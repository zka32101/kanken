import 'dart:typed_data';

import 'package:app_common_kit/app_common_kit.dart'
    show
        CharacterPack,
        ExamPhase,
        MascotDayState,
        MascotStage,
        MascotWidget,
        Outfit,
        UkalabCert,
        WardrobeScreen,
        coinProvider,
        equippedOutfitProvider,
        showPassReportDialog;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/oshi_provider.dart';
import '../viewmodels/user_viewmodel.dart';

/// 画像（共有カード）をOSの共有シートで共有する。
Future<void> shareCardImage(Uint8List png) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(png, mimeType: 'image/png', name: 'ukalab_pass.png')],
      text: '#うかラボ #漢字検定',
    ),
  );
}

enum _OshiAction { wardrobe, passReport }

/// ホームの「推し」カード。学習が進むと成長し、学習コインの残高を控えめに出す。
/// メニューから着替え・ショップと、試験の結果報告（合格報告）を開ける。
class OshiCard extends ConsumerWidget {
  const OshiCard({Key? key}) : super(key: key);

  ExamPhase _examPhase(DateTime? examDate) =>
      MascotDayState(examDate: examDate).examPhase(DateTime.now());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stage = ref.watch(oshiStageProvider).valueOrNull ?? MascotStage.lv1;
    final examDate = ref.watch(currentUserProvider).valueOrNull?.examDate;

    // コインと衣装は付加機能。未設定でも画面は出す。
    int? balance;
    try {
      balance = ref.watch(coinProvider).balance;
    } catch (_) {}
    Outfit? outfit;
    try {
      outfit = ref.watch(equippedOutfitProvider);
    } catch (_) {}

    void onSelected(_OshiAction a) {
      switch (a) {
        case _OshiAction.wardrobe:
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => WardrobeScreen(
              cert: UkalabCert.kanjiKentei,
              examPhase: _examPhase(examDate),
              stage: stage,
              pack: CharacterPack.standard,
            ),
          ));
        case _OshiAction.passReport:
          showPassReportDialog(
            context,
            ref,
            cert: UkalabCert.kanjiKentei,
            stage: stage,
            onShare: shareCardImage,
          );
      }
    }

    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        child: Row(
          children: [
            MascotWidget(
              stage: stage,
              outfit: outfit,
              examPhase: _examPhase(examDate),
              size: 88,
            ),
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
            PopupMenuButton<_OshiAction>(
              tooltip: '推しのメニュー',
              icon: const Icon(Icons.more_vert),
              onSelected: onSelected,
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: _OshiAction.wardrobe, child: Text('着替え・ショップ')),
                PopupMenuItem(
                    value: _OshiAction.passReport, child: Text('試験の結果を報告')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
