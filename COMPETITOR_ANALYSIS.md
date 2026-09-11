# 🔍 競合分析＆改善提案

## 1️⃣ 主要競合アプリ分析

### A. 漢検対応アプリ市場

| アプリ名 | 配信 | 価格 | 評価 | 主な機能 |
|---------|------|------|------|---------|
| **漢検 公式アプリ** | iOS/Android | 無料 | ⭐4.2 | 過去問・学習 |
| **漢検学習アプリ** | Android | $4.99 | ⭐4.5 | 練習問題・進捗管理 |
| **漢字検定 問題集** | iOS/Android | 無料+IAP | ⭐3.9 | ゲーム要素・ランキング |
| **漢字検定対策** | Android | $2.99 | ⭐4.1 | 分野別・レベル別 |

### B. 既存プロジェクト（同一開発者）

**kokugo-kore** (国語これ)
- 平仮名・片仮名学習用
- ゲーミフィケーション要素
- 音声機能
- Riverpod 使用

---

## 2️⃣ 現在の kanken 機能分析

### 現実装機能
✅ Flutter + Firebase 基盤
✅ Riverpod 状態管理
✅ Firebase Authentication
✅ Firebase Analytics
✅ Lottie アニメーション
✅ Audio プレイヤー
✅ Material Design

### 不足機能（競合比較）
❌ ゲーミフィケーション（レベル・ボーナス・チャレンジ）
❌ 学習進捗の可視化（グラフ・統計）
❌ ランキング・マルチプレイ
❌ 音声出題（Elevenlabs/TTS）
❌ オフライン対応
❌ エクスポート機能（学習記録）

---

## 3️⃣ 改善提案（優先度順）

### 🥇 P1: 即実装推奨

#### 1. ゲーミフィケーション機能
**目的:** ユーザー継続率向上

```dart
// lib/models/gamification.dart
class UserStats {
  int totalQuestions;      // 解いた問題数
  int streak;              // 連続正解日数
  int level;               // 現在レベル (1-10)
  int experience;          // 累積経験値
  int coins;               // ゲーム内通貨
  
  // ランク判定
  String getRank() {
    if (experience < 500) return '新米受験生';
    if (experience < 1000) return '見習い学生';
    if (experience < 2000) return '中堅学生';
    if (experience < 5000) return '精鋭受験生';
    return 'マスター';
  }
}
```

**実装コスト:** 中程度（1-2週間）

#### 2. 学習進捗ダッシュボード
**目的:** ユーザー満足度・リテンション向上

```dart
// 表示内容
- 週別正解率グラフ
- 分野別進捗 (得意・苦手)
- 今週の学習時間
- 目標達成度 (%)
```

**実装コスト:** 低（fl_chart パッケージ使用）

#### 3. デイリーチャレンジ
**目的:** 毎日の起動促進

```yaml
Features:
  - 毎日更新される10問セット
  - ボーナスコイン獲得
  - 連続クリア記念報酬
  - SNS シェア機能
```

**実装コスト:** 低（1週間以下）

---

### 🥈 P2: 中期改善（1ヶ月以内）

#### 4. 音声機能強化
```dart
// TTS (Text-to-Speech) 統合
- 漢字読み上げ
- 四字熟語の読み上げ
- 音声出題モード

// 実装案
google_ml_kit + tts パッケージ
```

**実装コスト:** 中程度

#### 5. オフライン対応
```dart
// Hive / Sqflite ローカルDB
- ダウンロード済み問題セットをオフライン対応
- 学習データのローカルキャッシュ

// 実装案
riverpod_generator + hive
```

**実装コスト:** 高（Firebase同期が複雑）

#### 6. ソーシャル機能
```yaml
Features:
  - フレンド追加
  - スコア比較
  - ランキング表示
  - チャレンジ招待
```

**実装コスト:** 高（Cloud Functions が必須）

---

### 🥉 P3: 長期改善（2-3ヶ月）

#### 7. AI チューター機能
```dart
// 間違った問題の解説生成
- Cloud Functions + Claude API
- リアルタイム質問応答

example:
User: "なぜ『舫』は『もやい』なの？"
AI: "『舫』は船を岸に結ぶ綱を意味する漢字です。..."
```

**実装コスト:** 非常に高

#### 8. 模擬試験・本番対策
```yaml
Features:
  - 実際の試験形式
  - 時間制限
  - 成績レポート
  - 合格可能性判定
```

**実装コスト:** 高

---

## 4️⃣ 競合との差別化ポイント

| 項目 | 競合 | kanken提案 |
|------|------|----------|
| **学習形式** | 問題形式 | ゲーム + AI解説 |
| **継続性** | なし | デイリーチャレンジ + ストリーク |
| **進捗管理** | 基本的 | 詳細な統計・グラフ |
| **ソーシャル** | ランキングのみ | フレンド機能・チャレンジ |
| **オフライン** | あり（有料） | 無料オフライン対応 |
| **価格戦略** | 有料/IAP | **フリーミアム戦略** |

