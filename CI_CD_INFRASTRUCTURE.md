# CI/CD インフラストラクチャガイド

## 概要

kanken プロジェクトの CI/CD パイプラインは GitHub Actions で実装されています。このドキュメントは、パイプラインの構成、セットアップ、トラブルシューティングについて説明します。

## アーキテクチャ

### GitHub Actions ワークフロー

```
┌─────────────────────────────────────────────────┐
│         GitHub Actions Workflows                │
└─────────────────────────────────────────────────┘
         ↓                    ↓
    ┌──────────┐         ┌─────────────┐
    │  build   │         │  firebase   │
    │  .yml    │         │  -import    │
    │          │         │  .yml       │
    └──────────┘         └─────────────┘
         ↓                    ↓
  ┌─────────────────┐  ┌──────────────┐
  │ Test Pipeline   │  │ Data Import  │
  │ - Setup Flutter │  │ Pipeline     │
  │ - Setup Firebase│  │ - Firebase   │
  │ - Run Tests     │  │ - Firestore  │
  │ - Gen Reports   │  │ - Security   │
  └─────────────────┘  └──────────────┘
```

### ワークフローファイル

| ファイル | 用途 | トリガー |
|---------|------|--------|
| `.github/workflows/build.yml` | テスト & ビルド | `push` to `main`/`develop`<br/>`pull_request` on `main`/`develop` |
| `.github/workflows/firebase-import.yml` | Firebase データ import | `workflow_dispatch`<br/>`push` to `main` (export_data/)<br/>`release` published |

## ワークフロー詳細

### 1. build.yml (テスト & ビルド)

**目的:** Dart/Flutter コードの品質保証とテスト実行

**実行環境:** Ubuntu 22.04 (ubuntu-latest)

**タイムアウト:** 30 分

#### パイプラインステップ

```
1. Checkout code
   └─ git リポジトリのチェックアウト

2. Setup Flutter
   └─ Flutter SDK 3.13.0 をセットアップ

3. Setup Firebase configuration ⭐ NEW
   └─ firebase_options.dart を自動生成
   └─ google-services.json を解析
   └─ プロジェクト設定を反映

4. Get dependencies
   └─ flutter pub get
   └─ Dart パッケージを解決

5. Run unit tests
   └─ flutter test --verbose
   └─ パイプフェイルで exit code を伝播
   └─ テスト出力を test-output.log に保存

6. Extract and display failed tests (on failure)
   └─ テスト失敗情報を表示
   └─ ログから失敗パターンを抽出

7. Upload test output log
   └─ test-output.log をアーティファクトアップロード
   └─ actions/upload-artifact@v4

8. Run integration tests (on success)
   └─ flutter test integration_test
   └─ 失敗しても続行 (|| true)
```

#### 環境変数

```
Flutter Version: 3.13.0
Channel: stable
Dart SDK: >=3.0.0 <4.0.0
Platform: ubuntu-22.04
```

#### 失敗時の処理

- テスト失敗時は exit code が非ゼロ
- `set -o pipefail` で tee が隠さない
- CI 再実行画面で詳細ログを確認可能
- アーティファクト: `test-output.log` をダウンロード

### 2. firebase-import.yml (データ import)

**目的:** Firestore データベースへの定期的なデータ import

**実行環境:** Ubuntu latest

**トリガー:**
- 手動 (workflow_dispatch)
- main ブランチへのプッシュ（export_data/ の変更時）
- Release publish イベント

#### パイプラインステップ

```
1. Checkout code
2. Setup Node.js 22
3. Install Firebase CLI
4. Setup Firebase credentials (from GitHub Secrets)
5. Import kanji questions data
6. Verify import
7. Cleanup (always)
```

#### 必要な GitHub Secrets

```
FIREBASE_SERVICE_ACCOUNT   Firebase サービスアカウント JSON
FIREBASE_PROJECT_ID         Firebase プロジェクト ID
```

## セットアップ手順

### ステップ 1: リポジトリ設定

```bash
# リポジトリをクローン
git clone https://github.com/zka32101/kanken.git
cd kanken
```

### ステップ 2: Firebase 設定

```bash
# google-services.json を配置
# (既に android/app/google-services.json に存在)

# firebase_options.dart を生成
bash scripts/generate-firebase-options.sh
```

### ステップ 3: GitHub Secrets 設定（本番環境）

本番環境でのデータ import が必要な場合：

1. GitHub リポジトリ → Settings → Secrets
2. 以下を追加：

```
Name: FIREBASE_SERVICE_ACCOUNT
Value: (Firebase Console から service-account-key.json をコピー)

Name: FIREBASE_PROJECT_ID
Value: kanken-dev (プロジェクト ID)
```

### ステップ 4: テスト実行

