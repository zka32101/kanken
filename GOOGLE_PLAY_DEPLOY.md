# 📱 Google Play Console デプロイガイド

## 1️⃣ 署名キーの生成（初回のみ）

### 1.1 キーストア生成
```bash
keytool -genkey -v -keystore android/app/key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias kanken_key -storepass PASSWORD -keypass PASSWORD
```

**入力内容例：**
```
姓名: Kanken Developer
組織単位: Development
組織: Example Inc
場所: Tokyo
都道府県: Tokyo
国コード: JP
```

### 1.2 署名設定（android/app/build.gradle）
```gradle
// 既存の設定を確認
signingConfigs {
    release {
        keyAlias 'kanken_key'
        keyPassword 'PASSWORD'
        storeFile file('key.jks')
        storePassword 'PASSWORD'
    }
}
```

---

## 2️⃣ App Bundle (AAB) ビルド

```bash
flutter build appbundle --release
```

**成功時の出力：**
```
build/app/outputs/bundle/release/app-release.aab
```

---

## 3️⃣ Google Play Console 登録

### 3.1 Developer Account 作成
- https://play.google.com/console
- $25 登録料（1回限り）
- Google アカウントで登録

### 3.2 アプリ登録

1. **「アプリを作成」→「新しいアプリ」**
   - アプリ名: 漢検チャレンジ
   - デフォルト言語: 日本語
   - アプリまたはゲーム: アプリ

2. **ストア掲載情報 タブ**
   - 説明・スクリーンショット・プレビュー画像を設定
   - コンテンツレーティングアンケート記入
   - ターゲット地域・年齢設定

3. **アプリのコンテンツ タブ**
   - 対象年齢
   - コンテンツレーティング
   - 広告設定（Firebase Analytics が有効）

---

## 4️⃣ リリース手順

### 4.1 内部テスト リリース（推奨・最初）

1. **アプリのリリース → 内部テスト**
2. **新しいリリースを作成**
   - app-release.aab をアップロード
   - リリースノート記入: 日本語で機能説明

3. **保存して内部テストに公開**

### 4.2 ユーザー テスト（β版）

1. **アプリのリリース → ユーザーテスト**
2. **新しいリリースを作成**
   - テスター追加: メールアドレスリスト
   - リリースノート記入

3. **テスター数: 推奨 5-50 人**
   - 社内テーム・友人に配信可

### 4.3 本番公開

1. **アプリのリリース → 本番**
2. **新しいリリースを作成**
   - app-release.aab をアップロード
   - ストア掲載情報 が完成していることを確認
   - リリースノート記入

3. **公開を開始**

---

## 5️⃣ 完了チェックリスト

- [ ] キーストア作成・署名キー保存
- [ ] Developer Account 登録（$25支払い）
- [ ] ストア掲載情報完成
  - [ ] アプリ説明・機能説明
  - [ ] スクリーンショット（5枚以上推奨）
  - [ ] プレビュー画像・アイコン
- [ ] コンテンツレーティング設定
- [ ] プライバシーポリシー URL 記載
  - 例: https://example.com/privacy
- [ ] 内部テスト リリース成功確認
- [ ] ユーザーテスト（β版）実施 - **最低 14 日間**
- [ ] 本番公開リリース

---

## 6️⃣ リリース後の監視

### 6.1 Google Play Console ダッシュボード確認

- **統計 タブ**
  - ダウンロード数
  - アクティブインストール数
  - クラッシュ率

- **Android vitals**
  - Stability（クラッシュ率）
  - Battery（電池消費）
  - Render time（描画速度）
  - **目標: 99% 以上の Stability**

### 6.2 Firebase Analytics 連携

- Firebase Console で
  - ユーザー数・セッション数
  - ユーザー行動フロー
  - カスタムイベント

### 6.3 バージョン更新

**次のバージョン公開時：**
```bash
# pubspec.yaml で version を更新
# 例: 1.0.0+1 → 1.0.1+2

flutter build appbundle --release
# → Google Play Console で新規リリース
```

---

## 7️⃣ トラブルシューティング

### アップロード失敗エラー

| エラー | 原因 | 解決策 |
|--------|------|--------|
| `Gradle build failed` | ビルドエラー | `flutter build appbundle --release` をローカルで確認 |
| `64-bit required` | 32bit APK | `android-arm64` で必ずビルド |
| `Signature invalid` | 署名キー不正 | `key.properties` の内容確認 |
| `Min SDK too low` | minSdkVersion 不足 | 最小 Android 5.0 (API 21) |

### バージョン管理

- **Version Code** (ビルド番号): 毎回 +1
- **Version Name** (表示版): semantic versioning (1.0.0)

**例：**
```yaml
version: 1.0.0+1  # Version Name: 1.0.0, Version Code: 1
version: 1.0.1+2  # Version Name: 1.0.1, Version Code: 2
version: 1.1.0+3  # Version Name: 1.1.0, Version Code: 3
```

---

## 参考リンク

- [Google Play Console ヘルプ](https://support.google.com/googleplay/android-developer)
- [App Bundle 形式](https://developer.android.com/guide/app-bundle)
- [ストア掲載情報ガイドライン](https://play.google.com/about/storelisting-ads/rules/)
