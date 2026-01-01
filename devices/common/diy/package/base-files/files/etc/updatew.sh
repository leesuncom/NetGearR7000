#!/bin/sh
# ==============================================================================
# OpenWRT 网络配置一键更新脚本（无判断+无sudo简化版 v2.3 2025-11-23）
# 功能：更新 Hosts、SmartDNS 规则、dnscrypt-proxy 配置、MosDNS 规则，并重启相关服务
# 适用环境：基于 OpenWRT 的路由器（如 R619AC）
# 执行权限：必须 root 用户（无 sudo 提权，非 root 必然权限不足失败）
# 说明：1. 已移除所有 if 条件判断、容错校验 2. 已移除所有 sudo 提权语句 3. 仅保留核心执行逻辑
# ==============================================================================

# -------------------------- 基础配置（可按需调整） --------------------------
SCRIPT_VERSION="v2.3"
TMP_DIR="/tmp/update-config"
GITHUB_PROXY="https://gh-proxy.com/"  # 末尾必须带 /，确保 URL 拼接正确
MIN_TMP_SPACE=5  # 原最小 /tmp 剩余空间（MB），已移除校验，仅作参考

# 各组件配置目录
MOSDNS_RULE_DIR="/etc/mosdns/rule"
SMARTDNS_CONF_DIR="/etc/smartdns"
DNSCRYPT_CONF_DIR="/etc/dnscrypt-proxy2"

# curl 通用参数（静默+证书忽略+重定向+超时+重试）
CURL_OPTS="-sS -k -L --connect-timeout 15 --max-time 30 --retry 2 --retry-delay 3"

# -------------------------- 工具函数（无判断+无sudo） --------------------------
# 1. 权限提示：需手动确保 root 执行（无权限检查+无sudo）
check_root() {
  echo "  → 请确保当前为 root 用户执行（无 sudo 提权，非 root 会权限不足）"
}

# 2. /tmp 空间检查：已移除 if 判断，仅打印空间信息
check_tmp_space() {
  echo "  → 检查 /tmp 剩余空间（已移除空间不足校验）..."
  TMP_FREE=$(df -m /tmp | awk 'NR==2 {print $4}')
  echo "  ✅ /tmp 剩余空间：$TMP_FREE MB（建议不低于 $MIN_TMP_SPACE MB）"
}

# 3. 目录创建：移除 sudo，直接创建目录
ensure_dir() {
  local dir="$1"
  mkdir -p "$dir"
  echo "  → 创建目录：$dir"
}

# 4. 文件下载：已移除 if 判断，直接执行 curl 下载
download_file() {
  local url="$1"
  local dest="$2"
  local desc="$3"
  
  # 打印完整 URL（调试用，确认无截断）
  echo "  → 下载：$desc（URL：${url:0:60}...）"
  curl $CURL_OPTS "$url" -o "$dest"
  echo "  → $desc 下载完成"
}

# 5. 文件复制：移除 sudo，直接执行 cp 复制
copy_file() {
  local src="$1"
  local dest="$2"
  local desc="$3"
  
  echo "  → 复制：$desc（$src → $dest）"
  cp -f "$src" "$dest"
  echo "  → $desc 复制完成"
}

# 6. 服务重启：移除 sudo，直接执行重启命令
restart_service() {
  local service="$1"
  echo "  → 重启：$service 服务"
  /etc/init.d/$service restart
}

# 7. 生成规则列表：保留核心功能，无判断语句
generate_list() {
  cat << EOF
$1
EOF
}

# -------------------------- 初始化（前置准备，无判断+无sudo） --------------------------
check_root

# 捕获退出信号，清理临时目录
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

# 初始化临时目录：移除 || 容错判断，直接创建
echo "[1/6] 初始化环境..."
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
echo "  ✅ 临时目录：$TMP_DIR"

# 检查 /tmp 空间（已移除校验）
check_tmp_space

# 确保目标目录存在
ensure_dir "$SMARTDNS_CONF_DIR/domain-set"
ensure_dir "$SMARTDNS_CONF_DIR/ip-set"
ensure_dir "$SMARTDNS_CONF_DIR/conf.d"
ensure_dir "$DNSCRYPT_CONF_DIR"
ensure_dir "$MOSDNS_RULE_DIR"
echo "  ✅ 所有目标目录准备完成"