---

## 5️⃣ 実装ロードマップ（推奨）

### Phase 1: MVP拡張（Week 1-2）
```
✓ デイリーチャレンジ実装
✓ 基本的なゲーミフィケーション
✓ 学習進捗ダッシュボード
```

### Phase 2: ソーシャル統合（Week 3-4）
```
✓ ユーザープロフィール
✓ ランキング機能
✓ 成績シェア機能
```

### Phase 3: AI & 高度機能（Week 5-8）
```
✓ 間違い問題の AI 解説
✓ オフライン対応
✓ 模擬試験機能
```

---

## 6️⃣ 実装コード例

### A. デイリーチャレンジスケルトン

```dart
// lib/features/daily_challenge/daily_challenge.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dailyChallengeProvider = StateNotifierProvider<
  DailyChallengeNotifier,
  DailyChallengeState
>((ref) => DailyChallengeNotifier());

class DailyChallenge {
  final String id;
  final List<Question> questions;  // 10問
  final DateTime resetTime;        // 翌日0:00
  final int bonusCoins;            // 10 coins
  
  bool get isExpired => DateTime.now().isAfter(resetTime);
  bool get isCompleted => questions.every((q) => q.answered);
}

class DailyChallengeNotifier extends StateNotifier<DailyChallengeState> {
  DailyChallengeNotifier() : super(const DailyChallengeState.initial());
  
  Future<void> loadToday() async {
    // Firestore から今日のチャレンジ取得
    // なければ自動生成
  }
  
  Future<void> submitAnswer(String questionId, String answer) async {
    // 回答を記録
    // 正解時: coins + experience 獲得
  }
}
```

### B. 進捗ダッシュボード UI

```dart
// lib/screens/progress_dashboard.dart
class ProgressDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(userStatsProvider);
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. 今週の正解率
          LineChart(weeklyAccuracyData),
          
          // 2. 分野別進捗
          BarChart(categoryProgressData),
          
          // 3. ストリーク表示
          StreakCard(
            currentStreak: stats.streak,
            recordStreak: stats.recordStreak,
          ),
          
          // 4. レベル・経験値
          ExpProgressIndicator(
            currentExp: stats.experience,
            nextLevelExp: stats.nextLevelThreshold,
          ),
        ],
      ),
    );
  }
}
```

### C. Gamification Model

```dart
// lib/models/rewards.dart
enum RewardType {
  correctAnswer,      // +10 exp
  streakBonus,        // +50 exp (連続5日)
  dailyChallenge,     // +100 coins
  milestone,          // レベルアップ時
}

class Reward {
  final RewardType type;
  final int amount;
  final String message;
  
  factory Reward.forCorrectAnswer() => Reward(
    type: RewardType.correctAnswer,
    amount: 10,
    message: '✨ +10 EXP',
  );
}
```

---

## 7️⃣ マーケティング戦略

### App Store Listing 最適化

**キーワード戦略:**
```
- 漢字検定アプリ
- 漢字学習ゲーム
- 日本語学習
- 受験対策
- 試験勉強アプリ
```

**スクリーンショット改善:**
```
1. ゲーム感覚で漢字学習
2. 毎日のチャレンジで継続
3. 成績管理で進捗確認
4. ランキングで競争
5. 合格を目指そう
```

**マーケティング施策:**
- 受験シーズン（9月-1月）に App Store Featured
- 教育系インフルエンサー連携
- Twitter/TikTok キャンペーン
- YouTube チュートリアル動画

---

## 📊 成功指標（KPI）

| 指標 | 目標 | 計測方法 |
|------|------|---------|
| DAU (日次ユーザー) | 100 → 500 | Firebase Analytics |
| Retention (7日) | 30% → 50% | Analytics Cohort |
| ARPU (平均課金) | $0.5 → $2.0 | App Store / Stripe |
| App Rating | 4.0 → 4.5+ | App Store Review |
| Conversion to Paid | 5% → 15% | In-App Purchase |

---

## 💡 最終推奨アクション

### 今週（Week 1）
- [ ] P1 機能の技術仕様書作成
- [ ] デザイン・UI/UX プロトタイプ
- [ ] データモデル設計（Firestore スキーマ）

### 来週（Week 2）
- [ ] デイリーチャレンジ実装開始
- [ ] ゲーミフィケーション基盤構築
- [ ] テスト・デバッグ

### Week 3-4
- [ ] ダッシュボード UI 完成
- [ ] Beta テスト実施
- [ ] Google Play リリース準備

---

**作成日:** 2026-09-11  
**次回レビュー:** リリース 1週間後
