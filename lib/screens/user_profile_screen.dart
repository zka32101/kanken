import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import '../providers/profile_provider.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider);
    final achievements = ref.watch(userAchievementsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('プロフィール'),
          centerTitle: true,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'プロフィール'),
              Tab(text: '実績'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            profile.when(
              data: (data) {
                if (data == null) {
                  return const Center(child: Text('プロフィールが見つかりません'));
                }
                return _buildProfileTab(context, ref, data);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('エラー')),
            ),
            achievements.when(
              data: (list) => _buildAchievementsTab(context, list),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('エラー')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // アバター
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade200,
            ),
            child: profile.avatarUrl != null
                ? Image.network(profile.avatarUrl!, fit: BoxFit.cover)
                : Icon(Icons.person, size: 50, color: Colors.blue.shade700),
          ),
          const SizedBox(height: 16),
          // 名前
          Text(
            profile.displayName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (profile.bio != null) ...[
            const SizedBox(height: 8),
            Text(profile.bio!),
          ],
          const SizedBox(height: 24),
          // 統計情報
          _buildStatCard(context, profile),
          const SizedBox(height: 24),
          // 編集ボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('編集'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _showEditDialog(context, ref, profile),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, UserProfile profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatTile('レベル', '${profile.level}', Colors.blue),
                _buildStatTile(
                    '経験値', '${profile.experience}', Colors.green),
                _buildStatTile(
                    '対戦', '${profile.totalBattles}', Colors.orange),
                _buildStatTile(
                    '勝率', '${(profile.winRate * 100).toStringAsFixed(1)}%',
                    Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              )),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab(
      BuildContext context, List<Achievement> achievements) {
    final unlocked = achievements.where((a) => a.isUnlocked).toList();
    final locked = achievements.where((a) => !a.isUnlocked).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'アンロック済み (${unlocked.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: unlocked.length,
            itemBuilder: (context, index) {
              return _buildAchievementCard(unlocked[index], true);
            },
          ),
          const SizedBox(height: 24),
          Text(
            'ロック (${locked.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: locked.length,
            itemBuilder: (context, index) {
              return _buildAchievementCard(locked[index], false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isUnlocked) {
    return Card(
      color: isUnlocked ? Colors.yellow.shade100 : Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isUnlocked ? Icons.star : Icons.lock,
            size: 32,
            color: isUnlocked ? Colors.amber : Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            achievement.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    String displayName = profile.displayName;
    String bio = profile.bio ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プロフィール編集'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'ユーザー名'),
              controller: TextEditingController(text: displayName),
              onChanged: (value) => displayName = value,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: '自己紹介'),
              controller: TextEditingController(text: bio),
              onChanged: (value) => bio = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(profileProvider.notifier).updateProfile(
                    displayName: displayName,
                    bio: bio,
                  );
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
