# 🛠️ P1機能 実装ガイド

## 対象: デイリーチャレンジ + ゲーミフィケーション

**期間:** 1-2週間  
**優先度:** 🥇 最高  
**難度:** 中程度

---

## 📋 実装チェックリスト

### Phase 1: データモデル＆DB設計（Day 1-2）

- [ ] Firestore スキーマ設計
- [ ] Dart models 作成
- [ ] Provider/Riverpod セットアップ

### Phase 2: Backend ロジック（Day 3-4）

- [ ] デイリーチャレンジ生成ロジック
- [ ] 報酬計算ロジック
- [ ] ユーザー統計更新

### Phase 3: UI 実装（Day 5-7）

- [ ] デイリーチャレンジ画面
- [ ] 進捗ダッシュボード
- [ ] 報酬アニメーション

### Phase 4: テスト＆デバッグ（Day 8-9）

- [ ] Unit テスト
- [ ] UI テスト
- [ ] 統合テスト

---

## 📐 Firestore スキーマ設計

```
users/{userId}
├── profile
│   ├── name (String)
│   ├── level (int)
│   ├── experience (int)
│   ├── coins (int)
│   └── joinedAt (Timestamp)
│
├── stats
│   ├── totalQuestions (int)
│   ├── correctCount (int)
│   ├── streak (int) ← 連続日数
│   ├── recordStreak (int)
│   ├── accuracyRate (double) ← 正答率
│   └── lastPlayedAt (Timestamp)
│
└── dailyProgress/{date} ← YYYY-MM-DD
    ├── date (String)
    ├── completed (bool)
    ├── correctCount (int/10)
    ├── earnedCoins (int)
    └── timestamp (Timestamp)

challenges/{challengeId}
├── date (String) ← YYYY-MM-DD
├── questions (List<String>) ← question IDs
├── difficulty (String) ← easy/medium/hard
├── createdAt (Timestamp)
└── resetTime (Timestamp) ← 翌日の0:00

rewards/{userId}/{rewardId}
├── type (String) ← correct_answer/streak_bonus/etc
├── amount (int) ← EXP or coins
├── earnedAt (Timestamp)
└── message (String)
```

---

## 🔧 実装コード

### 1. Models 定義

```dart
// lib/models/daily_challenge.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DailyChallenge {
  final String id;
  final String date; // YYYY-MM-DD
  final List<String> questionIds;
  final String difficulty; // easy/medium/hard
  final DateTime resetTime;
  
  const DailyChallenge({
    required this.id,
    required this.date,
    required this.questionIds,
    required this.difficulty,
    required this.resetTime,
  });
  
  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'] as String,
      date: json['date'] as String,
      questionIds: List<String>.from(json['questions'] as List),
      difficulty: json['difficulty'] as String,
      resetTime: (json['resetTime'] as Timestamp).toDate(),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'questions': questionIds,
    'difficulty': difficulty,
    'resetTime': resetTime,
  };
  
  bool get isExpired => DateTime.now().isAfter(resetTime);
}

// lib/models/user_stats.dart
class UserStats {
  final String userId;
  final int level;
  final int experience;
  final int coins;
  final int totalQuestions;
  final int correctCount;
  final int streak;
  final int recordStreak;
  final double accuracyRate;
  final DateTime lastPlayedAt;
  
  const UserStats({
    required this.userId,
    required this.level,
    required this.experience,
    required this.coins,
    required this.totalQuestions,
    required this.correctCount,
    required this.streak,
    required this.recordStreak,
    required this.accuracyRate,
    required this.lastPlayedAt,
  });
  
  // ランク判定
  String getRank() {
    if (experience < 500) return '新米受験生';
    if (experience < 1000) return '見習い学生';
    if (experience < 2000) return '中堅学生';
    if (experience < 5000) return '精鋭受験生';
    return 'マスター';
  }
  
  // 次のレベルまでの経験値
  int get expToNextLevel {
    final nextThreshold = (level * 500);
    return nextThreshold - experience;
  }
  
  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      userId: json['userId'] as String,
      level: json['level'] as int? ?? 1,
      experience: json['experience'] as int? ?? 0,
      coins: json['coins'] as int? ?? 0,
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      correctCount: json['correctCount'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      recordStreak: json['recordStreak'] as int? ?? 0,
      accuracyRate: json['accuracyRate'] as double? ?? 0.0,
      lastPlayedAt: (json['lastPlayedAt'] as Timestamp?)?.toDate() 
        ?? DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'level': level,
    'experience': experience,
    'coins': coins,
    'totalQuestions': totalQuestions,
    'correctCount': correctCount,
    'streak': streak,
    'recordStreak': recordStreak,
    'accuracyRate': accuracyRate,
    'lastPlayedAt': lastPlayedAt,
  };
}

// lib/models/reward.dart
enum RewardType {
  correctAnswer,
  streakBonus,
  dailyChallengeBonus,
  levelUp,
}

class Reward {
  final RewardType type;
  final int amount; // EXP or coins
  final String message;
  final DateTime earnedAt;
  
  const Reward({
    required this.type,
    required this.amount,
    required this.message,
    required this.earnedAt,
  });
  
  factory Reward.correctAnswer() => Reward(
    type: RewardType.correctAnswer,
    amount: 10,
    message: '✨ +10 EXP',
    earnedAt: DateTime.now(),
  );
  
  factory Reward.streakBonus(int streak) => Reward(
    type: RewardType.streakBonus,
    amount: 50,
    message: '🔥 連続$streak日！ +50 EXP',
    earnedAt: DateTime.now(),
  );
  
  factory Reward.dailyChallengeComplete() => Reward(
    type: RewardType.dailyChallengeBonus,
    amount: 100,
    message: '🎉 デイリーチャレンジ完了！ +100 coins',
    earnedAt: DateTime.now(),
  );
}
```