# -------------------------- 核心功能：更新各组件配置（无sudo） --------------------------
# [3/6] 更新 SmartDNS 规则（移除循环内非空判断+无sudo）
echo -e "\n[3/6] 更新 SmartDNS 规则..."
generate_list "
${GITHUB_PROXY}raw.githubusercontent.com/leesuncom/update/refs/heads/main/r619ac/etc/smartdns/blacklist-ip.conf|$SMARTDNS_CONF_DIR/blacklist-ip.conf|IP黑名单
https://www.cloudflare.com/ips-v4/|$SMARTDNS_CONF_DIR/ip-set/cloudflare-ipv4.txt|Cloudflare IPv4列表
${GITHUB_PROXY}raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt|$SMARTDNS_CONF_DIR/ip-set/china_ip_list.txt|中国IP列表
${GITHUB_PROXY}raw.githubusercontent.com/leesuncom/update/refs/heads/main/r619ac/etc/smartdns/domain-set/domains.china.smartdns.conf|$SMARTDNS_CONF_DIR/domain-set/domains.china.smartdns.conf|中国域名列表
${GITHUB_PROXY}raw.githubusercontent.com/leesuncom/update/refs/heads/main/r619ac/etc/smartdns/domain-set/proxy-domain-list.conf|$SMARTDNS_CONF_DIR/domain-set/proxy-domain-list.conf|GFW代理域名列表
${GITHUB_PROXY}raw.githubusercontent.com/Cats-Team/AdRules/main/smart-dns.conf|$SMARTDNS_CONF_DIR/address.conf|Cats-Team广告过滤规则
https://anti-ad.net/anti-ad-for-smartdns.conf|$SMARTDNS_CONF_DIR/conf.d/anti-ad-smartdns.conf|anti-ad广告过滤规则
" | while IFS="|" read -r url dest desc; do
  download_file "$url" "$TMP_DIR/$(basename "$dest")" "$desc"
  copy_file "$TMP_DIR/$(basename "$dest")" "$dest" "$desc"
  rm -f "$TMP_DIR/$(basename "$dest")"
done
echo "  ✅ SmartDNS 规则更新完成"

# [4/6] 更新 dnscrypt-proxy 配置（移除循环内非空判断+无sudo）
echo -e "\n[4/6] 更新 dnscrypt-proxy 配置..."
generate_list "
dnscrypt-blacklist-domains.txt|域名黑名单
dnscrypt-blacklist-ips.txt|IP黑名单
dnscrypt-captive-portals.txt|公共网络检测规则
dnscrypt-cloaking-rules.txt|域名伪装规则
dnscrypt-forwarding-rules.txt|转发规则
dnscrypt-whitelist-domains.txt|域名白名单
dnscrypt-whitelist-ips.txt|IP白名单
relays.md|中继服务器文档
public-resolvers.md|公共解析器文档
parental-control.md|家长控制文档
odoh-servers.md|ODOH服务器文档
odoh-relays.md|ODOH中继文档
" | while IFS="|" read -r filename desc; do
  url="${GITHUB_PROXY}raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/$filename"
  download_file "$url" "$DNSCRYPT_CONF_DIR/$filename" "$desc"
done
echo "  ✅ dnscrypt-proxy 配置更新完成"

# [5/6] 更新 MosDNS 规则（分批下载，无判断+无sudo）
echo -e "\n[5/6] 更新 MosDNS 规则..."

# 5.1 Journalist-HK 规则集（移除 sudo）
echo "  → 下载 Journalist-HK 规则集..."
generate_list "
akamai_domain_list.txt|akamai_domain_list.txt
block_list.txt|blocklist.txt
cachefly_ipv4.txt|cachefly_ipv4.txt
cdn77_ipv4.txt|cdn77_ipv4.txt
cdn77_ipv6.txt|cdn77_ipv6.txt
china_domain_list_mini.txt|china_domain_list_mini.txt
cloudfront.txt|cloudfront.txt
cloudfront_ipv6.txt|cloudfront_ipv6.txt
custom_list.txt|custom_list.txt
gfw_ip_list.txt|gfw_ip_list.txt
grey_list_js.txt|grey_list_js.txt
grey_list.txt|greylist.txt
hosts_akamai.txt|hosts_akamai.txt
hosts_fastly.txt|hosts_fastly.txt
jp_dns_list.txt|jp_dns_list.txt
original_domain_list.txt|original_domain_list.txt
ipv6_domain_list.txt|ipv6_domain_list.txt
private.txt|private.txt
redirect.txt|redirect.txt
sucuri_ipv4.txt|sucuri_ipv4.txt
us_dns_list.txt|us_dns_list.txt
white_list.txt|whitelist.txt
" | while IFS="|" read -r src dest; do
  url="${GITHUB_PROXY}raw.githubusercontent.com/Journalist-HK/Rules/main/$src"
  download_file "$url" "$TMP_DIR/$dest" "Journalist-HK/$src"
  cp -f "$TMP_DIR/$dest" "$MOSDNS_RULE_DIR/"
  rm -f "$TMP_DIR/$dest"
