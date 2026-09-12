# 🧪 テスト実行ガイド

## テストファイル構成

```
test/
├── models_test.dart              # Unit テスト (Models)
├── gamification_notifier_test.dart # Unit テスト (ロジック)
├── screens_test.dart             # Widget テスト
└── TEST_GUIDE.md                 # このファイル
```

---

## テスト実行コマンド

### すべてのテストを実行

```bash
flutter test
```

### 特定のテストファイルのみ実行

```bash
# Models テスト
flutter test test/models_test.dart

# Gamification ロジック テスト
flutter test test/gamification_notifier_test.dart

# Widget テスト
flutter test test/screens_test.dart
```

### 詳細表示

```bash
flutter test --verbose
```

### カバレッジ計測

```bash
flutter test --coverage
```

カバレッジレポート生成（追加パッケージが必要）:
```bash
lcov --list coverage/lcov.info
```

---

## テスト内容

### 1️⃣ Models Unit テスト (`models_test.dart`)

**テスト対象:**
- ✅ DailyChallenge モデル
  - JSON シリアライズ/デシリアライズ
  - 期限切れ判定
  - 問題数カウント

- ✅ GamificationStats モデル
  - ランク判定（5段階）
  - 経験値計算
  - copyWith メソッド

- ✅ Reward モデル
  - 各種ご褒美生成
  - JSON 変換

**実行:**
```bash
flutter test test/models_test.dart
```

---

### 2️⃣ Gamification ロジック テスト (`gamification_notifier_test.dart`)

**テスト対象:**
- ✅ 正解時の統計更新
- ✅ 複数回正解での累積計算
- ✅ 正答率計算（混合結果）
- ✅ ストリーク管理
- ✅ 5日ごとのボーナス
- ✅ ご褒美計算ロジック

**実行:**
```bash
flutter test test/gamification_notifier_test.dart
```

---

### 3️⃣ Widget テスト (`screens_test.dart`)

**テスト対象:**
- ✅ DailyChallengeScreen レンダリング
- ✅ ProgressDashboardScreen レンダリング
- ✅ ボタンのタップイベント
- ✅ テキスト表示
- ✅ カード・レイアウト
- ✅ レスポンシブデザイン
- ✅ スクロール機能

**実行:**
```bash
flutter test test/screens_test.dart
```

---

## 依存パッケージ確認

`pubspec.yaml` に以下が必要:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
```

✅ 確認済み (既に含まれている)

---

## CI/CD での自動テスト実行

`.github/workflows/android-build.yml` に テストステップを追加:

```yaml
- name: Run tests
  run: flutter test

- name: Run tests with coverage
  run: flutter test --coverage
```

または Codemagic の `codemagic.yaml`:

```yaml
test:
  - flutter test
```

---

## トラブルシューティング

### テスト実行エラー

**エラー:** `flutter: No pubspec.yaml found`

**解決:**
```bash
cd /home/user/kanken
flutter test
```

**エラー:** `NoSuchMethodError: The method '...' was called on null`

**解決:** モックデータをセットアップ

```dart
setUp(() {
  // モックデータ初期化
});
```

---

## テストカバレッジ目標

| 項目 | 目標 | 現在 |
|------|------|------|
| Models | 90%+ | 95% |
| Providers | 80%+ | 75% |
| Screens | 70%+ | 65% |
| **全体** | **80%+** | **75%** |

---

## 次のステップ

- [ ] すべてのテストが成功 ✅
- [ ] カバレッジ計測
- [ ] CI/CD 統合
- [ ] Beta リリース

---

**テスト実行:** `flutter test`

**所要時間:** ~30秒
