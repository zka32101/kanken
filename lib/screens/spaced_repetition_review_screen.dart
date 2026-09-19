import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/spaced_repetition_item.dart';
import '../providers/spaced_repetition_provider.dart';

class SpacedRepetitionReviewScreen extends ConsumerStatefulWidget {
  const SpacedRepetitionReviewScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SpacedRepetitionReviewScreen> createState() =>
      _SpacedRepetitionReviewScreenState();
}

class _SpacedRepetitionReviewScreenState
    extends ConsumerState<SpacedRepetitionReviewScreen> {
  int _currentIndex = 0;
  bool _showAnswer = false;
  int _correctCount = 0;
  List<SpacedRepetitionItem> _reviewItems = [];
  bool _isLoading = true;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _loadReviewSession();
  }

  Future<void> _loadReviewSession() async {
    final dueItems = await ref.read(dueReviewItemsProvider.future);

    setState(() {
      _reviewItems = dueItems;
      _isLoading = false;
      _isFinished = dueItems.isEmpty;
    });
  }

  SpacedRepetitionItem? get _currentItem {
    if (_currentIndex >= _reviewItems.length) return null;
    return _reviewItems[_currentIndex];
  }

  Future<void> _submitQuality(int quality) async {
    if (quality >= 3) _correctCount++;

    await recordReviewResult(
      item: _reviewItems[_currentIndex],
      quality: quality,
    );

    if (_currentIndex + 1 >= _reviewItems.length) {
      setState(() => _isFinished = true);
      ref.invalidate(dueReviewItemsProvider);
      ref.invalidate(allSpacedRepetitionItemsProvider);
      ref.invalidate(reviewSessionStatsProvider);
    } else {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('間隔反復復習'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isFinished
              ? _buildFinishedView(context)
              : _buildReviewView(context),
    );
  }

  Widget _buildFinishedView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              _reviewItems.isEmpty ? '今日の復習はありません！' : '復習完了！',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_reviewItems.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '正解: $_correctCount / ${_reviewItems.length}問',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('戻る'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewView(BuildContext context) {
    final item = _currentItem;
    if (item == null) {
      return const Center(child: Text('問題データを読み込めませんでした'));
    }

    final progress = (_currentIndex + 1) / _reviewItems.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 進捗バー
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_currentIndex + 1} / ${_reviewItems.length}問  (習熟: ${item.masteryLevel})',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 32),

          // 問題カード
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.kanji,
                          style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
                        ),
                        if (item.question.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            item.question,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (_showAnswer)
                          Text(
                            item.correctAnswer,
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          OutlinedButton(
                            onPressed: () => setState(() => _showAnswer = true),
                            child: const Text('答えを表示'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 評価ボタン（回答表示後のみ）
          if (_showAnswer) _buildQualityButtons(),
        ],
      ),
    );
  }

  Widget _buildQualityButtons() {
    return Column(
      children: [
        Text(
          'どのくらい覚えていましたか？',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildQualityButton(0, '忘れた', Colors.red),
            _buildQualityButton(3, '難しい', Colors.orange),
            _buildQualityButton(4, '普通', Colors.blue),
            _buildQualityButton(5, '簡単', Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _buildQualityButton(int quality, String label, Color color) {
    return ElevatedButton(
      onPressed: () => _submitQuality(quality),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label),
    );
  }
}
