import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shop.dart';
import '../viewmodels/user_viewmodel.dart' as user_vm;

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

/// 現在のプロフィールIDを取得
final _currentProfileIdProvider = Provider<String>((ref) {
  return ref.watch(
    user_vm.currentUserProvider.select((async) => async.value?.profileId ?? 'default'),
  );
});

/// users/{uid}/profiles/{profileId} 配下のドキュメント参照
DocumentReference<Map<String, dynamic>> _profileDoc(String uid, String profileId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('profiles')
      .doc(profileId);
}

/// ショップのすべてのアイテムを取得
final shopItemsProvider = FutureProvider<List<ShopItem>>((ref) async {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final querySnapshot = await firestore
      .collection('shop')
      .doc('default')
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
      .doc('default')
      .collection('items')
      .where('category', isEqualTo: category)
      .where('isAvailable', isEqualTo: true)
      .orderBy('price', descending: false)
      .get();

  return querySnapshot.docs
      .map((doc) => ShopItem.fromJson(doc.data()))
      .toList();
});

/// ユーザーのウォレット情報を取得（プロフィール単位）
final userWalletProvider = FutureProvider<UserWallet?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final profileId = ref.watch(_currentProfileIdProvider);
  final doc = await _profileDoc(userId, profileId)
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

/// ユーザーの購入履歴を取得（プロフィール単位）
final userPurchaseHistoryProvider =
    FutureProvider<List<Purchase>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final profileId = ref.watch(_currentProfileIdProvider);
  final querySnapshot = await _profileDoc(userId, profileId)
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
      .doc('default')
      .collection('coinPackages')
      .orderBy('coins', descending: false)
      .get();

  return querySnapshot.docs
      .map((doc) => CoinPackage.fromJson(doc.data()))
      .toList();
});

/// ユーザーのインベントリを取得（プロフィール単位）
final userInventoryProvider =
    FutureProvider<List<UserInventoryItem>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final profileId = ref.watch(_currentProfileIdProvider);
  final querySnapshot = await _profileDoc(userId, profileId)
      .collection('inventory')
      .orderBy('obtainedAt', descending: true)
      .get();

  return querySnapshot.docs
      .map((doc) => UserInventoryItem.fromJson(doc.data()))
      .toList();
});

/// ショップ Notifier（プロフィール単位）
class ShopNotifier extends StateNotifier<void> {
  final FirebaseFirestore _firestore;
  final String? _userId;
  final String _profileId;

  ShopNotifier(this._firestore, this._userId, this._profileId) : super(null);

  /// アイテムを購入
  Future<bool> purchaseItem(ShopItem item) async {
    if (_userId == null) return false;

    try {
      final profileRef = _profileDoc(_userId!, _profileId);

      // トランザクションで購入処理を実行（race condition防止）
      final result = await _firestore.runTransaction<bool>((transaction) async {
        final walletRef = profileRef.collection('wallet').doc('balance');

        // トランザクション内でウォレット情報を取得
        final walletDoc = await transaction.get(walletRef);

        if (!walletDoc.exists) {
          return false;
        }

        final wallet = UserWallet.fromJson(walletDoc.data() ?? {});

        // トランザクション内で購入可能かチェック
        if (!wallet.canAfford(item.price, item.currency)) {
          return false;
        }

        // ウォレットを更新
        int newCoins = wallet.coins;
        int newDiamonds = wallet.diamonds;

        if (item.currency == 'coin') {
          newCoins -= item.price;
        } else if (item.currency == 'diamond') {
          newDiamonds -= item.price;
        }

        transaction.update(
          walletRef,
          {
            'coins': newCoins,
            'diamonds': newDiamonds,
            'totalSpent': FieldValue.increment(item.price),
            'lastUpdated': Timestamp.now(),
          },
        );

        // 購入履歴を記録
        final purchasesRef = profileRef.collection('purchases');
        final purchaseId = purchasesRef.doc().id;
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

        transaction.set(purchasesRef.doc(purchaseId), purchase.toJson());

        // インベントリに追加
        final inventoryRef = profileRef.collection('inventory');
        final inventoryId = inventoryRef.doc().id;
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

        transaction.set(inventoryRef.doc(inventoryId), inventoryItem.toJson());

        return true;
      });

      return result;
    } catch (e) {
      return false;
    }
  }

  /// コインを購入
  Future<bool> purchaseCoins(CoinPackage package) async {
    if (_userId == null) return false;

    try {
      final walletRef = _profileDoc(_userId!, _profileId).collection('wallet').doc('balance');

      // トランザクション使用（race condition防止）
      await _firestore.runTransaction((transaction) async {
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
      await _profileDoc(_userId!, _profileId)
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
      await _profileDoc(_userId!, _profileId)
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
  final profileId = ref.watch(_currentProfileIdProvider);
  return ShopNotifier(firestore, userId, profileId);
});
