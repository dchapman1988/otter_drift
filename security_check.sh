#!/bin/bash

# 🔒 Security Check Script
# This script verifies that no sensitive information is committed to git

echo "🔒 Running Security Check..."
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check for hardcoded API keys (exclude documentation and example files)
echo -e "${BLUE}🔍 Checking for hardcoded API keys...${NC}"
if grep -r "78f28fff4b059717021ca7862609a75f239af89ecc717fb1558edd6243705ee0" . --exclude-dir=.git --exclude-dir=build --exclude-dir=.dart_tool --exclude="security_check.sh" --exclude="run_dev.sh" --exclude="*.md" --exclude="build_scripts/*" --exclude=".vscode/*" > /dev/null 2>&1; then
    echo -e "${RED}❌ Found hardcoded API key in source code!${NC}"
    grep -r "78f28fff4b059717021ca7862609a75f239af89ecc717fb1558edd6243705ee0" . --exclude-dir=.git --exclude-dir=build --exclude-dir=.dart_tool --exclude="security_check.sh" --exclude="run_dev.sh" --exclude="*.md" --exclude="build_scripts/*" --exclude=".vscode/*"
    exit 1
else
    echo -e "${GREEN}✅ No hardcoded API keys found in source code${NC}"
fi

# Check for common secret patterns
echo -e "${BLUE}🔍 Checking for common secret patterns...${NC}"
if grep -r -i "api_key.*=" . --exclude-dir=.git --exclude-dir=build --exclude="security_check.sh" --exclude="run_dev.sh" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Found potential API key assignments. Please verify these are safe:${NC}"
    grep -r -i "api_key.*=" . --exclude-dir=.git --exclude-dir=build --exclude="security_check.sh" --exclude="run_dev.sh"
else
    echo -e "${GREEN}✅ No suspicious API key assignments found${NC}"
fi

# Check for .env files
echo -e "${BLUE}🔍 Checking for .env files...${NC}"
if find . -name ".env*" -not -path "./.git/*" | grep -q .; then
    echo -e "${YELLOW}⚠️  Found .env files. Please ensure they're in .gitignore:${NC}"
    find . -name ".env*" -not -path "./.git/*"
else
    echo -e "${GREEN}✅ No .env files found${NC}"
fi

# Check git status for sensitive files
echo -e "${BLUE}🔍 Checking git status for sensitive files...${NC}"
if git status --porcelain | grep -E "\.(key|pem|env|log)$" > /dev/null 2>&1; then
    echo -e "${RED}❌ Found sensitive files in git status!${NC}"
    git status --porcelain | grep -E "\.(key|pem|env|log)$"
    exit 1
else
    echo -e "${GREEN}✅ No sensitive files in git status${NC}"
fi

# Check if run_dev.sh is ignored
echo -e "${BLUE}🔍 Checking if run_dev.sh is properly ignored...${NC}"
if git check-ignore run_dev.sh > /dev/null 2>&1; then
    echo -e "${GREEN}✅ run_dev.sh is properly ignored by git${NC}"
else
    echo -e "${RED}❌ run_dev.sh is NOT ignored by git!${NC}"
    exit 1
fi

# Check for certificate files
echo -e "${BLUE}🔍 Checking for certificate files...${NC}"
if find . -name "*.crt" -o -name "*.pem" -o -name "*.p12" -o -name "*.jks" -o -name "*.keystore" | grep -v ".git" | grep -q .; then
    echo -e "${YELLOW}⚠️  Found certificate files. Please ensure they're in .gitignore:${NC}"
    find . -name "*.crt" -o -name "*.pem" -o -name "*.p12" -o -name "*.jks" -o -name "*.keystore" | grep -v ".git"
else
    echo -e "${GREEN}✅ No certificate files found${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Security check completed successfully!${NC}"
echo -e "${BLUE}💡 Remember to always use --dart-define for API keys${NC}"
echo -e "${BLUE}💡 Never commit sensitive information to version control${NC}"
