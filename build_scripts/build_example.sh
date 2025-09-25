#!/bin/bash

# 🔒 Secure JWT Authentication Build Scripts
# This file contains example build commands for different environments

# Your API credentials
DEV_API_KEY="your_development_api_key_here"
STAGING_API_KEY="your_staging_api_key_here"
PROD_API_KEY="your_production_api_key_here"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔒 Secure JWT Authentication Build Scripts${NC}"
echo "================================================"

# Function to validate API key format
validate_api_key() {
    local api_key=$1
    local env_name=$2
    
    if [ ${#api_key} -ne 64 ]; then
        echo -e "${RED}❌ Error: $env_name API key must be exactly 64 characters long${NC}"
        echo -e "${RED}   Current length: ${#api_key} characters${NC}"
        return 1
    fi
    
    if ! [[ $api_key =~ ^[a-fA-F0-9]+$ ]]; then
        echo -e "${RED}❌ Error: $env_name API key must be hexadecimal${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ $env_name API key format is valid${NC}"
    return 0
}

# Function to build for development
build_dev() {
    echo -e "${YELLOW}🔧 Building for Development...${NC}"
    
    if ! validate_api_key "$DEV_API_KEY" "Development"; then
        return 1
    fi
    
    echo -e "${BLUE}Running development build...${NC}"
    flutter run \
        --dart-define=API_KEY="$DEV_API_KEY" \
        --dart-define=CLIENT_ID="game_client_1" \
        --dart-define=API_BASE="http://localhost:3000"
}

# Function to build for staging
build_staging() {
    echo -e "${YELLOW}🔧 Building for Staging...${NC}"
    
    if ! validate_api_key "$STAGING_API_KEY" "Staging"; then
        return 1
    fi
    
    echo -e "${BLUE}Building staging APK...${NC}"
    flutter build apk \
        --dart-define=API_KEY="$STAGING_API_KEY" \
        --dart-define=CLIENT_ID="staging_client" \
        --dart-define=API_BASE="https://staging-api.yourdomain.com" \
        --release
}

# Function to build for production
build_prod() {
    echo -e "${YELLOW}🔧 Building for Production...${NC}"
    
    if ! validate_api_key "$PROD_API_KEY" "Production"; then
        return 1
    fi
    
    echo -e "${BLUE}Building production APK...${NC}"
    flutter build apk \
        --dart-define=API_KEY="$PROD_API_KEY" \
        --dart-define=CLIENT_ID="production_client" \
        --dart-define=API_BASE="https://api.yourdomain.com" \
        --release
}

# Function to build for iOS
build_ios() {
    echo -e "${YELLOW}🔧 Building for iOS...${NC}"
    
    if ! validate_api_key "$PROD_API_KEY" "Production"; then
        return 1
    fi
    
    echo -e "${BLUE}Building iOS app...${NC}"
    flutter build ios \
        --dart-define=API_KEY="$PROD_API_KEY" \
        --dart-define=CLIENT_ID="production_client" \
        --dart-define=API_BASE="https://api.yourdomain.com" \
        --release
}

# Function to run tests
run_tests() {
    echo -e "${YELLOW}🧪 Running Tests...${NC}"
    
    if ! validate_api_key "$DEV_API_KEY" "Development"; then
        return 1
    fi
    
    echo -e "${BLUE}Running tests with development API key...${NC}"
    flutter test \
        --dart-define=API_KEY="$DEV_API_KEY" \
        --dart-define=CLIENT_ID="game_client_1"
}

# Function to show help
show_help() {
    echo -e "${BLUE}Available commands:${NC}"
    echo "  dev      - Run development build"
    echo "  staging  - Build staging APK"
    echo "  prod     - Build production APK"
    echo "  ios      - Build iOS app"
    echo "  test     - Run tests"
    echo "  help     - Show this help message"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  ./build_example.sh dev"
    echo "  ./build_example.sh prod"
    echo "  ./build_example.sh test"
}

# Main script logic
case "$1" in
    "dev")
        build_dev
        ;;
    "staging")
        build_staging
        ;;
    "prod")
        build_prod
        ;;
    "ios")
        build_ios
        ;;
    "test")
        run_tests
        ;;
    "help"|"--help"|"-h"|"")
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac

echo -e "${GREEN}✅ Build script completed${NC}"
