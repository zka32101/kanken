import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shop.dart';
import '../providers/shop_provider.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(userWalletProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ショップ'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'コイン'),
            Tab(text: 'スキン'),
            Tab(text: 'キャラ'),
            Tab(text: 'エフェクト'),
            Tab(text: 'バッジ'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ウォレット表示
          wallet.when(
            data: (walletData) {
              if (walletData == null) return const SizedBox();
              return _buildWalletCard(walletData);
            },
            loading: () => const SizedBox(height: 80),
            error: (_, __) => const SizedBox(),
          ),
          // タブビュー
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCoinTab(),
                _buildCategoryTab('skin'),
                _buildCategoryTab('character'),
                _buildCategoryTab('effect'),
                _buildCategoryTab('badge'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(UserWallet wallet) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.purple.shade400, Colors.purple.shade700],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Icon(Icons.monetization_on, color: Colors.yellow, size: 28),
              const SizedBox(height: 4),
              Text(
                'コイン',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              Text(
                '${wallet.coins}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          Column(
            children: [
              const Icon(Icons.diamond, color: Colors.cyan, size: 28),
              const SizedBox(height: 4),
              Text(
                'ダイヤ',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              Text(
                '${wallet.diamonds}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoinTab() {
    final packages = ref.watch(coinPackagesProvider);

    return packages.when(
      data: (packageList) {
        if (packageList.isEmpty) {
          return const Center(child: Text('コインパッケージがありません'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: packageList.length,
          itemBuilder: (context, index) {
            final package = packageList[index];
            return _buildPackageTile(package);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('エラー')),
    );
  }

  Widget _buildPackageTile(CoinPackage package) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${package.coins} コイン',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    if (package.bonusCoins != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+${package.bonusCoins}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  '¥${package.realPrice}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    ref
                        .read(shopProvider.notifier)
                        .purchaseCoins(package);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${package.totalCoins}コイン獲得!',
                        ),
                      ),
                    );
                  },
                  child: const Text('購入'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTab(String category) {
    final items = ref.watch(shopItemsByCategoryProvider(category));

    return items.when(
      data: (itemList) {
        if (itemList.isEmpty) {
          return const Center(child: Text('アイテムがありません'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: itemList.length,
          itemBuilder: (context, index) {
            final item = itemList[index];
            return _buildItemCard(item);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('エラー')),
    );
  }

  Widget _buildItemCard(ShopItem item) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // アイテム画像
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: item.imageUrl != null
                    ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                    : Icon(Icons.image, color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(height: 8),
            // レア度
            Row(
              children: List.generate(
                item.rarity,
                (index) => const Icon(Icons.star, size: 12, color: Colors.amber),
              ),
            ),
            const SizedBox(height: 4),
            // 名前
            Text(
              item.name,
              style: Theme.of(context).textTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // 価格と購入ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.price}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    ref.read(shopProvider.notifier).purchaseItem(item);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item.name}を購入しました!')),
                    );
                  },
                  child: const Text('買', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
