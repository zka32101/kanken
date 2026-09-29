import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/kanji_info_data.dart';
import '../data/kanji_radical_data.dart';
import '../data/stroke_order_sample_data.dart';
import '../viewmodels/services_provider.dart';
import '../viewmodels/user_viewmodel.dart';
import '../views/handwriting_practice_screen.dart';
import '../widgets/stroke_order_animation.dart';
import '../theme/app_theme.dart';

/// 選択中の級で実際に出題される漢字のうち、書き順データがあるものだけに絞る。
final _levelStrokeOrderKanjiProvider =
    FutureProvider.family<List<String>, String>((ref, level) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final questions = await firestoreService.getQuestionsByLevel(level, limit: 200);
  final available = StrokeOrderSampleData.availableKanji.toSet();
  final levelKanji = questions.map((q) => q.kanji).where(available.contains).toSet().toList();
  return levelKanji.isNotEmpty ? levelKanji : StrokeOrderSampleData.availableKanji;
});

/// 漢字の学習画面（漢字一覧 → タップで書き順アニメーション・読み方・用例を表示）
/// 一覧は現在選択中の級（currentLevelProvider）に出題される漢字のみに絞る。
class StrokeOrderScreen extends ConsumerStatefulWidget {
  const StrokeOrderScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StrokeOrderScreen> createState() => _StrokeOrderScreenState();
}

class _StrokeOrderScreenState extends ConsumerState<StrokeOrderScreen> {
  String? _selectedKanji;
  String? _selectedForLevel;

  @override
  Widget build(BuildContext context) {
    final level = ref.watch(currentLevelProvider);
    final kanjiListAsync = ref.watch(_levelStrokeOrderKanjiProvider(level));
    final learnedIds = ref.watch(learnedKanjiIdsProvider).valueOrNull ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('漢字の学習'),
        centerTitle: true,
      ),
      body: kanjiListAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('エラー: $err')),
        data: (kanjiList) {
          if (kanjiList.isEmpty) {
            return const Center(child: Text('この級の漢字データがありません'));
          }
          // 級が変わったら選択をリセットする（別の級の漢字が選ばれたままにならないように）。
          if (_selectedForLevel != level) {
            _selectedForLevel = level;
            _selectedKanji = null;
          }
          final selected =
              (_selectedKanji != null && kanjiList.contains(_selectedKanji))
                  ? _selectedKanji!
                  : kanjiList.first;
          return _buildContent(context, level, kanjiList, selected, learnedIds);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    String level,
    List<String> kanjiList,
    String selected,
    Set<String> learnedIds,
  ) {
    final data = StrokeOrderSampleData.getStrokeOrder(selected)!;
    final info = KanjiInfoData.get(selected);
    final radicalInfo = KanjiRadicalData.get(selected);

    return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 書き順アニメーション表示エリア
            StrokeOrderAnimationWidget(
              key: ValueKey(selected),
              data: data,
              size: 260,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit),
                label: Text('「$selected」を書く練習'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HandwritingPracticeScreen(
                        level: level,
                        kanji: selected,
                      ),
                    ),
                  );
                },
              ),
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
                    const Text(
                      '読み方',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: info.readings.map((reading) {
                        return Chip(
                          label: Text(reading),
                          backgroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                    if (radicalInfo != null) ...[
                      const SizedBox(height: 12),
                      const Text(
                        '部首',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text('${radicalInfo.radical}（${radicalInfo.radicalName}）'),
                        backgroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text(
                      '使い方の例',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    ...info.examples.map(
                      (example) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '・$example',
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ),
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
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
                final isLearned = learnedIds.contains('$level-$kanji');
                return GestureDetector(
                  onTap: () => setState(() => _selectedKanji = kanji),
                  child: Stack(
                    children: [
                      Container(
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
                      if (isLearned)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
  }
}
