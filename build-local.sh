#!/bin/bash

set -e

echo "🔧 kanken - ローカルビルドスクリプト"
echo "=================================="
echo ""

# 1. 環境確認
echo "✓ 環境確認中..."
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter がインストールされていません"
    exit 1
fi

if ! command -v java &> /dev/null; then
    echo "❌ Java がインストールされていません"
    exit 1
fi

FLUTTER_VER=$(flutter --version | head -1)
JAVA_VER=$(java -version 2>&1 | head -1)
DART_VER=$(dart --version 2>&1)

echo "  Flutter: $FLUTTER_VER"
echo "  Java: $JAVA_VER"
echo "  Dart: $DART_VER"
echo ""

# 2. 依存関係取得
echo "✓ 依存関係取得中..."
flutter pub get
echo ""

# 3. Dart分析
echo "✓ Dart分析実行中..."
dart analyze --fatal-infos || echo "⚠️  警告あり"
echo ""

# 4. APK ビルド (Debug)
echo "✓ APK ビルド中 (Debug)..."
flutter build apk --debug --target-platform android-arm64
APK_PATH="build/app/outputs/apk/debug/app-debug.apk"

if [ -f "$APK_PATH" ]; then
    SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo "✅ APK ビルド成功"
    echo "   パス: $APK_PATH"
    echo "   サイズ: $SIZE"
else
    echo "❌ APK ビルド失敗"
    exit 1
fi
echo ""

# 5. App Bundle ビルド (Release)
echo "✓ App Bundle ビルド中 (Release)..."
flutter build appbundle --release
AAB_PATH="build/app/outputs/bundle/release/app-release.aab"

if [ -f "$AAB_PATH" ]; then
    SIZE=$(du -h "$AAB_PATH" | cut -f1)
    echo "✅ App Bundle ビルド成功"
    echo "   パス: $AAB_PATH"
    echo "   サイズ: $SIZE"
else
    echo "⚠️  App Bundle ビルド失敗（署名キー未設定の可能性）"
fi
echo ""

echo "🎉 ビルド完了！"
