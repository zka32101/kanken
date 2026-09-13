import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/shop.dart';

void main() {
  group('ShopItem Tests', () {
    test('ShopItem can be created', () {
      final item = ShopItem(
        itemId: 'item1',
        name: 'ゴールドスキン',
        description: 'キャラクターの金色スキン',
        category: 'skin',
        price: 500,
        currency: 'coin',
        isAvailable: true,
        rarity: 4,
        createdAt: DateTime.now(),
      );

      expect(item.itemId, equals('item1'));
      expect(item.name, equals('ゴールドスキン'));
      expect(item.rarity, equals(4));
    });

    test('JSON round-trip serialization', () {
      final original = ShopItem(
        itemId: 'item1',
        name: 'ゴールドスキン',
        description: 'キャラクターの金色スキン',
        category: 'skin',
        price: 500,
        currency: 'coin',
        isAvailable: true,
        rarity: 4,
        createdAt: DateTime(2026, 9, 13),
      );

      final json = original.toJson();
      final fromJson = ShopItem.fromJson(json as Map<String, dynamic>);

      expect(fromJson.itemId, equals(original.itemId));
      expect(fromJson.price, equals(original.price));
      expect(fromJson.rarity, equals(original.rarity));
    });
  });

  group('UserWallet Tests', () {
    test('UserWallet can be created', () {
      final wallet = UserWallet(
        userId: 'user1',
        coins: 1000,
        diamonds: 50,
        totalSpent: 5000,
        lastUpdated: DateTime.now(),
      );

      expect(wallet.userId, equals('user1'));
      expect(wallet.coins, equals(1000));
      expect(wallet.diamonds, equals(50));
    });

    test('canAfford checks correctly', () {
      final wallet = UserWallet(
        userId: 'user1',
        coins: 1000,
        diamonds: 50,
        totalSpent: 0,
        lastUpdated: DateTime.now(),
      );

      expect(wallet.canAfford(500, 'coin'), isTrue);
      expect(wallet.canAfford(2000, 'coin'), isFalse);
      expect(wallet.canAfford(30, 'diamond'), isTrue);
      expect(wallet.canAfford(100, 'diamond'), isFalse);
    });

    test('JSON round-trip serialization', () {
      final original = UserWallet(
        userId: 'user1',
        coins: 1000,
        diamonds: 50,
        totalSpent: 5000,
        lastUpdated: DateTime(2026, 9, 13),
      );

      final json = original.toJson();
      final fromJson = UserWallet.fromJson(json as Map<String, dynamic>);

      expect(fromJson.userId, equals(original.userId));
      expect(fromJson.coins, equals(original.coins));
      expect(fromJson.totalSpent, equals(original.totalSpent));
    });
  });

  group('CoinPackage Tests', () {
    test('CoinPackage can be created', () {
      final package = CoinPackage(
        packageId: 'pkg1',
        name: 'スターターパック',
        coins: 500,
        realPrice: 490,
        bonusCoins: 100,
        isPopular: true,
      );

      expect(package.packageId, equals('pkg1'));
      expect(package.coins, equals(500));
      expect(package.totalCoins, equals(600));
    });

    test('totalCoins calculates correctly', () {
      final packageWithBonus = CoinPackage(
        packageId: 'pkg1',
        name: 'パッケージ',
        coins: 500,
        realPrice: 490,
        bonusCoins: 100,
        isPopular: false,
      );

      final packageNoBonus = CoinPackage(
        packageId: 'pkg2',
        name: 'パッケージ',
        coins: 500,
        realPrice: 490,
        bonusCoins: null,
        isPopular: false,
      );

      expect(packageWithBonus.totalCoins, equals(600));
      expect(packageNoBonus.totalCoins, equals(500));
    });

    test('JSON round-trip serialization', () {
      final original = CoinPackage(
        packageId: 'pkg1',
        name: 'スターターパック',
        coins: 500,
        realPrice: 490,
        bonusCoins: 100,
        isPopular: true,
      );

      final json = original.toJson();
      final fromJson = CoinPackage.fromJson(json as Map<String, dynamic>);

      expect(fromJson.packageId, equals(original.packageId));
      expect(fromJson.coins, equals(original.coins));
      expect(fromJson.bonusCoins, equals(original.bonusCoins));
    });
  });

  group('Purchase Tests', () {
    test('Purchase can be created', () {
      final purchase = Purchase(
        purchaseId: 'pur1',
        userId: 'user1',
        itemId: 'item1',
        itemName: 'ゴールドスキン',
        price: 500,
        currency: 'coin',
        purchasedAt: DateTime.now(),
        isRefunded: false,
      );

      expect(purchase.purchaseId, equals('pur1'));
      expect(purchase.itemName, equals('ゴールドスキン'));
      expect(purchase.isRefunded, isFalse);
    });

    test('JSON round-trip serialization', () {
      final original = Purchase(
        purchaseId: 'pur1',
        userId: 'user1',
        itemId: 'item1',
        itemName: 'ゴールドスキン',
        price: 500,
        currency: 'coin',
        purchasedAt: DateTime(2026, 9, 13),
        isRefunded: false,
      );

      final json = original.toJson();
      final fromJson = Purchase.fromJson(json as Map<String, dynamic>);

      expect(fromJson.purchaseId, equals(original.purchaseId));
      expect(fromJson.price, equals(original.price));
      expect(fromJson.currency, equals(original.currency));
    });
  });

  group('UserInventoryItem Tests', () {
    test('UserInventoryItem can be created', () {
      final item = UserInventoryItem(
        inventoryId: 'inv1',
        userId: 'user1',
        itemId: 'item1',
        itemName: 'ゴールドスキン',
        category: 'skin',
        quantity: 1,
        isEquipped: true,
        obtainedAt: DateTime.now(),
      );

      expect(item.inventoryId, equals('inv1'));
      expect(item.itemName, equals('ゴールドスキン'));
      expect(item.isEquipped, isTrue);
    });

    test('JSON round-trip serialization', () {
      final original = UserInventoryItem(
        inventoryId: 'inv1',
        userId: 'user1',
        itemId: 'item1',
        itemName: 'ゴールドスキン',
        category: 'skin',
        quantity: 1,
        isEquipped: true,
        obtainedAt: DateTime(2026, 9, 13),
      );

      final json = original.toJson();
      final fromJson =
          UserInventoryItem.fromJson(json as Map<String, dynamic>);

      expect(fromJson.inventoryId, equals(original.inventoryId));
      expect(fromJson.category, equals(original.category));
      expect(fromJson.isEquipped, equals(original.isEquipped));
    });
  });
}
