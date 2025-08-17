#!/bin/sh

# 测试参数
SERVER="192.168.3.2"
PORT="6773"
DOMAIN="example.com"

# 生成 DNS 查询二进制
echo -n -e "\x00\x00\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00\x07${DOMAIN%.*}\x03${DOMAIN##*.}\x00\x00\x01\x00\x01" > query.bin

# 测试 POST 请求
echo "=== Testing DoH with POST ==="
curl -k -v -X POST \
  -H "Content-Type: application/dns-message" \
  --data-binary @query.bin \
  "https://$SERVER:$PORT/dns-query" 2>&1 | grep -E "< HTTP|< Content-Type|^\{"

# 测试 GET 请求
echo -e "\n=== Testing DoH with GET ==="
DNS_QUERY=$(base64 -w0 query.bin | tr '/+' '_-' | tr -d '=')
curl -k -v "https://$SERVER:$PORT/dns-query?dns=$DNS_QUERY" 2>&1 | grep -E "< HTTP|< Content-Type|^\{"