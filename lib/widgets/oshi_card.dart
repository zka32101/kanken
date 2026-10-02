import 'package:app_common_kit/app_common_kit.dart'
    show MascotStage, MascotWidget, coinProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/oshi_provider.dart';

/// ホームの「推し」カード。学習が進むと成長し、学習コインの残高を控えめに出す。
class OshiCard extends ConsumerWidget {
  const OshiCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stage = ref.watch(oshiStageProvider).valueOrNull ?? MascotStage.lv1;

    // コインは付加機能。未設定でも画面は出す。
    int? balance;
    try {
      balance = ref.watch(coinProvider).balance;
    } catch (_) {}

    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            MascotWidget(stage: stage, size: 88),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('あなたの推し  Lv${stage.level}',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text('学習すると成長します', style: theme.textTheme.bodySmall),
                  if (balance != null) ...[
                    const SizedBox(height: 4),
                    Text('学習コイン $balance', style: theme.textTheme.labelMedium),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
