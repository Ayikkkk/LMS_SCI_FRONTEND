#!/bin/bash

# Script to test all three environments
# Usage: ./test_environments.sh

echo "=================================="
echo "Testing Environment Configuration"
echo "=================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test Development Environment
echo -e "${BLUE}1. Testing DEVELOPMENT environment...${NC}"
flutter run --dart-define=ENV=development -d chrome --web-port=8080 &
PID1=$!
sleep 5
echo -e "${GREEN}✓ Development environment started${NC}"
echo "   Check console for: Environment: Development"
echo "   API URL should be: http://192.168.101.82:8000/api/"
echo ""
kill $PID1 2>/dev/null

# Test Staging Environment
echo -e "${BLUE}2. Testing STAGING environment...${NC}"
flutter run --dart-define=ENV=staging -d chrome --web-port=8081 &
PID2=$!
sleep 5
echo -e "${GREEN}✓ Staging environment started${NC}"
echo "   Check console for: Environment: Staging"
echo "   API URL should be: https://staging-api.yourdomain.com/api/"
echo ""
kill $PID2 2>/dev/null

# Test Production Environment
echo -e "${BLUE}3. Testing PRODUCTION environment...${NC}"
flutter run --dart-define=ENV=production -d chrome --web-port=8082 &
PID3=$!
sleep 5
echo -e "${GREEN}✓ Production environment started${NC}"
echo "   Check console for: Environment: Production"
echo "   API URL should be: https://api.yourdomain.com/api/"
echo ""
kill $PID3 2>/dev/null

echo "=================================="
echo -e "${GREEN}All environments tested!${NC}"
echo "=================================="
echo ""
echo "Next steps:"
echo "1. Check the console output for each environment"
echo "2. Verify API URLs are correct"
echo "3. Update production URLs in lib/core/config/environment.dart"
echo "4. Test API connectivity for each environment"
echo ""
