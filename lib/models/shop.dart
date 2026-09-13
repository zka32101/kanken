import 'package:cloud_firestore/cloud_firestore.dart';

/// ショップアイテム
class ShopItem {
  final String itemId;
  final String name;
  final String description;
  final String category; // 'skin', 'character', 'effect', 'badge'
  final int price;
  final String currency; // 'coin', 'diamond'
  final String? imageUrl;
  final bool isAvailable;
  final int rarity; // 1-5星
  final DateTime createdAt;

  const ShopItem({
    required this.itemId,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.currency,
    this.imageUrl,
    required this.isAvailable,
    required this.rarity,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'name': name,
    'description': description,
    'category': category,
    'price': price,
    'currency': currency,
    'imageUrl': imageUrl,
    'isAvailable': isAvailable,
    'rarity': rarity,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory ShopItem.fromJson(Map<String, dynamic> json) => ShopItem(
    itemId: json['itemId'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    category: json['category'] as String,
    price: json['price'] as int? ?? 0,
    currency: json['currency'] as String? ?? 'coin',
    imageUrl: json['imageUrl'] as String?,
    isAvailable: json['isAvailable'] as bool? ?? true,
    rarity: json['rarity'] as int? ?? 1,
    createdAt: json['createdAt'] is Timestamp
        ? (json['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
  );
}

/// ユーザーウォレット
class UserWallet {
  final String userId;
  final int coins;
  final int diamonds;
  final int totalSpent;
  final DateTime lastUpdated;

  const UserWallet({
    required this.userId,
    required this.coins,
    required this.diamonds,
    required this.totalSpent,
    required this.lastUpdated,
  });

  bool canAfford(int price, String currency) {
    switch (currency) {
      case 'coin':
        return coins >= price;
      case 'diamond':
        return diamonds >= price;
      default:
        return false;
    }
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'coins': coins,
    'diamonds': diamonds,
    'totalSpent': totalSpent,
    'lastUpdated': Timestamp.fromDate(lastUpdated),
  };

  factory UserWallet.fromJson(Map<String, dynamic> json) => UserWallet(
    userId: json['userId'] as String,
    coins: json['coins'] as int? ?? 0,
    diamonds: json['diamonds'] as int? ?? 0,
    totalSpent: json['totalSpent'] as int? ?? 0,
    lastUpdated: json['lastUpdated'] is Timestamp
        ? (json['lastUpdated'] as Timestamp).toDate()
        : DateTime.now(),
  );
}

/// 購入履歴
class Purchase {
  final String purchaseId;
  final String userId;
  final String itemId;
  final String itemName;
  final int price;
  final String currency;
  final DateTime purchasedAt;
  final bool isRefunded;

  const Purchase({
    required this.purchaseId,
    required this.userId,
    required this.itemId,
    required this.itemName,
    required this.price,
    required this.currency,
    required this.purchasedAt,
    required this.isRefunded,
  });

  Map<String, dynamic> toJson() => {
    'purchaseId': purchaseId,
    'userId': userId,
    'itemId': itemId,
    'itemName': itemName,
    'price': price,
    'currency': currency,
    'purchasedAt': Timestamp.fromDate(purchasedAt),
    'isRefunded': isRefunded,
  };

  factory Purchase.fromJson(Map<String, dynamic> json) => Purchase(
    purchaseId: json['purchaseId'] as String,
    userId: json['userId'] as String,
    itemId: json['itemId'] as String,
    itemName: json['itemName'] as String,
    price: json['price'] as int? ?? 0,
    currency: json['currency'] as String? ?? 'coin',
    purchasedAt: json['purchasedAt'] is Timestamp
        ? (json['purchasedAt'] as Timestamp).toDate()
        : DateTime.now(),
    isRefunded: json['isRefunded'] as bool? ?? false,
  );
}

/// コイン購入パッケージ
class CoinPackage {
  final String packageId;
  final String name;
  final int coins;
  final int realPrice; // 円単位
  final int? bonusCoins; // ボーナスコイン
  final bool isPopular;

  const CoinPackage({
    required this.packageId,
    required this.name,
    required this.coins,
    required this.realPrice,
    this.bonusCoins,
    required this.isPopular,
  });

  int get totalCoins => coins + (bonusCoins ?? 0);

  Map<String, dynamic> toJson() => {
    'packageId': packageId,
    'name': name,
    'coins': coins,
    'realPrice': realPrice,
    'bonusCoins': bonusCoins,
    'isPopular': isPopular,
  };

  factory CoinPackage.fromJson(Map<String, dynamic> json) => CoinPackage(
    packageId: json['packageId'] as String,
    name: json['name'] as String,
    coins: json['coins'] as int? ?? 0,
    realPrice: json['realPrice'] as int? ?? 0,
    bonusCoins: json['bonusCoins'] as int?,
    isPopular: json['isPopular'] as bool? ?? false,
  );
}

/// ユーザーの所持アイテム
class UserInventoryItem {
  final String inventoryId;
  final String userId;
  final String itemId;
  final String itemName;
  final String category;
  final int quantity;
  final bool isEquipped;
  final DateTime obtainedAt;

  const UserInventoryItem({
    required this.inventoryId,
    required this.userId,
    required this.itemId,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.isEquipped,
    required this.obtainedAt,
  });

  Map<String, dynamic> toJson() => {
    'inventoryId': inventoryId,
    'userId': userId,
    'itemId': itemId,
    'itemName': itemName,
    'category': category,
    'quantity': quantity,
    'isEquipped': isEquipped,
    'obtainedAt': Timestamp.fromDate(obtainedAt),
  };

  factory UserInventoryItem.fromJson(Map<String, dynamic> json) =>
      UserInventoryItem(
        inventoryId: json['inventoryId'] as String,
        userId: json['userId'] as String,
        itemId: json['itemId'] as String,
        itemName: json['itemName'] as String,
        category: json['category'] as String,
        quantity: json['quantity'] as int? ?? 0,
        isEquipped: json['isEquipped'] as bool? ?? false,
        obtainedAt: json['obtainedAt'] is Timestamp
            ? (json['obtainedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
}
