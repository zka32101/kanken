import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 課金画面や外部ストアへの遷移など、子どもが誤って進んでしまうと困る
/// 操作の前に表示する軽量な保護者確認ダイアログ。
///
/// ランダムな2桁の四則演算を出題し、正解した場合のみ
/// `Navigator.pop(context, true)` で結果を返す。
///
/// 直接使うより [requireParentalGate] を使う方が簡潔。
class ParentalGateDialog extends StatefulWidget {
  static const String defaultTitle = '保護者の方へ確認';
  static const String defaultDescription = 'これは大人の方が行う操作です。\n下の計算の答えを入力してください。';
  static const String defaultOkLabel = 'つぎへ';
  static const String defaultCancelLabel = 'やめる';

  final String? title;
  final String? description;
  final String? okLabel;
  final String? cancelLabel;
  final Color? primaryColor;

  const ParentalGateDialog({
    super.key,
    this.title,
    this.description,
    this.okLabel,
    this.cancelLabel,
    this.primaryColor,
  });

  @override
  State<ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<ParentalGateDialog> {
  late final int _a;
  late final int _b;
  late final bool _isAddition;
  late final int _correctAnswer;
  final _controller = TextEditingController();
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _isAddition = random.nextBool();
    if (_isAddition) {
      // 10〜30同士の足し算（子どもには少し難しく、大人なら瞬時に解ける程度）
      _a = 10 + random.nextInt(21);
      _b = 10 + random.nextInt(21);
      _correctAnswer = _a + _b;
    } else {
      // 引いた結果が必ず正の数になるよう大きい方を_aにする
      final x = 10 + random.nextInt(21);
      final y = 10 + random.nextInt(21);
      _a = math.max(x, y);
      _b = math.min(x, y);
      _correctAnswer = _a - _b;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final input = int.tryParse(_controller.text.trim());
    if (input == _correctAnswer) {
      Navigator.pop(context, true);
    } else {
      setState(() => _showError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.colorScheme.primary;
    final op = _isAddition ? '+' : '-';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🔒', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title ?? ParentalGateDialog.defaultTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              widget.description ?? ParentalGateDialog.defaultDescription,
              style: TextStyle(fontSize: 14, height: 1.6, color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '$_a $op $_b = ?',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '答えを入力',
                errorText: _showError ? '答えが違います' : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.cancelLabel ?? ParentalGateDialog.defaultCancelLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.okLabel ?? ParentalGateDialog.defaultOkLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// [ParentalGateDialog] を表示し、正解した場合のみ `true` を返すヘルパー。
///
/// 課金画面（ペイウォール）や外部ストアへの遷移など、保護者の確認が
/// 必要な操作の前に呼び出す。キャンセル・不正解・ダイアログを閉じた
/// 場合は `false`。
Future<bool> requireParentalGate(
  BuildContext context, {
  String? title,
  String? description,
  String? okLabel,
  String? cancelLabel,
  Color? primaryColor,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ParentalGateDialog(
      title: title,
      description: description,
      okLabel: okLabel,
      cancelLabel: cancelLabel,
      primaryColor: primaryColor,
    ),
  );
  return result ?? false;
}