### 2. Riverpod Providers

```dart
// lib/providers/daily_challenge_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_challenge.dart';
import '../models/user_stats.dart';

final firebaseProvider = Provider((ref) => FirebaseFirestore.instance);

// デイリーチャレンジ取得
final dailyChallengeProvider = FutureProvider<DailyChallenge>((ref) async {
  final db = ref.watch(firebaseProvider);
  final today = DateTime.now();
  final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  
  final doc = await db.collection('challenges').doc(dateStr).get();
  
  if (!doc.exists) {
    // チャレンジが存在しない場合は作成
    return _createDailyChallenge(db, dateStr);
  }
  
  return DailyChallenge.fromJson(doc.data()!);
});

// ユーザー統計取得
final userStatsProvider = FutureProvider<UserStats>((ref) async {
  final db = ref.watch(firebaseProvider);
  final userId = 'CURRENT_USER_ID'; // Firebase Auth から取得
  
  final doc = await db.collection('users').doc(userId).collection('stats').doc('current').get();
  
  if (!doc.exists) {
    return UserStats(
      userId: userId,
      level: 1,
      experience: 0,
      coins: 0,
      totalQuestions: 0,
      correctCount: 0,
      streak: 0,
      recordStreak: 0,
      accuracyRate: 0.0,
      lastPlayedAt: DateTime.now(),
    );
  }
  
  return UserStats.fromJson(doc.data()!);
});

// デイリーチャレンジ State Notifier
class DailyChallengeNotifier extends StateNotifier<AsyncValue<DailyChallenge>> {
  final FirebaseFirestore _firestore;
  
  DailyChallengeNotifier(this._firestore) : super(const AsyncValue.loading());
  
  Future<void> loadToday() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final today = DateTime.now();
      final dateStr = _formatDate(today);
      
      final doc = await _firestore.collection('challenges').doc(dateStr).get();
      
      if (!doc.exists) {
        return _createDailyChallenge(dateStr);
      }
      
      return DailyChallenge.fromJson(doc.data()!);
    });
  }
  
  Future<void> submitAnswer(
    String userId,
    String questionId,
    bool isCorrect,
  ) async {
    await _firestore.collection('users').doc(userId).update({
      'stats.totalQuestions': FieldValue.increment(1),
      if (isCorrect)
        'stats.correctCount': FieldValue.increment(1),
    });
    
    if (isCorrect) {
      // 経験値加算
      await _addExperience(userId, 10);
    }
  }
  
  Future<void> _addExperience(String userId, int amount) async {
    final userRef = _firestore.collection('users').doc(userId);
    
    await userRef.update({
      'stats.experience': FieldValue.increment(amount),
    });
    
    // レベルアップ判定
    final doc = await userRef.get();
    final stats = UserStats.fromJson(doc.data()!['stats'] ?? {});
    
    if (stats.experience % 500 == 0) {
      await userRef.update({
        'stats.level': FieldValue.increment(1),
      });
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  Future<DailyChallenge> _createDailyChallenge(String dateStr) async {
    // ランダムに10問選択
    final questionsSnap = await _firestore
      .collection('questions')
      .limit(10)
      .get();
    
    final challenge = DailyChallenge(
      id: dateStr,
      date: dateStr,
      questionIds: questionsSnap.docs.map((d) => d.id).toList(),
      difficulty: 'medium',
      resetTime: DateTime.now().add(Duration(days: 1)),
    );
    
    await _firestore.collection('challenges').doc(dateStr).set(challenge.toJson());
    
    return challenge;
  }
}

final dailyChallengeNotifierProvider = 
  StateNotifierProvider<DailyChallengeNotifier, AsyncValue<DailyChallenge>>((ref) {
  final firestore = ref.watch(firebaseProvider);
  return DailyChallengeNotifier(firestore);
});
```

