# 🏗️ kanken ビルドガイド

## ローカルビルド（開発環境）

### 前提条件
- Flutter 3.10.0 以上
- Java 11 以上
- Android SDK 34

### ビルド実行

```bash
./build-local.sh
```

**実行内容：**
- ✓ Flutter/Java/Dart環境確認
- ✓ Pub依存関係取得
- ✓ Dart分析（lint）
- ✓ APK ビルド（Debug）
- ✓ App Bundle ビルド（Release）

**成功時の出力ファイル：**
- `build/app/outputs/apk/debug/app-debug.apk` → 開発用APK
- `build/app/outputs/bundle/release/app-release.aab` → Google Play Deploy用

---

## CI/CD パイプライン

### 🟢 Codemagic（推奨・本番環境）

**自動トリガー：**
- main/master/develop ブランチへのpush
- Pull Request作成

**セットアップ：**
1. https://codemagic.io で登録（GitHub連携）
2. リポジトリ接続 → `zka32101/kanken`
3. `codemagic.yaml` 自動検出
4. 環境変数設定（必要に応じて）

**ビルド成果物：**
- Debug APK
- Release App Bundle
- ビルドログ

---

## トラブルシューティング

### Flutterが見つからない
```bash
flutter pub get
```

### 依存関係エラー
```bash
flutter pub get
flutter clean
rm -rf .dart_tool
flutter pub get
```

### Gradleエラー
```bash
cd android && ./gradlew clean && cd ..
flutter build apk --debug
```

### Firebase設定エラー
- `android/app/google-services.json` を確認
- Firebase Console から再ダウンロード

---

## ビルド出力確認

```bash
# APK署名確認
jarsigner -verify -verbose build/app/outputs/apk/debug/app-debug.apk

# App Bundle情報確認
bundletool dump manifest --bundle=build/app/outputs/bundle/release/app-release.aab
```

---

## 64bit APK要件（Google Play）

Google Play では 64bit APKが必須です。

```bash
# 64bit ARMv8 で自動ビルド
flutter build apk --debug --target-platform android-arm64
```

---

## 次のステップ

- [x] ローカルビルド検証
- [ ] Codemagic セットアップ（https://codemagic.io）
- [ ] Google Play Console 登録・デプロイ
- [ ] 内部テスト（β版）リリース
