import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/user_viewmodel.dart';
import '../viewmodels/services_provider.dart';

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
