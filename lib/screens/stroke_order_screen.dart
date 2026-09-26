import 'package:flutter/material.dart';
import '../data/kanji_info_data.dart';
import '../data/stroke_order_sample_data.dart';
import '../widgets/stroke_order_animation.dart';
import '../theme/app_theme.dart';

/// 書き順ガイド画面（漢字一覧 → タップで書き順アニメーション表示）
class StrokeOrderScreen extends StatefulWidget {
  const StrokeOrderScreen({Key? key}) : super(key: key);

  @override
  State<StrokeOrderScreen> createState() => _StrokeOrderScreenState();
}

class _StrokeOrderScreenState extends State<StrokeOrderScreen> {
  String? _selectedKanji;

  @override
  Widget build(BuildContext context) {
    final kanjiList = StrokeOrderSampleData.availableKanji;
    final selected = _selectedKanji ?? kanjiList.first;
    final data = StrokeOrderSampleData.getStrokeOrder(selected)!;
    final info = KanjiInfoData.get(selected);

    return Scaffold(
      appBar: AppBar(
        title: const Text('書き順ガイド'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 書き順アニメーション表示エリア
            StrokeOrderAnimationWidget(
              key: ValueKey(selected),
              data: data,
              size: 260,
            ),
            if (info != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '読み方: ${info.reading}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '例: ${info.example}',
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // 漢字選択グリッド
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'かんじをえらぼう',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: kanjiList.length,
                itemBuilder: (context, index) {
                  final kanji = kanjiList[index];
                  final isSelected = kanji == selected;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedKanji = kanji),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          kanji,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
