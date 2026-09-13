import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shop.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final currentUserIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.currentUser?.uid;
});

/// ショップのすべてのアイテムを取得
final shopItemsProvider = FutureProvider<List<ShopItem>>((ref) async {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final querySnapshot = await firestore
      .collection('shop')
      .collection('items')
      .where('isAvailable', isEqualTo: true)
      .orderBy('rarity', descending: true)
      .get();

  return querySnapshot.docs
      .map((doc) => ShopItem.fromJson(doc.data()))
      .toList();
});

/// カテゴリ別のアイテムを取得
final shopItemsByCategoryProvider =
    FutureProvider.family<List<ShopItem>, String>((ref, category) async {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final querySnapshot = await firestore
      .collection('shop')
      .collection('items')
      .where('category', isEqualTo: category)
      .where('isAvailable', isEqualTo: true)
      .orderBy('price', descending: false)
      .get();

  return querySnapshot.docs
      .map((doc) => ShopItem.fromJson(doc.data()))
      .toList();
});

/// ユーザーのウォレット情報を取得
final userWalletProvider = FutureProvider<UserWallet?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final firestore = ref.watch(firebaseFirestoreProvider);
  final doc = await firestore
      .collection('users')
      .doc(userId)
      .collection('wallet')
      .doc('balance')
      .get();

  if (!doc.exists) {
    return UserWallet(
      userId: userId,
      coins: 0,
      diamonds: 0,
      totalSpent: 0,
      lastUpdated: DateTime.now(),
    );
  }

  return UserWallet.fromJson(doc.data() ?? {});
});

/// ユーザーの購入履歴を取得
final userPurchaseHistoryProvider =
    FutureProvider<List<Purchase>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final firestore = ref.watch(firebaseFirestoreProvider);
  final querySnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('purchases')
      .orderBy('purchasedAt', descending: true)
      .limit(50)
      .get();

  return querySnapshot.docs
      .map((doc) => Purchase.fromJson(doc.data()))
      .toList();
});

/// コイン購入パッケージを取得
final coinPackagesProvider =
    FutureProvider<List<CoinPackage>>((ref) async {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final querySnapshot = await firestore
      .collection('shop')
      .collection('coinPackages')
      .orderBy('coins', descending: false)
      .get();

  return querySnapshot.docs
      .map((doc) => CoinPackage.fromJson(doc.data()))
      .toList();
});

/// ユーザーのインベントリを取得
final userInventoryProvider =
    FutureProvider<List<UserInventoryItem>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final firestore = ref.watch(firebaseFirestoreProvider);
  final querySnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('inventory')
      .orderBy('obtainedAt', descending: true)
      .get();

  return querySnapshot.docs
      .map((doc) => UserInventoryItem.fromJson(doc.data()))
      .toList();
});

/// ショップ Notifier
class ShopNotifier extends StateNotifier<void> {
  final FirebaseFirestore _firestore;
  final String? _userId;

  ShopNotifier(this._firestore, this._userId) : super(null);

  /// アイテムを購入
  Future<bool> purchaseItem(ShopItem item) async {
    if (_userId == null) return false;

    try {
      // ウォレット情報を取得
      final walletDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('wallet')
          .doc('balance')
          .get();

      if (!walletDoc.exists) {
        return false;
      }

      final wallet = UserWallet.fromJson(walletDoc.data() ?? {});

      // 購入可能かチェック
      if (!wallet.canAfford(item.price, item.currency)) {
        return false;
      }

      // トランザクションで購入処理を実行
      await _firestore.runTransaction((transaction) async {
        // ウォレットを更新
        int newCoins = wallet.coins;
        int newDiamonds = wallet.diamonds;

        if (item.currency == 'coin') {
          newCoins -= item.price;
        } else if (item.currency == 'diamond') {
          newDiamonds -= item.price;
        }

        transaction.update(
          _firestore
              .collection('users')
              .doc(_userId)
              .collection('wallet')
              .doc('balance'),
          {
            'coins': newCoins,
            'diamonds': newDiamonds,
            'totalSpent': FieldValue.increment(item.price),
            'lastUpdated': Timestamp.now(),
          },
        );

        // 購入履歴を記録
        final purchaseId = _firestore.collection('users').doc().id;
        final purchase = Purchase(
          purchaseId: purchaseId,
          userId: _userId!,
          itemId: item.itemId,
          itemName: item.name,
          price: item.price,
          currency: item.currency,
          purchasedAt: DateTime.now(),
          isRefunded: false,
        );

        transaction.set(
          _firestore
              .collection('users')
              .doc(_userId)
              .collection('purchases')
              .doc(purchaseId),
          purchase.toJson(),
        );

        // インベントリに追加
        final inventoryId = _firestore.collection('users').doc().id;
        final inventoryItem = UserInventoryItem(
          inventoryId: inventoryId,
          userId: _userId!,
          itemId: item.itemId,
          itemName: item.name,
          category: item.category,
          quantity: 1,
          isEquipped: false,
          obtainedAt: DateTime.now(),
        );

        transaction.set(
          _firestore
              .collection('users')
              .doc(_userId)
              .collection('inventory')
              .doc(inventoryId),
          inventoryItem.toJson(),
        );
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// コインを購入
  Future<bool> purchaseCoins(CoinPackage package) async {
    if (_userId == null) return false;

    try {
      // トランザクション使用（race condition防止）
      await _firestore.runTransaction((transaction) async {
        final walletRef = _firestore
            .collection('users')
            .doc(_userId)
            .collection('wallet')
            .doc('balance');

        final walletDoc = await transaction.get(walletRef);

        UserWallet wallet;
        if (walletDoc.exists) {
          wallet = UserWallet.fromJson(walletDoc.data() ?? {});
        } else {
          wallet = UserWallet(
            userId: _userId!,
            coins: 0,
            diamonds: 0,
            totalSpent: 0,
            lastUpdated: DateTime.now(),
          );
        }

        // トランザクション内でウォレットを更新
        transaction.set(walletRef, {
          'userId': _userId,
          'coins': wallet.coins + package.totalCoins,
          'diamonds': wallet.diamonds,
          'totalSpent': wallet.totalSpent + package.realPrice,
          'lastUpdated': Timestamp.now(),
        });
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// アイテムを装備
  Future<bool> equipItem(String inventoryId) async {
    if (_userId == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('inventory')
          .doc(inventoryId)
          .update({'isEquipped': true});

      return true;
    } catch (e) {
      return false;
    }
  }

  /// アイテムを外す
  Future<bool> unequipItem(String inventoryId) async {
    if (_userId == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('inventory')
          .doc(inventoryId)
          .update({'isEquipped': false});

      return true;
    } catch (e) {
      return false;
    }
  }
}

/// ショップ StateNotifierProvider
final shopProvider = StateNotifierProvider<ShopNotifier, void>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final userId = ref.watch(currentUserIdProvider);
  return ShopNotifier(firestore, userId);
});
