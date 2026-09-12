import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/challenge_invitation.dart';
import '../providers/challenge_provider.dart';

class ChallengeScreen extends ConsumerStatefulWidget {
  const ChallengeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challengeState = ref.watch(challengeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎮 チャレンジ'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
        foregroundColor: Colors.black87,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(child: Text('アクティブ')),
            Tab(child: Text('受信')),
            Tab(child: Text('送信')),
            Tab(child: Text('完了')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: アクティブなチャレンジ
          _ActiveChallengesTab(),
          // Tab 2: 受信したリクエスト
          _IncomingChallengesTab(),
          // Tab 3: 送信したリクエスト
          _OutgoingChallengesTab(),
          // Tab 4: 完了済みチャレンジ
          _CompletedChallengesTab(),
        ],
      ),
    );
  }
}

/// Tab 1: アクティブなチャレンジ
class _ActiveChallengesTab extends ConsumerWidget {
  const _ActiveChallengesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeChallengesAsync = ref.watch(activeChallengesProvider);

    return activeChallengesAsync.when(
      data: (challenges) {
        if (challenges.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_esports_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'アクティブなチャレンジはありません',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            return _ChallengeCard(challenge: challenge);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('エラー: $error'),
      ),
    );
  }
}

/// Tab 2: 受信したリクエスト
class _IncomingChallengesTab extends ConsumerWidget {
  const _IncomingChallengesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomingAsync = ref.watch(incomingChallengesProvider);

    return incomingAsync.when(
      data: (challenges) {
        if (challenges.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mail_outline,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'リクエストがありません',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            return _RequestCard(
              challenge: challenge,
              isIncoming: true,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('エラー: $error'),
      ),
    );
  }
}

/// Tab 3: 送信したリクエスト
class _OutgoingChallengesTab extends ConsumerWidget {
  const _OutgoingChallengesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outgoingAsync = ref.watch(outgoingChallengesProvider);

    return outgoingAsync.when(
      data: (challenges) {
        if (challenges.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.send_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  '送信したリクエストはありません',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            return _RequestCard(
              challenge: challenge,
              isIncoming: false,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('エラー: $error'),
      ),
    );
  }
}

/// Tab 4: 完了済みチャレンジ
class _CompletedChallengesTab extends ConsumerWidget {
  const _CompletedChallengesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedAsync = ref.watch(completedChallengesProvider);

    return completedAsync.when(
      data: (challenges) {
        if (challenges.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.done_all_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  '完了したチャレンジはありません',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            return _ResultCard(challenge: challenge);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('エラー: $error'),
      ),
    );
  }
}

/// チャレンジカード（アクティブなチャレンジ）
class _ChallengeCard extends ConsumerStatefulWidget {
  final ChallengeInvitation challenge;

  const _ChallengeCard({
    Key? key,
    required this.challenge,
  }) : super(key: key);