```bash
# ローカルテスト
flutter test

# CI テスト確認
git push origin main  # build.yml が自動実行
```

## 環境変数とシークレット

### GitHub Secrets

| Secret | 用途 | 例 |
|--------|------|-----|
| `FIREBASE_SERVICE_ACCOUNT` | Firebase CLI 認証 | `{ "type": "service_account", ... }` |
| `FIREBASE_PROJECT_ID` | Firebase プロジェクト ID | `kanken-dev` |

### ワークフロー内の環境変数

```yaml
env:
  FLUTTER_VERSION: '3.13.0'
  FLUTTER_CHANNEL: 'stable'
```

## トラブルシューティング

### 問題 1: "flutter test" でテストが失敗

**確認項目:**

```bash
# ローカルで再現
flutter pub get
flutter test --verbose

# ログを確認
git log --oneline -5
```

**一般的な原因:**

1. Dart パッケージの依存関係エラー
   ```bash
   flutter pub get
   flutter pub upgrade
   ```

2. テスト期待値のミスマッチ
   ```bash
   # テストファイルを確認
   cat test/models_test.dart
   ```

3. プラットフォーム固有の問題
   ```bash
   flutter doctor -v
   ```

### 問題 2: "Firebase configuration" ステップが失敗

**確認:**

```bash
# google-services.json が存在するか
ls -la android/app/google-services.json

# jq がインストールされているか
jq --version

# JSON が有効か
jq . android/app/google-services.json
```

**解決:**

```bash
# スクリプトを実行
bash scripts/generate-firebase-options.sh

# ファイルを確認
cat lib/firebase_options.dart
```

### 問題 3: "Upload test output" が失敗

**原因:** 古い upload-artifact アクション（v3）を使用

**解決:** `.github/workflows/build.yml` を確認

```yaml
- uses: actions/upload-artifact@v4  # ✅ v4 を使用
  with:
    name: test-output-log
    path: test-output.log
```

### 問題 4: テストログが途中で切れている

**原因:** GitHub Actions のログ出力制限（リアルタイム 5000 行）

**解決:** アーティファクトで完全なログを取得

```bash
# Actions タブ → 実行 → Artifacts をダウンロード
# test-output.log に全テスト結果が含まれます
```

## パフォーマンス最適化

### 1. 依存関係のキャッシュ

```yaml
- name: Cache Flutter dependencies
  uses: actions/cache@v3
  with:
    path: ~/.pub-cache
    key: ${{ runner.os }}-flutter-${{ hashFiles('**/pubspec.yaml') }}
```

### 2. 並列テスト実行

```bash
flutter test --concurrency=4  # 4 つのテストを並列実行
```

### 3. ビルドキャッシュ

```yaml
- name: Cache Gradle build
  uses: actions/cache@v3
  with:
    path: android/.gradle
    key: ${{ runner.os }}-gradle-${{ hashFiles('android/build.gradle') }}
```

## 本番環境への展開

### Release フロー

```
1. git tag v1.0.0-beta.1
2. git push origin v1.0.0-beta.1
3. GitHub Release を作成
4. firebase-import.yml が自動トリガー
5. Firestore データが import される
```

### セキュリティチェック

```bash
# リリース前チェック
bash scripts/pre-release-check.sh
```

## モニタリング

### ワークフロー実行状況

```
GitHub リポジトリ → Actions タブ
```

各ワークフロー実行は以下の情報を表示：

- ✅ 成功 (緑)
- ❌ 失敗 (赤)
- ⏸️ キャンセル (グレー)

### ログの確認

```
Actions → ワークフロー → 実行 → ジョブ → ステップ
```

### アーティファクトのダウンロード

```
Actions → 実行 → Artifacts → test-output-log.zip
```

## ベストプラクティス

### 1. コミットメッセージ

```
機能: 詳細な説明

[skip ci]  # CI をスキップする場合
```

### 2. ブランチ戦略

```
main ブランチ
├─ develop ブランチ（開発用）
└─ feature/XXX ブランチ（機能開発）
```

### 3. PR チェック

```
PR 作成時に自動で build.yml が実行
全テストが成功してから merge
```

## 参考リンク

- [GitHub Actions ドキュメント](https://docs.github.com/ja/actions)
- [Flutter CI/CD ガイド](https://docs.flutter.dev/deployment/cd)
- [Firebase CLI ドキュメント](https://firebase.google.com/docs/cli)
- [GitHub Actions ベストプラクティス](https://docs.github.com/ja/actions/guides)

## 更新履歴

### 2026-09-15

- CI/CD インフラドキュメントを作成
- Firebase Options ジェネレータを統合
- build.yml に Firebase setup ステップを追加
- 詳細なトラブルシューティングガイドを追加
