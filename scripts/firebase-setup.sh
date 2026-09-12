#!/bin/bash

##########################################################
# Firebase セットアップスクリプト
#
# 用途: Kanken Flutter アプリの Firebase 初期化
# 使い方: bash scripts/firebase-setup.sh
##########################################################

set -e  # エラーで終了

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔥 Firebase セットアップを開始します${NC}\n"

# Step 1: Firebase CLI インストール確認
echo -e "${YELLOW}📦 Step 1: Firebase CLI を確認中...${NC}"

if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI がインストールされていません${NC}"
    echo "以下のコマンドでインストール:"
    echo "npm install -g firebase-tools"
    exit 1
fi

FIREBASE_VERSION=$(firebase --version)
echo -e "${GREEN}✓ Firebase CLI インストール済み: ${FIREBASE_VERSION}${NC}\n"

# Step 2: Firebase ログイン
echo -e "${YELLOW}🔐 Step 2: Firebase にログイン...${NC}"

firebase login --no-localhost

echo -e "${GREEN}✓ Firebase ログイン完了${NC}\n"

# Step 3: プロジェクト確認
echo -e "${YELLOW}📋 Step 3: Firebase プロジェクト一覧${NC}"

firebase projects:list

echo -e "\n${YELLOW}使用するプロジェクト ID を入力してください:${NC}"
read PROJECT_ID

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}❌ プロジェクト ID を入力してください${NC}"
    exit 1
fi

echo -e "${GREEN}✓ プロジェクト ID: ${PROJECT_ID}${NC}\n"

# Step 4: Firebase 初期化
echo -e "${YELLOW}⚙️  Step 4: Firebase を初期化...${NC}"

firebase use "$PROJECT_ID"

echo -e "${GREEN}✓ プロジェクト選択完了${NC}\n"

# Step 5: Android google-services.json 取得
echo -e "${YELLOW}📱 Step 5: Android google-services.json を取得...${NC}"

# Firebase Console から手動でダウンロードが必要
echo "次の手順を実行してください:"
echo "1. https://firebase.google.com/docs/android/setup を開く"
echo "2. 'google-services.json' をダウンロード"
echo "3. android/app/ に配置"
echo ""
echo "配置確認:"

if [ -f "android/app/google-services.json" ]; then
    echo -e "${GREEN}✓ google-services.json が見つかりました${NC}"
else
    echo -e "${RED}❌ google-services.json が見つかりません${NC}"
    echo "手動で android/app/ に配置してください"
fi

echo -e "\n"

# Step 6: Firebase セキュリティルール設定
echo -e "${YELLOW}🔒 Step 6: Firestore セキュリティルール設定...${NC}"

# rules ファイル確認
if [ -f "firestore.rules" ]; then
    echo -e "${GREEN}✓ firestore.rules が見つかりました${NC}"
    echo "デプロイしますか? (y/n)"
    read DEPLOY_RULES

    if [ "$DEPLOY_RULES" = "y" ]; then
        firebase deploy --only firestore:rules
        echo -e "${GREEN}✓ Firestore ルール デプロイ完了${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  firestore.rules が見つかりません${NC}"
    echo "Firestore セキュリティルールを手動で設定してください:"
    echo "https://console.firebase.google.com/"
fi

echo -e "\n"

# Step 7: Firebase サービス確認
echo -e "${YELLOW}✅ Step 7: Firebase サービス確認${NC}"

echo "Firebase Console で以下を確認:"
echo "  [ ] Authentication: Email/Password 有効"
echo "  [ ] Firestore: Database 作成済み"
echo "  [ ] Analytics: 有効"
echo "  [ ] Crashlytics: 有効"
echo ""

# Step 8: Flutter Firebase 設定
echo -e "${YELLOW}📦 Step 8: Flutter Firebase パッケージ設定${NC}"

echo "以下のコマンドを実行:"
echo "  flutter pub get"
echo "  flutter pub run build_runner build --delete-conflicting-outputs"
echo ""

read -p "実行しますか? (y/n)" RUN_PUB_GET

if [ "$RUN_PUB_GET" = "y" ]; then
    cd "$(dirname "$0")/.."
    flutter pub get
    flutter pub run build_runner build --delete-conflicting-outputs
    echo -e "${GREEN}✓ パッケージ設定完了${NC}"
fi

echo -e "\n"

# Step 9: 環境変数設定 (オプション)
echo -e "${YELLOW}🔧 Step 9: 環境変数設定 (オプション)${NC}"

if [ ! -f ".env" ]; then
    echo "Create .env file with Firebase configuration? (y/n)"
    read CREATE_ENV

    if [ "$CREATE_ENV" = "y" ]; then
        cat > .env << EOF
# Firebase Configuration
FIREBASE_PROJECT_ID=${PROJECT_ID}
FIREBASE_API_KEY=YOUR_API_KEY_HERE
FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID_HERE
FIREBASE_APP_ID=YOUR_APP_ID_HERE

# Optional: Emulator (for development)
FIREBASE_EMULATOR_HOST=localhost:5001
EOF
        echo -e "${GREEN}✓ .env ファイル作成${NC}"
        echo "注意: YOUR_* の値を Firebase Console から取得して入力してください"
    fi
else
    echo -e "${GREEN}✓ .env ファイルが既に存在します${NC}"
fi

echo -e "\n"

# Step 10: テスト実行
echo -e "${YELLOW}🧪 Step 10: Firebase 接続テスト${NC}"

echo "Firebase 接続をテストしますか? (y/n)"
read RUN_TEST

if [ "$RUN_TEST" = "y" ]; then
    echo "以下のコマンドを実行:"
    echo "  flutter run"
    echo ""
    echo "ログイン画面が表示されたら、テストアカウントでログインしてください"
fi

echo -e "\n"

# 完了
echo -e "${GREEN}✅ Firebase セットアップ完了!${NC}\n"

echo "次のステップ:"
echo "1. android/app/google-services.json を配置"
echo "2. Firebase Console でセキュリティルール設定"
echo "3. flutter run でアプリをテスト"
echo "4. ビルドして Google Play Console にアップロード"
echo ""

echo -e "${YELLOW}参考リンク:${NC}"
echo "- Firebase ドキュメント: https://firebase.google.com/docs"
echo "- Google Play Console: https://play.google.com/console"
echo "- Kanken Wiki: https://github.com/zka32101/kanken/wiki"

echo ""
echo -e "${GREEN}セットアップスクリプト終了${NC}"
