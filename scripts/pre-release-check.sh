#!/bin/bash

##########################################################
# Pre-Release チェックスクリプト
#
# 用途: Beta リリース前の最終確認
# 使い方: bash scripts/pre-release-check.sh
##########################################################

set -e

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# カウンター
PASS=0
FAIL=0
WARN=0

# テスト結果を記録
test_result() {
    local name=$1
    local result=$2
    local detail=$3

    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $name"
        ((PASS++))
    elif [ "$result" = "FAIL" ]; then
        echo -e "${RED}✗${NC} $name"
        [ -n "$detail" ] && echo "  $detail"
        ((FAIL++))
    elif [ "$result" = "WARN" ]; then
        echo -e "${YELLOW}⚠${NC} $name"
        [ -n "$detail" ] && echo "  $detail"
        ((WARN++))
    fi
}

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🚀 Beta リリース前チェック${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# ============= Section 1: ファイル構成 =============
echo -e "${YELLOW}📂 Section 1: ファイル構成${NC}"
echo ""

# pubspec.yaml 確認
if [ -f "pubspec.yaml" ]; then
    VERSION=$(grep "^version:" pubspec.yaml | awk '{print $2}')
    test_result "pubspec.yaml" "PASS" "Version: $VERSION"
else
    test_result "pubspec.yaml" "FAIL"
fi

# google-services.json 確認
if [ -f "android/app/google-services.json" ]; then
    test_result "google-services.json" "PASS"
else
    test_result "google-services.json" "WARN" "手動で android/app/ に配置が必要"
fi

# codemagic.yaml 確認
if [ -f "codemagic.yaml" ]; then
    test_result "codemagic.yaml" "PASS"
else
    test_result "codemagic.yaml" "FAIL"
fi

# README 確認
if [ -f "README.md" ]; then
    test_result "README.md" "PASS"
else
    test_result "README.md" "WARN"
fi

echo ""

# ============= Section 2: コード品質 =============
echo -e "${YELLOW}🔍 Section 2: コード品質チェック${NC}"
echo ""

# Dart Analyzer
echo "dart analyze を実行中..."
if dart analyze --fatal-infos 2>/dev/null; then
    test_result "Dart Analyzer" "PASS"
else
    test_result "Dart Analyzer" "FAIL" "dart analyze --fatal-infos を実行してください"
fi

# Flutter Doctor
echo "flutter doctor を実行中..."
if flutter doctor -v 2>/dev/null | grep -q "Flutter"; then
    test_result "Flutter 環境" "PASS"
else
    test_result "Flutter 環境" "FAIL" "Flutter がインストールされていません"
fi

echo ""

# ============= Section 3: テスト =============
echo -e "${YELLOW}🧪 Section 3: テスト実行確認${NC}"
echo ""

# テストファイル確認
TEST_FILES=("test/models_test.dart" "test/gamification_notifier_test.dart" "test/ranking_test.dart" "test/friend_test.dart" "test/screens_test.dart")

for test_file in "${TEST_FILES[@]}"; do
    if [ -f "$test_file" ]; then
        test_result "$test_file" "PASS"
    else
        test_result "$test_file" "FAIL"
    fi
done

echo ""
echo "テスト実行: flutter test --coverage"
echo "実行してください (時間がかかる場合があります)"
echo ""

# ============= Section 4: セキュリティ =============
echo -e "${YELLOW}🔒 Section 4: セキュリティチェック${NC}"
echo ""

# git ignore 確認
if [ -f ".gitignore" ]; then
    if grep -q "google-services.json" .gitignore; then
        test_result "google-services.json gitignore" "PASS"
    else
        test_result "google-services.json gitignore" "WARN" ".gitignore に google-services.json を追加してください"
    fi

    if grep -q ".env" .gitignore; then
        test_result ".env gitignore" "PASS"
    else
        test_result ".env gitignore" "WARN" ".gitignore に .env を追加してください"
    fi
else
    test_result ".gitignore" "WARN"
fi

# API キー露出確認
if grep -r "firebase_key\|api_key\|secret" --include="*.dart" --include="*.json" . 2>/dev/null | grep -v "node_modules\|.git" | head -1 > /dev/null; then
    test_result "API キー" "WARN" "コード内にハードコードされたキーがないか確認"
else
    test_result "API キー" "PASS"
fi

echo ""

# ============= Section 5: ドキュメント =============
echo -e "${YELLOW}📚 Section 5: ドキュメント確認${NC}"
echo ""

DOC_FILES=(
    "BETA_RELEASE_GUIDE.md"
    "PRODUCTION_CHECKLIST.md"
    "IMPLEMENTATION_SUMMARY.md"
    "CI_CD_CHECKLIST.md"
    "TEST_GUIDE.md"
    "BUILD_GUIDE.md"
)

for doc_file in "${DOC_FILES[@]}"; do
    if [ -f "$doc_file" ]; then
        test_result "$doc_file" "PASS"
    else
        test_result "$doc_file" "WARN"
    fi
done

echo ""

# ============= Section 6: Firebase =============
echo -e "${YELLOW}🔥 Section 6: Firebase 設定確認${NC}"
echo ""

# Firebase CLI
if command -v firebase &> /dev/null; then
    test_result "Firebase CLI" "PASS"

    # プロジェクト確認
    if firebase projects:list 2>/dev/null | grep -q "PROJECT_ID"; then
        test_result "Firebase プロジェクト" "PASS"
    else
        test_result "Firebase プロジェクト" "WARN" "firebase use PROJECT_ID で設定"
    fi
else
    test_result "Firebase CLI" "WARN" "npm install -g firebase-tools"
fi

echo ""

# ============= Section 7: ビルド =============
echo -e "${YELLOW}🏗️  Section 7: ビルド前チェック${NC}"
echo ""

# Gradle wrapper
if [ -f "android/gradlew" ]; then
    test_result "Gradle Wrapper" "PASS"
else
    test_result "Gradle Wrapper" "FAIL"
fi

# build.gradle 確認
if [ -f "android/app/build.gradle" ]; then
    if grep -q "targetSdkVersion 34" android/app/build.gradle; then
        test_result "Target SDK Version" "PASS" "34 (最新)"
    else
        test_result "Target SDK Version" "WARN" "34 (Android 最新) を推奨"
    fi

    if grep -q "abiFilters.*arm64-v8a" android/app/build.gradle; then
        test_result "64-bit サポート" "PASS"
    else
        test_result "64-bit サポート" "WARN" "arm64-v8a を有効にしてください"
    fi
else
    test_result "build.gradle" "FAIL"
fi

echo ""

# ============= Section 8: Git =============
echo -e "${YELLOW}🔧 Section 8: Git 確認${NC}"
echo ""

# Git status
if [ -d ".git" ]; then
    test_result "Git リポジトリ" "PASS"

    if git status --short | grep -q "."; then
        test_result "作業ディレクトリ" "WARN" "変更されたファイルがあります"
        git status --short | head -5
    else
        test_result "作業ディレクトリ" "PASS" "クリーン"
    fi

    REMOTE_URL=$(git config --get remote.origin.url)
    test_result "Git Remote" "PASS" "$REMOTE_URL"
else
    test_result "Git リポジトリ" "FAIL"
fi

echo ""

# ============= Section 9: バージョン =============
echo -e "${YELLOW}📌 Section 9: バージョン確認${NC}"
echo ""

if [ -f "pubspec.yaml" ]; then
    VERSION=$(grep "^version:" pubspec.yaml | awk '{print $2}')
    BUILD=$(grep "^version:" pubspec.yaml | sed 's/.*+//')

    echo -e "  App Version: ${BLUE}${VERSION}${NC}"
    echo -e "  Build Number: ${BLUE}${BUILD}${NC}"
    echo ""

    if [[ "$VERSION" == *"beta"* ]]; then
        test_result "Beta バージョン" "PASS"
    else
        test_result "Beta バージョン" "WARN" "バージョンに 'beta' を含めることを推奨"
    fi
fi

echo ""

# ============= サマリー =============
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 チェック結果${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

TOTAL=$((PASS + FAIL + WARN))

echo -e "  ${GREEN}✓ PASS${NC}:  ${PASS}/${TOTAL}"
echo -e "  ${RED}✗ FAIL${NC}:  ${FAIL}/${TOTAL}"
echo -e "  ${YELLOW}⚠ WARN${NC}:  ${WARN}/${TOTAL}"

echo ""

# ============= GO/NO-GO 判定 =============
if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}✅ GO: Beta リリース準備 OK${NC}"
    echo ""
    echo "次のステップ:"
    echo "1. flutter test --coverage を実行"
    echo "2. Firebase セットアップを完了"
    echo "3. Google Play Console でストア掲載情報を入力"
    echo "4. bash scripts/firebase-setup.sh を実行"
    echo "5. BETA_RELEASE_GUIDE.md に従ってリリース"
    exit 0
else
    echo -e "${RED}❌ NO-GO: 修正が必要です${NC}"
    echo ""
    echo "上記のエラーを修正してから再度チェック:"
    echo "bash scripts/pre-release-check.sh"
    exit 1
fi
