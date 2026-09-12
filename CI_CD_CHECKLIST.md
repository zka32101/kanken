# 🔄 CI/CD パイプライン チェックリスト

## Codemagic 自動パイプライン

### ✅ 実装完了

- [x] **依存パッケージ取得**
  - コマンド: `flutter pub get`
  - 目的: Dart/Flutter パッケージの依存関係解決

- [x] **静的解析**
  - コマンド: `dart analyze`
  - 目的: コード品質チェック・エラー検出

- [x] **ユニットテスト実行**
  - コマンド: `flutter test --coverage`
  - テスト数: 78+ テスト
  - 対象ファイル:
    - test/models_test.dart
    - test/gamification_notifier_test.dart
    - test/ranking_test.dart
    - test/friend_test.dart
  - カバレッジ計測: 有効

- [x] **カバレッジレポート送信**
  - サービス: Codecov
  - フォーマット: lcov.info
  - 自動アップロード: 有効

- [x] **APK ビルド (Debug)**
  - コマンド: `flutter build apk --debug`
  - ターゲット: android-arm64
  - アーティファクト: build/app/outputs/apk/debug/app-debug.apk

- [x] **App Bundle ビルド (Release)**
  - コマンド: `flutter build appbundle --release`
  - アーティファクト: build/app/outputs/bundle/release/app-release.aab

### 📊 パイプライン トリガー

```yaml
triggering:
  events:
    - push          # コミット時
    - pull_request  # PR 作成時
  branch:
    include_patterns:
      - main
      - master
      - develop
```

### 📧 通知設定

- 成功時: メール通知
- 失敗時: メール通知 (即座)
- 受信者: $TEAM_EMAIL

---

## テスト実行要件

### ローカル環境

**前提条件:**
```
✓ Flutter 3.x 以上
✓ Dart 3.x 以上
✓ Java 11
✓ Android SDK 34 以上
```

**環境変数:**
```bash
FIREBASE_EMULATOR_HOST=localhost:5001  # (オプション)
CODECOV_TOKEN=<token>                  # Codecov 統合用
```

### テスト実行コマンド

```bash
# すべてのテスト実行
flutter test

# カバレッジ計測
flutter test --coverage

# 特定テスト実行
flutter test test/models_test.dart

# 詳細表示
flutter test --verbose
```

### 期待される結果

```
✓ すべてのテストが PASS
✓ カバレッジ > 75%
✓ dart analyze で警告なし
✓ APK/AAB ビルド成功
```

---

## デプロイメント フロー

### 1️⃣ ローカル検証 (開発者)

```bash
# テスト実行
flutter test

# ビルドチェック
flutter build apk --debug

# Commit & Push
git commit -m "..."
git push -u origin <branch>
```

### 2️⃣ Codemagic 自動検証

```
1. コード取得 & 依存関係解決
2. 静的解析実行
3. 78+ テスト実行 (カバレッジ計測)
4. APK/AAB ビルド
5. アーティファクト保存
6. 結果通知
```

### 3️⃣ PR レビュー

```
✓ すべてのテスト PASS
✓ ビルド成功
✓ カバレッジ > 75%
→ マージ可能
```

### 4️⃣ main ブランチ マージ

```
自動で以下を実行:
- Release APK/AAB 生成
- Google Play Internal Testing 準備
- テストレポート生成
```

---

## テストカバレッジ監視

### Codecov 統合

**設定:**
```yaml
# .codecov.yml
codecov:
  require:
    - v: 75  # 75% カバレッジ必須
```

**データ:**
- リアルタイム カバレッジ追跡
- Pull Request コメント (自動)
- 変更箇所のカバレッジ分析

### カバレッジ改善ターゲット

| セクション | 現在 | 目標 |
|----------|------|------|
| Models | 95% | 95%+ |
| Providers | 75% | 80%+ |
| Screens | 65% | 70%+ |
| **全体** | 78% | **80%+** |

---

## 障害時の対応

### テスト失敗

```
1. ローカルで再現
2. デバッグ実行 (--verbose)
3. 修正コミット
4. Push で再トリガー
```

### ビルド失敗

```
1. ビルドログ確認
2. 依存パッケージ更新: flutter pub upgrade
3. クリーンビルド: flutter clean
4. 再度 Push
```

### カバレッジ低下

```
1. テスト追加が必要な箇所を特定
2. 新しいテストケース作成
3. カバレッジ 75% 以上確認
4. Commit & Push
```

---

## Beta リリース準備

### チェックリスト

- [ ] すべてのテスト PASS
- [ ] カバレッジ > 75%
- [ ] 静的解析 警告なし
- [ ] APK/AAB ビルド成功
- [ ] Firebase セットアップ確認
- [ ] Analytics イベント検証
- [ ] クラッシュレポート設定確認

### リリース手順

```bash
# 1. Version 更新
# pubspec.yaml: version: 1.0.0+1

# 2. Changelog 更新
# CHANGELOG.md に変更内容記載

# 3. タグ作成
git tag -a v1.0.0 -m "Beta Release v1.0.0"
git push origin v1.0.0

# 4. Release AAB を Codemagic で取得
# Google Play Console にアップロード
```

---

## モニタリング

### Codemagic ダッシュボード

- ビルド履歴確認
- 成功/失敗の分析
- 実行時間の監視

### Firebase Console

- Crashlytics: クラッシュレポート
- Analytics: イベント追跡
- Performance: アプリパフォーマンス

### Codecov

- カバレッジ推移
- 変更箇所の分析
- トレンド監視

---

**最終更新:** 2026-09-12

**ステータス:** ✅ 実装完了・本番対応可能
