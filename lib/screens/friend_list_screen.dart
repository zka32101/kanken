import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanken/models/friend.dart';
import 'package:kanken/providers/friend_provider.dart';

class FriendListScreen extends ConsumerStatefulWidget {
  const FriendListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends ConsumerState<FriendListScreen>
    with SingleTickerProviderStateMixin {
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
        title: const Text('フレンド'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'フレンド'),
            Tab(icon: Icon(Icons.inbox), text: 'リクエスト'),
            Tab(icon: Icon(Icons.send), text: '送信済み'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendList(),
          _buildIncomingRequests(),
          _buildOutgoingRequests(),
        ],
      ),
    );
  }

  Widget _buildFriendList() {
    final friendsAsyncValue = ref.watch(friendListProvider);

    return friendsAsyncValue.when(
      data: (friends) => friends.isEmpty
          ? _buildEmptyState('フレンドを追加しましょう')
          : ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) =>
                  _buildFriendCard(friends[index]),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('エラー: $error')),
    );
  }

  Widget _buildIncomingRequests() {
    final requestsAsyncValue = ref.watch(incomingRequestsProvider);

    return requestsAsyncValue.when(
      data: (requests) => requests.isEmpty
          ? _buildEmptyState('新しいリクエストはありません')
          : ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) =>
                  _buildRequestCard(requests[index], isIncoming: true),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('エラー: $error')),
    );
  }

  Widget _buildOutgoingRequests() {
    final friendsAsyncValue = ref.watch(outgoingRequestsProvider);

    return friendsAsyncValue.when(
      data: (friends) => friends.isEmpty
          ? _buildEmptyState('リクエスト待ちのユーザーはいません')
          : ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) =>
                  _buildSentRequestCard(friends[index]),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('エラー: $error')),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(Friend friend) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: friend.isOnline ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: friend.isOnline
            ? Border.all(color: Colors.green.shade300, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // ステータスインジケーター
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: friend.isOnline ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),

          // ユーザー情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      friend.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Lv ${friend.level}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatBadge('EXP', friend.experience.toString()),
                    const SizedBox(width: 12),
                    _buildStatBadge('正答率', '${(friend.accuracyRate * 100).toStringAsFixed(0)}%'),
                    const SizedBox(width: 12),
                    _buildStatBadge('🔥', friend.streak.toString()),
                  ],
                ),
              ],
            ),
          ),

          // アクション
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('削除'),
                onTap: () => _showConfirmDialog(
                  'フレンド削除',
                  '${friend.userName} を削除しますか？',
                  () => ref.read(friendNotifierProvider.notifier)
                      .removeFriend(friend.userId),
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(FriendRequest request, {required bool isIncoming}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_add, color: Colors.blue),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${request.fromUserName} からのリクエスト',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'リクエスト日: ${_formatDate(request.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // アクションボタン
          Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onPressed: () async {
                  // フレンド情報を取得して承認
                  final friendData = Friend(
                    userId: request.fromUserId,
                    userName: request.fromUserName,
                    level: 1,
                    experience: 0,
                    accuracyRate: 0.0,
                    streak: 0,
                    status: FriendStatus.friend,
                    addedAt: DateTime.now(),
                  );

                  await ref.read(friendNotifierProvider.notifier)
                      .acceptFriendRequest(request, friendData);
                },
                child: const Text(
                  '承認',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onPressed: () => ref.read(friendNotifierProvider.notifier)
                    .rejectFriendRequest(request),
                child: const Text('拒否', fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSentRequestCard(Friend friend) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: Colors.orange),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'リクエスト待機中...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // キャンセルボタン
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            onPressed: () => ref.read(friendNotifierProvider.notifier)
                .removeFriend(friend.userId),
            child: const Text('キャンセル', fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}';
  }

  void _showConfirmDialog(
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              '削除',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