### 3. UI - デイリーチャレンジ画面

```dart
// lib/screens/daily_challenge_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

class DailyChallengeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(dailyChallengeNotifierProvider);
    final statsAsync = ref.watch(userStatsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('デイリーチャレンジ'),
        elevation: 0,
      ),
      body: challengeAsync.when(
        data: (challenge) => statsAsync.when(
          data: (stats) => _buildChallengeBody(
            context,
            challenge,
            stats,
            ref,
          ),
          loading: () => Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('エラー: $err')),
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('エラー: $err')),
      ),
    );
  }
  
  Widget _buildChallengeBody(
    BuildContext context,
    DailyChallenge challenge,
    UserStats stats,
    WidgetRef ref,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. ステータスカード
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '今日のチャレンジ',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 12),
                  Text(
                    '10問中 0問 解答',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: 12),
                  LinearProgressIndicator(value: 0.0),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          
          // 2. ユーザー統計
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'レベル',
                  value: '${stats.level}',
                  icon: '⭐',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: 'コイン',
                  value: '${stats.coins}',
                  icon: '💰',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: 'ストリーク',
                  value: '${stats.streak}日',
                  icon: '🔥',
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // 3. チャレンジ開始ボタン
          ElevatedButton.large(
            onPressed: () {
              // チャレンジ詳細画面へ遷移
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChallengeDetailScreen(
                    challenge: challenge,
                    stats: stats,
                  ),
                ),
              );
            },
            child: Text('チャレンジを開始'),
          ),
          SizedBox(height: 16),
          
          // 4. ボーナス情報
          Card(
            color: Colors.amber.withAlpha(25),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🎉 本日のボーナス'),
                  SizedBox(height: 8),
                  Text('• 完了時: +100 コイン'),
                  Text('• 全問正解: +50 EXP'),
                  Text('• ストリーク: 連続 ${stats.streak} 日！'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Text(icon, style: TextStyle(fontSize: 24)),
            SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 📦 必要なパッケージ追加

```yaml
# pubspec.yaml に追加
dependencies:
  cloud_firestore: ^4.14.0
  fl_chart: ^0.65.0
  intl: ^0.19.0
```

**コマンド:**
```bash
flutter pub add cloud_firestore fl_chart intl
```

---

## 🧪 テスト実装

```dart
// test/providers/daily_challenge_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('DailyChallengeNotifier', () {
    late MockFirebaseFirestore firestore;
    late DailyChallengeNotifier notifier;
    
    setUp(() {
      firestore = MockFirebaseFirestore();
      notifier = DailyChallengeNotifier(firestore);
    });
    
    test('デイリーチャレンジ読み込み成功', () async {
      // テストコード
    });
    
    test('正解時に経験値加算', () async {
      // テストコード
    });
    
    test('ストリーク計算', () {
      // テストコード
    });
  });
}
```

---

## 🚀 デプロイ手順

### ローカルテスト
```bash
flutter run -d emulator
```

### Firebase へのデータセット投入
```bash
# Firestore データ初期化スクリプト
firebase firestore:set-data challenges/2026-09-11 --data '{...}'
```

### リリース前チェック
- [ ] Unit テスト成功
- [ ] UI テスト成功
- [ ] Firebase ルール確認
- [ ] パフォーマンス測定

---

**推定コミット:** 9-12 commits  
**推定 PR:** 1-2 review rounds  
**期間:** 1-2 週間