done

# 5.2 Loyalsoldier 规则集（移除 sudo）
echo "  → 下载 Loyalsoldier 规则集..."
generate_list "
geoip/release/text/facebook.txt|facebook.txt|Facebook IP列表
geoip/release/text/fastly.txt|fastly.txt|Fastly IP列表
geoip/release/text/telegram.txt|telegram.txt|Telegram IP列表
geoip/release/text/twitter.txt|twitter.txt|Twitter IP列表
v2ray-rules-dat/release/gfw.txt|gfw.txt|GFW域名列表
v2ray-rules-dat/release/greatfire.txt|greatfire.txt|GreatFire域名列表
" | while IFS="|" read -r path dest desc; do
  url="${GITHUB_PROXY}raw.githubusercontent.com/Loyalsoldier/$path"
  download_file "$url" "$TMP_DIR/$dest" "Loyalsoldier/$desc"
  cp -f "$TMP_DIR/$dest" "$MOSDNS_RULE_DIR/"
  rm -f "$TMP_DIR/$dest"
done

# 5.3 pmkol/easymosdns 规则集（移除 sudo）
echo "  → 下载 pmkol/easymosdns 规则集..."
generate_list "
rules/ad_domain_list.txt|ad_domain_list.txt|广告域名列表
rules/cdn_domain_list.txt|cdn_domain_list.txt|CDN域名列表
rules/china_domain_list.txt|china_domain_list.txt|中国域名列表
rules/china_ip_list.txt|china_ip_list.txt|中国IP列表
" | while IFS="|" read -r path dest desc; do
  url="${GITHUB_PROXY}raw.githubusercontent.com/pmkol/easymosdns/$path"
  download_file "$url" "$TMP_DIR/$dest" "pmkol/$desc"
  cp -f "$TMP_DIR/$dest" "$MOSDNS_RULE_DIR/"
  rm -f "$TMP_DIR/$dest"
done

# 5.4 CloudflareSpeedTest IP列表（移除 sudo）
echo "  → 下载 CloudflareSpeedTest 规则集..."
download_file "${GITHUB_PROXY}raw.githubusercontent.com/XIU2/CloudflareSpeedTest/master/ip.txt" \
  "$TMP_DIR/ip.txt" "Cloudflare IPv4测试列表"
cp -f "$TMP_DIR/ip.txt" "$MOSDNS_RULE_DIR/"
rm -f "$TMP_DIR/ip.txt"

download_file "${GITHUB_PROXY}raw.githubusercontent.com/XIU2/CloudflareSpeedTest/master/ipv6.txt" \
  "$TMP_DIR/ipv6.txt" "Cloudflare IPv6测试列表"
cp -f "$TMP_DIR/ipv6.txt" "$MOSDNS_RULE_DIR/"
rm -f "$TMP_DIR/ipv6.txt"

echo "  ✅ MosDNS 规则更新完成"

# [6/6] 重启服务 + 清理收尾（无sudo）
echo -e "\n[6/6] 重启服务并清理..."
restart_service "dnscrypt-proxy"
restart_service "mosdns"
restart_service "smartdns"

# 最终清理
rm -rf "$TMP_DIR"
echo "  ✅ 临时文件已彻底清理"

# -------------------------- 结束提示 --------------------------
echo -e "\n======================================"
echo "✅ 全部配置更新完成！（脚本版本：$SCRIPT_VERSION）"
echo "📌 关键注意事项（无 sudo 版本专属）："
echo "  1. 必须以 root 用户执行（无 sudo 提权，普通用户会权限不足导致失败）"
echo "  2. 已移除所有容错判断，需手动确保 /tmp 空间充足、网络通畅、curl 已安装"
echo "  3. 服务状态检查：/etc/init.d/{dnscrypt-proxy,mosdns,smartdns} status"
echo "  4. 网络测试：ping baidu.com / ping google.com（验证解析）"
echo "  5. 代理更换：若下载失败，可修改 GITHUB_PROXY 为 https://gh.api.99988866.xyz/"
echo "======================================"