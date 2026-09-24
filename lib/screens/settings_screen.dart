import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import '../viewmodels/user_viewmodel.dart';
import '../viewmodels/services_provider.dart';

/// プロフィールのアイコンに使える絵文字候補
const _avatarIconChoices = ['🙂', '😀', '😊', '🐱', '🐶', '🐻', '🦁', '🐼', '🐸', '🦊', '⭐', '🌸'];

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        centerTitle: true,
        elevation: 0,
      ),
      body: currentUserAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('ログインしてください'));
          }
          return ListView(
            children: [
              const _SectionHeader('プロフィール'),
              const _ProfileManagementSection(),
              const Divider(),
              const _SectionHeader('学習'),
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('出題除外の条件'),
                subtitle: Text('${user.masteryThreshold}回連続正解したら出題しない'),
                trailing: DropdownButton<int>(
                  value: user.masteryThreshold,
                  items: const [1, 2, 3, 5, 10]
                      .map((n) => DropdownMenuItem(value: n, child: Text('$n回')))
                      .toList(),
                  onChanged: (value) async {
                    if (value == null) return;
                    final firestoreService = ref.read(firestoreServiceProvider);
                    await firestoreService.updateUser(
                      user.copyWith(masteryThreshold: value),
                    );
                    ref.invalidate(currentUserProvider);
                  },
                ),
              ),
              const Divider(),
              const _SectionHeader('公開設定'),
              SwitchListTile(
                secondary: const Icon(Icons.leaderboard),
                title: const Text('ランキングに参加する'),
                subtitle: const Text('ニックネームと成績が全員に公開されます'),
                value: user.rankingOptIn,
                onChanged: (value) async {
                  final firestoreService = ref.read(firestoreServiceProvider);
                  await firestoreService.updateUser(
                    user.copyWith(rankingOptIn: value),
                  );
                  ref.invalidate(currentUserProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value ? 'ランキングに参加しました' : 'ランキング参加をやめました',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('エラー: $err')),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

/// 1つのFirebase Authアカウント配下の複数プロフィール（兄弟等）を
/// 一覧・切り替え・追加・削除するためのセクション。
/// 学習履歴・目標・ランキングはプロフィールごとに完全に分離される。
class _ProfileManagementSection extends ConsumerWidget {
  const _ProfileManagementSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) return const SizedBox.shrink();

    final profilesAsync = ref.watch(userProfilesProvider(uid));
    final activeProfileId = ref.watch(activeProfileIdProvider) ?? 'default';

    return profilesAsync.when(
      data: (profiles) {
        return Column(
          children: [
            ...profiles.map(
              (profile) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: profile.profileId == activeProfileId
                      ? Colors.blue.shade100
                      : Colors.grey.shade200,
                  child: Text(profile.avatarIcon, style: const TextStyle(fontSize: 20)),
                ),
                title: Text(profile.displayName.isEmpty ? '(名前未設定)' : profile.displayName),
                subtitle: Text(profile.currentLevel),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.badge_outlined, size: 20),
                      tooltip: 'フレンドIDを表示',
                      onPressed: () => _showFriendIdDialog(context, uid, profile),
                    ),
                    if (profile.profileId == activeProfileId)
                      const Icon(Icons.check_circle, color: Colors.blue)
                    else
                      TextButton(
                        onPressed: () {
                          ref.read(activeProfileIdProvider.notifier).state = profile.profileId;
                        },
                        child: const Text('切り替え'),
                      ),
                    if (profiles.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _confirmDeleteProfile(
                          context,
                          ref,
                          uid,
                          profile,
                          activeProfileId,
                          profiles,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.add)),
              title: const Text('プロフィールを追加'),
              subtitle: const Text('兄弟など、複数人で使う場合に追加できます'),
              onTap: () => _showAddProfileDialog(context, ref, uid),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('プロフィールの読み込みに失敗しました: $err'),
      ),
    );
  }

  /// フレンド追加・ランキングで使う「フレンドID」を表示する。
  /// friend_provider.dart / leaderboard_provider.dart と同じ
  /// FirestoreService.rankingDocId(uid, profileId) の複合ID。
  void _showFriendIdDialog(BuildContext context, String uid, User profile) {
    final friendId = FirestoreService.rankingDocId(uid, profile.profileId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${profile.displayName}のフレンドID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('このIDを友達に伝えると、フレンド追加やチャレンジができます。'),
            const SizedBox(height: 12),
            SelectableText(
              friendId,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: friendId));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('フレンドIDをコピーしました')),
              );
            },
            child: const Text('コピー'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteProfile(
    BuildContext context,
    WidgetRef ref,
    String uid,
    User profile,
    String activeProfileId,
    List<User> profiles,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プロフィールを削除しますか？'),
        content: Text(
          '「${profile.displayName}」の学習履歴・目標・ランキングもすべて削除されます。この操作は取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final firestoreService = ref.read(firestoreServiceProvider);
    await firestoreService.deleteProfile(uid, profile.profileId);

    // 削除したプロフィールが選択中だった場合は、残りの先頭プロフィールに切り替える
    if (profile.profileId == activeProfileId) {
      final remaining = profiles.where((p) => p.profileId != profile.profileId).toList();
      if (remaining.isNotEmpty) {
        ref.read(activeProfileIdProvider.notifier).state = remaining.first.profileId;
      }
    }

    ref.invalidate(userProfilesProvider(uid));
    ref.invalidate(currentUserProvider);
  }

  Future<void> _showAddProfileDialog(BuildContext context, WidgetRef ref, String uid) async {
    final controller = TextEditingController();
    String selectedIcon = _avatarIconChoices.first;
    String selectedLevel = 'LEVEL_10';
    const levels = [
      'LEVEL_10',
      'LEVEL_9',
      'LEVEL_8',
      'LEVEL_7',
      'LEVEL_6',
      'LEVEL_5',
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('プロフィールを追加'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  maxLength: 20,
                  decoration: const InputDecoration(labelText: 'ニックネーム'),
                ),
                const SizedBox(height: 8),
                const Text('アイコン', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: _avatarIconChoices.map((icon) {
                    final selected = icon == selectedIcon;
                    return ChoiceChip(
                      label: Text(icon, style: const TextStyle(fontSize: 18)),
                      selected: selected,
                      onSelected: (_) => setState(() => selectedIcon = icon),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('受験級', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: selectedLevel,
                  isExpanded: true,
                  items: levels
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => selectedLevel = value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) return;

                  final firestoreService = ref.read(firestoreServiceProvider);
                  final newProfileId = const Uuid().v4();
                  await firestoreService.createUser(
                    User(
                      uid: uid,
                      profileId: newProfileId,
                      displayName: name,
                      avatarIcon: selectedIcon,
                      currentLevel: selectedLevel,
                      streakCount: 0,
                      createdAt: DateTime.now(),
                    ),
                  );

                  ref.invalidate(userProfilesProvider(uid));
                  ref.read(activeProfileIdProvider.notifier).state = newProfileId;

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('追加'),
              ),
            ],
          );
        },
      ),
    );
  }
}
