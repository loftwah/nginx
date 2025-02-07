#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🚀 Starting proxy tests..."

# Function to test an endpoint
test_endpoint() {
    local url=$1
    local expected_status=$2
    local description=$3
    
    echo -n "Testing $description... "
    
    response=$(curl -s -w "\n%{http_code}" "$url")
    status=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed \$d)

    if [ "$status" -eq "$expected_status" ]; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC}"
        echo "Expected status $expected_status, got $status"
        echo "Response body: $body"
        return 1
    fi
}

# Test health endpoint
test_endpoint "http://localhost:42069/health" 200 "health check endpoint"

# Test main proxy to default nginx
test_endpoint "http://localhost:42069/" 200 "proxy to backend"

# Test large header handling
test_endpoint "http://localhost:42069/" 200 "large header handling" \
    -H "X-Test-Header: $(printf 'x%.0s' {1..1000})"

# Test gzip compression
echo -n "Testing gzip compression... "
if curl -sI -H "Accept-Encoding: gzip" "http://localhost:42069/" | grep -q "Content-Encoding: gzip"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "Gzip compression not working"
    exit 1
fi

# Validate JSON logging
echo -n "Validating JSON logs... "
log_entry=$(docker compose logs --tail=1 reverse-proxy | grep -o '{.*}')
if echo "$log_entry" | jq . >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "Invalid JSON log format"
    exit 1
fi

# Test proxy headers
echo -n "Testing proxy headers... "
headers=$(curl -sI "http://localhost:42069/")
if echo "$headers" | grep -q "Server: nginx" && \
   echo "$headers" | grep -q "Content-Type:"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "Missing expected headers"
    exit 1
fi

echo "✨ All tests passed successfully!" 