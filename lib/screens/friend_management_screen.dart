import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/social.dart';
import '../providers/social_provider.dart';

class FriendManagementScreen extends ConsumerStatefulWidget {
  const FriendManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FriendManagementScreen> createState() =>
      _FriendManagementScreenState();
}

class _FriendManagementScreenState extends ConsumerState<FriendManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フレンド管理'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'フレンド'),
            Tab(text: '要求'),
            Tab(text: '送信'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsTab(),
          _buildRequestsTab(),
          _buildSentTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('フレンド追加'),
        backgroundColor: Colors.blue,
        onPressed: () => _showSearchFriendDialog(context),
      ),
    );
  }

  Widget _buildFriendsTab() {
    final friends = ref.watch(userFriendsProvider);

    return friends.when(
      data: (friendList) {
        if (friendList.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_outline,
            title: 'フレンドがいません',
            message: 'フレンドを追加しましょう',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: friendList.length,
          itemBuilder: (context, index) {
            final friend = friendList[index];
            return _buildFriendTile(context, friend);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text('エラーが発生しました'),
      ),
    );
  }

  Widget _buildFriendTile(BuildContext context, Friend friend) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // アバター
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade200,
              ),
              child: friend.avatarUrl != null
                  ? Image.network(friend.avatarUrl!)
                  : Icon(Icons.person, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 12),
            // ユーザー情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.displayName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lv.${friend.level}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            // 削除ボタン
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('削除'),
                  onTap: () async {
                    final success = await ref.read(socialProvider.notifier).removeFriend(friend.friendId);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? 'フレンドを削除しました' : 'エラーが発生しました')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTab() {
    final requests = ref.watch(pendingFriendRequestsProvider);

    return requests.when(
      data: (requestList) {
        if (requestList.isEmpty) {
          return _buildEmptyState(
            icon: Icons.mail_outline,
            title: 'フレンド要求はありません',
            message: '新しい要求を待機中...',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: requestList.length,
          itemBuilder: (context, index) {
            final request = requestList[index];
            return _buildRequestTile(context, request);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text('エラーが発生しました'),
      ),
    );
  }

  Widget _buildRequestTile(BuildContext context, FriendRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // アバター
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.shade200,
              ),
              child: request.fromAvatarUrl != null
                  ? Image.network(request.fromAvatarUrl!)
                  : Icon(Icons.person, color: Colors.green.shade700),
            ),
            const SizedBox(width: 12),
            // ユーザー情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.fromDisplayName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '要求を送信しました',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            // ボタン
            Column(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('承認'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final success = await ref.read(socialProvider.notifier).acceptFriendRequest(request);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? 'フレンドを承認しました' : 'エラーが発生しました')),
                    );
                  },
                ),
                const SizedBox(height: 4),
                ElevatedButton.icon(
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('拒否'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final success = await ref.read(socialProvider.notifier).rejectFriendRequest(request);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? '要求を拒否しました' : 'エラーが発生しました')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentTab() {
    final requests = ref.watch(sentFriendRequestsProvider);

    return requests.when(
      data: (requestList) {
        if (requestList.isEmpty) {
          return _buildEmptyState(
            icon: Icons.send_outlined,
            title: '送信した要求はありません',
            message: 'フレンドリクエストを送信しましょう',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: requestList.length,
          itemBuilder: (context, index) {
            final request = requestList[index];
            return _buildSentRequestTile(context, request);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text('エラーが発生しました'),
      ),
    );
  }

  Widget _buildSentRequestTile(BuildContext context, FriendRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // ステータス表示
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.shade200,
              ),
              child: Icon(
                Icons.hourglass_empty,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(width: 12),
            // ユーザー情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ユーザーID: ${request.toUserId.length > 8 ? request.toUserId.substring(0, 8) : request.toUserId}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '待機中...',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.orange,
                        ),
                  ),
                ],
              ),
            ),
            // キャンセルボタン
            ElevatedButton.icon(
              icon: const Icon(Icons.close, size: 16),
              label: const Text('キャンセル'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final success = await ref.read(socialProvider.notifier).cancelFriendRequest(request.toUserId);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? '要求をキャンセルしました' : 'エラーが発生しました')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _showSearchFriendDialog(BuildContext context) async {
    String searchUserId = '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フレンド追加'),
        content: TextField(
          decoration: InputDecoration(
            labelText: 'ユーザーIDで検索',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (value) => searchUserId = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (searchUserId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ユーザーIDを入力してください')),
                );
                return;
              }

              ref
                  .read(socialProvider.notifier)
                  .sendFriendRequest(searchUserId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('フレンド要求を送信しました')),
              );
            },
            child: const Text('送信'),
          ),
        ],
      ),
    );
  }
}
