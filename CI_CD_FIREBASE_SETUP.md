# CI/CD Firebase セットアップガイド

## 概要

このドキュメントは、kanken の CI/CD パイプラインと Firebase の依存関係解決について説明します。

## 問題: Firebase 設定の不整合

### 原因

**firebase_options.dart** と **google-services.json** が同期されていませんでした。

```dart
// 問題: firebase_options.dart のプレースホルダー値
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',        // ❌ プレースホルダー
  appId: 'YOUR_ANDROID_APP_ID',          // ❌ プレースホルダー
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',  // ❌ プレースホルダー
  projectId: 'kanken-project',           // ❌ 古い値
  // ...
);
```

一方、**google-services.json** には実際の値がありました：

```json
{
  "project_info": {
    "project_id": "kanken-dev",
    "project_number": "123456789012",
    "firebase_url": "https://kanken-dev.firebaseio.com",
    "storage_bucket": "kanken-dev.appspot.com"
  },
  "client": [{
    "client_info": {
      "mobilesdk_app_id": "1:123456789012:android:abcdef1234567890abcd"
    },
    "api_key": [{
      "current_key": "AIzaSyAbcDefGhIjKlMnOpQrStUvWxYz1234567"
    }]
  }]
}
```

### 解決策

自動生成スクリプトを実装して、**google-services.json** から **firebase_options.dart** を生成します。

## 実装

### 1. Firebase Options ジェネレータ

#### Bash スクリプト (推奨)

```bash
bash scripts/generate-firebase-options.sh
```

このスクリプトは：
- `google-services.json` を解析
- Firebase プロジェクト情報を抽出
- `lib/firebase_options.dart` を自動生成
- iOS/macOS/Web のプレースホルダー値は保持（別途設定が必要）

#### Node.js スクリプト (代替)

```bash
node scripts/generate-firebase-options.js
```

### 2. CI/CD パイプラインの統合

`.github/workflows/build.yml` に以下のステップを追加：

```yaml
- name: Setup Firebase configuration
  run: |
    echo "Generating firebase_options.dart from google-services.json..."
    bash scripts/generate-firebase-options.sh
```

このステップは `flutter pub get` の前に実行されます。

### 3. ワークフロー実行順序

```
1. Checkout code
2. Setup Flutter
3. Setup Firebase configuration  ← ⭐ NEW
4. Get dependencies
5. Run unit tests
6. Extract and display failed tests (if failed)
7. Upload test output log
8. Run integration tests
```

## GitHub Secrets 設定

Firebase 関連の secrets は現在不要ですが（google-services.json は既にリポジトリに含まれている）、本番環境では以下を設定してください：

### 必須 (本番環境)

```
FIREBASE_PROJECT_ID          Firebase プロジェクト ID
FIREBASE_SERVICE_ACCOUNT     Firebase サービスアカウント JSON
```

### オプション

```
FIREBASE_EMULATOR_HOST       Emulator ホスト (開発時のみ)
FIREBASE_EMULATOR_PORT       Emulator ポート (開発時のみ)
```

設定手順:
1. GitHub リポジトリ → Settings → Secrets and variables → Actions
2. "New repository secret" をクリック
3. Name と Value を入力
4. "Add secret" をクリック

## ローカル開発

### セットアップ

```bash
# 1. 依存関係をインストール
flutter pub get

# 2. Firebase Options を生成
bash scripts/generate-firebase-options.sh

# 3. テストを実行
flutter test

# 4. アプリを実行
flutter run
```

### firebase_options.dart の更新

google-services.json を更新した場合：

```bash
bash scripts/generate-firebase-options.sh
```

## トラブルシューティング

### 問題: "jq コマンドが見つからない"

**解決策:**

```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq

# Windows (git bash)
# msys2/mingw64-i686-jq をインストール
```

### 問題: "Permission denied" (generate-firebase-options.sh)

**解決策:**

```bash
chmod +x scripts/generate-firebase-options.sh
```

### 問題: firebase_options.dart が生成されない

**確認:**

1. `android/app/google-services.json` が存在するか
2. JSON ファイルが有効か：`jq . android/app/google-services.json`
3. スクリプトが実行可能か：`ls -la scripts/generate-firebase-options.sh`

### 問題: "YOUR_IOS_API_KEY" が残っている

**説明:** iOS/macOS/Web のプレースホルダーはスクリプトが生成できません。

**解決策:**

1. Firebase Console → プロジェクト設定
2. 各プラットフォームの API キーを取得
3. `lib/firebase_options.dart` を手動で更新

```dart
static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'AIzaSy...',  // Firebase Console から取得
  appId: '1:...:ios:...',
  // ...
);
```

## ファイル一覧

| ファイル | 用途 |
|---------|------|
| `scripts/generate-firebase-options.sh` | Bash スクリプト (推奨) |
| `scripts/generate-firebase-options.js` | Node.js スクリプト (代替) |
| `lib/firebase_options.dart` | 生成されるファイル |
| `android/app/google-services.json` | ソース (Android) |
| `.github/workflows/build.yml` | CI/CD ワークフロー |

## セキュリティ考慮

### ✅ 安全

- `google-services.json` はリポジトリに含まれている（開発用）
- API キーは Android の方針により無効化可能
- スクリプトは `.git` を無視（git 履歴は影響しない）

### ⚠️ 本番環境での推奨

1. **google-services.json を .gitignore に追加**
   ```bash
   echo "android/app/google-services.json" >> .gitignore
   ```

2. **GitHub Secrets で本番用 google-services.json を保管**
   ```bash
   # CI/CD で復元
   echo "${{ secrets.FIREBASE_SERVICE_ACCOUNT }}" > android/app/google-services.json
   ```

3. **firebase_options.dart も同様に保護**
   ```bash
   echo "lib/firebase_options.dart" >> .gitignore
   ```

## 参考リンク

- [Firebase CLI ドキュメント](https://firebase.google.com/docs/cli)
- [FlutterFire 公式ドキュメント](https://firebase.flutter.dev/)
- [Google Services Gradle Plugin](https://developers.google.com/android/guides/google-services-plugin)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

## 更新履歴

### 2026-09-15

- Firebase Options ジェネレータを実装
- CI/CD パイプラインに統合
- 設定ドキュメントを作成
- google-services.json と firebase_options.dart の同期を実現
