import 'dart:typed_data';

import 'package:app_common_kit/app_common_kit.dart' show MascotStage, UkalabCert, UkalabOshiCard;
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

/// ホームの「推し」カード。共通キットの [UkalabOshiCard] に、漢字検定の成長段階・
/// 試験日・連続日数を渡す。推しの選択・着替え・合格報告・表示切替はキット側。
class OshiCard extends ConsumerWidget {
  const OshiCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stage = ref.watch(oshiStageProvider).valueOrNull ?? MascotStage.lv1;
    final user = ref.watch(currentUserProvider).valueOrNull;
    return UkalabOshiCard(
      cert: UkalabCert.kanjiKentei,
      stage: stage,
      appId: 'kanken',
      examDate: user?.examDate,
      streakDays: user?.streakCount ?? 0,
      onShare: shareCardImage,
    );
  }
}
