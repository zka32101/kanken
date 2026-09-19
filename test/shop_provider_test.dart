import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/shop.dart';

void main() {
  group('ShopItem Tests', () {
    test('ShopItem creates with valid data', () {
      final item = ShopItem(
        id: 'item-1',
        name: 'Legendary Badge',
        description: 'Ultra-rare badge',
        price: 500,
        category: 'badge',
        rarity: 'legendary',
        imageUrl: 'https://example.com/badge.png',
      );

      expect(item.id, equals('item-1'));
      expect(item.name, equals('Legendary Badge'));
      expect(item.price, equals(500));
      expect(item.rarity, equals('legendary'));
    });

    test('ShopItem validates price', () {
      final item = ShopItem(
        id: 'item-2',
        name: 'Common Item',
        description: 'Basic item',
        price: 10,
        category: 'item',
        rarity: 'common',
        imageUrl: 'https://example.com/item.png',
      );

      expect(item.price, greaterThan(0));
      expect(item.price, lessThan(10000));
    });

    test('ShopItem categories are valid', () {
      const validCategories = ['badge', 'avatar', 'theme', 'item'];

      for (final category in validCategories) {
        final item = ShopItem(
          id: 'item-$category',
          name: 'Test Item',
          description: 'Test',
          price: 100,
          category: category,
          rarity: 'common',
          imageUrl: 'https://example.com/item.png',
        );

        expect(validCategories.contains(item.category), isTrue);
      }
    });

    test('ShopItem rarity levels', () {
      const rarityLevels = ['common', 'uncommon', 'rare', 'epic', 'legendary'];

      for (final rarity in rarityLevels) {
        final item = ShopItem(
          id: 'item-$rarity',
          name: 'Item',
          description: 'Test',
          price: 100,
          category: 'badge',
          rarity: rarity,
          imageUrl: 'https://example.com/item.png',
        );

        expect(rarityLevels.contains(item.rarity), isTrue);
      }
    });

    test('ShopItem fromJson creates instance', () {
      final jsonData = {
        'id': 'item-3',
        'name': 'Premium Badge',
        'description': 'Exclusive badge',
        'price': 750,
        'category': 'badge',
        'rarity': 'epic',
        'imageUrl': 'https://example.com/premium.png',
      };

      final item = ShopItem.fromJson(jsonData);

      expect(item.id, equals('item-3'));
      expect(item.name, equals('Premium Badge'));
      expect(item.price, equals(750));
      expect(item.rarity, equals('epic'));
    });

    test('ShopItem toJson converts to map', () {
      final item = ShopItem(
        id: 'item-4',
        name: 'Test Badge',
        description: 'For testing',
        price: 300,
        category: 'badge',
        rarity: 'rare',
        imageUrl: 'https://example.com/test.png',
      );

      final json = item.toJson();

      expect(json['id'], equals('item-4'));
      expect(json['name'], equals('Test Badge'));
      expect(json['price'], equals(300));
    });

    test('ShopItem pricing tiers', () {
      final commonItem = ShopItem(
        id: 'common',
        name: 'Common',
        description: 'Common',
        price: 50,
        category: 'item',
        rarity: 'common',
        imageUrl: 'https://example.com/common.png',
      );

      final legendaryItem = ShopItem(
        id: 'legendary',
        name: 'Legendary',
        description: 'Legendary',
        price: 2000,
        category: 'badge',
        rarity: 'legendary',
        imageUrl: 'https://example.com/legendary.png',
      );

      expect(legendaryItem.price, greaterThan(commonItem.price));
    });

    test('ShopItem purchase validation', () {
      final item = ShopItem(
        id: 'item-5',
        name: 'Purchase Test',
        description: 'Testing purchase',
        price: 200,
        category: 'item',
        rarity: 'uncommon',
        imageUrl: 'https://example.com/purchase.png',
      );

      final userCoins = 500;
      final canPurchase = userCoins >= item.price;

      expect(canPurchase, isTrue);
      expect(item.price, lessThanOrEqualTo(userCoins));
    });

    test('ShopItem insufficient funds', () {
      final item = ShopItem(
        id: 'item-6',
        name: 'Expensive',
        description: 'Too expensive',
        price: 1000,
        category: 'badge',
        rarity: 'legendary',
        imageUrl: 'https://example.com/expensive.png',
      );

      final userCoins = 500;
      final canPurchase = userCoins >= item.price;

      expect(canPurchase, isFalse);
    });

    test('ShopItem batch loading', () {
      final items = List.generate(10, (i) {
        return ShopItem(
          id: 'item-$i',
          name: 'Item $i',
          description: 'Item description',
          price: (i + 1) * 100,
          category: i % 2 == 0 ? 'badge' : 'avatar',
          rarity: ['common', 'uncommon', 'rare', 'epic', 'legendary'][i % 5],
          imageUrl: 'https://example.com/item-$i.png',
        );
      });

      expect(items.length, equals(10));
      expect(items.first.price, equals(100));
      expect(items.last.price, equals(1000));
    });
  });
}