  @override
  ConsumerState<_ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends ConsumerState<_ChallengeCard> {
  int? _myScore;

  @override
  Widget build(BuildContext context) {
    final daysLeft = widget.challenge.expiresAt
        .difference(DateTime.now())
        .inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.cyan.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー: 相手名 vs 自分
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.challenge.fromUserName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'vs',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.challenge.toUserName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // スコア表示エリア
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ScoreDisplay(
                    score: widget.challenge.fromScore,
                    label: widget.challenge.fromUserName,
                  ),
                  Text(
                    '-',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _ScoreDisplay(
                    score: widget.challenge.toScore,
                    label: widget.challenge.toUserName,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // スコア入力エリア
            if (_myScore == null)
              Column(
                children: [
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'あなたのスコアを入力',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _myScore = int.tryParse(value);
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _myScore != null
                          ? () => _submitScore(context)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'スコアを記録',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 8),

            // 有効期限表示
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ステータス: ${widget.challenge.getStatusLabel()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '残り $daysLeft 日',
                  style: TextStyle(
                    fontSize: 12,
                    color: daysLeft <= 2 ? Colors.red : Colors.grey.shade600,
                    fontWeight: daysLeft <= 2 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitScore(BuildContext context) async {
    if (_myScore == null) return;

    final notifier = ref.read(challengeNotifierProvider.notifier);
    await notifier.submitScore(
      invitationId: widget.challenge.invitationId,
      opponentUserId: widget.challenge.fromUserId == widget.challenge.toUserId
          ? widget.challenge.toUserId
          : widget.challenge.fromUserId,
      myScore: _myScore!,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('スコアを記録しました')),
    );
  }
}

/// スコア表示小ウィジェット
class _ScoreDisplay extends StatelessWidget {
  final int? score;
  final String label;

  const _ScoreDisplay({
    Key? key,
    required this.score,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          score?.toString() ?? '-',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: score != null ? Colors.blue : Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// リクエストカード（受信・送信）
class _RequestCard extends ConsumerWidget {
  final ChallengeInvitation challenge;
  final bool isIncoming;

  const _RequestCard({
    Key? key,
    required this.challenge,
    required this.isIncoming,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysLeft = challenge.expiresAt.difference(DateTime.now()).inDays;
    final oppName =
        isIncoming ? challenge.fromUserName : challenge.toUserName;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: isIncoming
                ? [Colors.orange.shade50, Colors.amber.shade50]
                : [Colors.green.shade50, Colors.teal.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isIncoming ? '$oppName からのチャレンジ' : '$oppName へのチャレンジ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '受信日: ${challenge.createdAt.toString().split('.')[0]}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isIncoming ? Icons.inbox : Icons.outbox,
                  color: isIncoming ? Colors.orange : Colors.green,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // アクションボタン
            if (isIncoming)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _acceptChallenge(context, ref),
                      icon: const Icon(Icons.check),
                      label: const Text('受け入れ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _declineChallenge(context, ref),
                      icon: const Icon(Icons.close),
                      label: const Text('拒否'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Text(
                '待機中...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),

            const SizedBox(height: 8),

            // 有効期限
            Text(
              '有効期限: 残り $daysLeft 日',
              style: TextStyle(
                fontSize: 12,
                color: daysLeft <= 2 ? Colors.red : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptChallenge(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(challengeNotifierProvider.notifier);
    await notifier.acceptChallenge(
      invitationId: challenge.invitationId,
      fromUserId: challenge.fromUserId,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('チャレンジを受け入れました')),
    );
  }

  Future<void> _declineChallenge(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(challengeNotifierProvider.notifier);
    await notifier.declineChallenge(
      invitationId: challenge.invitationId,
      fromUserId: challenge.fromUserId,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('チャレンジを拒否しました')),
    );
  }
}

/// 結果カード（完了済みチャレンジ）
class _ResultCard extends StatelessWidget {
  final ChallengeInvitation challenge;

  const _ResultCard({Key? key, required this.challenge}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final winner = challenge.getWinner();
    final scoreDiff = challenge.getScoreDifference() ?? 0;
    final isWin = winner != null; // 同点の場合はfalse

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: isWin
                ? [Colors.purple.shade50, Colors.deepPurple.shade50]
                : [Colors.grey.shade50, Colors.blueGrey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '対戦結果',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isWin ? Colors.amber : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    winner != null ? '決着' : '同点',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // スコア比較
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ResultScoreDisplay(
                    name: challenge.fromUserName,
                    score: challenge.fromScore ?? 0,
                    isWinner: winner == challenge.fromUserId,
                  ),
                  Text(
                    '-',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _ResultScoreDisplay(
                    name: challenge.toUserName,
                    score: challenge.toScore ?? 0,
                    isWinner: winner == challenge.toUserId,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 差分表示
            Center(
              child: Text(
                'スコア差: $scoreDiff',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 完了日時
            Text(
              '完了: ${challenge.completedAt?.toString().split('.')[0] ?? 'N/A'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 結果スコア表示小ウィジェット
class _ResultScoreDisplay extends StatelessWidget {
  final String name;
  final int score;
  final bool isWinner;

  const _ResultScoreDisplay({
    Key? key,
    required this.name,
    required this.score,
    required this.isWinner,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isWinner)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Icon(
              Icons.emoji_events,
              color: Colors.amber,
              size: 20,
            ),
          ),
        Text(
          score.toString(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isWinner ? Colors.amber : Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
