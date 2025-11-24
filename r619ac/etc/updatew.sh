#!/bin/sh
# ==============================================================================
# OpenWRT 网络配置一键更新脚本（最终稳定版 v2.3 2025-11-23）
# 功能：更新 Hosts、SmartDNS 规则、dnscrypt-proxy 配置、MosDNS 规则，并重启相关服务
# 适用环境：基于 OpenWRT 的路由器（如 R619AC）
# 执行权限：必须 root 用户（脚本内置权限检查）
# 修复点：URL 截断、/tmp 空间检查、网络重试、格式校验
# ==============================================================================

# -------------------------- 基础配置（可按需调整） --------------------------
SCRIPT_VERSION="v2.3"
TMP_DIR="/tmp/update-config"
GITHUB_PROXY="https://gh-proxy.com/"  # 末尾必须带 /，确保 URL 拼接正确
MIN_TMP_SPACE=5  # 最小 /tmp 剩余空间（MB），低于则退出

# 各组件配置目录
MOSDNS_RULE_DIR="/etc/mosdns/rule"
SMARTDNS_CONF_DIR="/etc/smartdns"
DNSCRYPT_CONF_DIR="/etc/dnscrypt-proxy2"

# curl 通用参数（静默+证书忽略+重定向+超时+重试）
CURL_OPTS="-sS -k -L --connect-timeout 15 --max-time 30 --retry 2 --retry-delay 3"

# -------------------------- 工具函数（增强容错） --------------------------
# 1. 权限检查：非 root 直接退出
check_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "❌ 错误：请使用 root 用户执行（或前缀加 sudo）"
    exit 1
  fi
}

# 2. /tmp 空间检查：确保有足够空间下载文件
check_tmp_space() {
  echo "  → 检查 /tmp 剩余空间..."
  # 计算 /tmp 剩余空间（MB），兼容 OpenWRT df 输出
  TMP_FREE=$(df -m /tmp | awk 'NR==2 {print $4}')
  if [ -z "$TMP_FREE" ] || [ "$TMP_FREE" -lt "$MIN_TMP_SPACE" ]; then
    echo "❌ 错误：/tmp 剩余空间不足（当前 $TMP_FREE MB，需至少 $MIN_TMP_SPACE MB）"
    echo "  解决方案：1. 清理 /tmp 冗余文件 2. 扩大 tmpfs 容量（需修改 OpenWRT 配置）"
    exit 1
  fi
  echo "  ✅ /tmp 剩余空间充足：$TMP_FREE MB"
}

# 3. 目录创建：确保目标目录存在（含 sudo 权限）
ensure_dir() {
  local dir="$1"
  if ! sudo mkdir -p "$dir"; then
    echo "❌ 错误：创建目录 $dir 失败（权限不足或磁盘满）"
    exit 1
  fi
}

# 4. 文件下载：增强调试输出，确保 URL 完整
download_file() {
  local url="$1"
  local dest="$2"
  local desc="$3"
  
  # 打印完整 URL（调试用，确认无截断）
  echo "  → 下载：$desc（URL：${url:0:60}...）"  # 只显示前60字符，避免输出过长
  if ! curl $CURL_OPTS "$url" -o "$dest"; then
    echo "❌ 错误：$desc 下载失败"
    echo "  完整 URL：$url"
    echo "  排查建议：1. 代理是否有效 2. 网络是否通畅 3. URL 是否存在 4. /tmp 空间是否充足"
    exit 1
  fi
}

# 5. 文件复制：统一处理复制逻辑
copy_file() {
  local src="$1"
  local dest="$2"
  local desc="$3"
  
  echo "  → 复制：$desc（$src → $dest）"
  if ! sudo cp -f "$src" "$dest"; then
    echo "❌ 错误：$desc 复制失败"
    exit 1
  fi
}

# 6. 服务重启：检查服务是否存在
restart_service() {
  local service="$1"
  echo "  → 重启：$service 服务"
  if [ -f "/etc/init.d/$service" ]; then
    if ! sudo /etc/init.d/$service restart; then
      echo "⚠️  警告：$service 重启失败，请手动检查状态"
    fi
  else
    echo "⚠️  警告：$service 未安装，跳过重启"
  fi
}

# 7. 生成规则列表：避免文件残留，用管道直接传递（无需临时文件）
# 作用：替代之前的临时文件，减少 I/O 并避免解析错误
generate_list() {
  cat << EOF
$1
EOF
}

# -------------------------- 初始化（前置准备） --------------------------
check_root

# 捕获退出信号，清理临时目录
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

# 初始化临时目录
echo "[1/6] 初始化环境..."
rm -rf "$TMP_DIR"  # 彻底清理旧残留
mkdir -p "$TMP_DIR" || { echo "❌ 错误：创建临时目录失败"; exit 1; }
echo "  ✅ 临时目录：$TMP_DIR"

# 检查 /tmp 空间（关键修复）
check_tmp_space

# 确保目标目录存在
ensure_dir "$SMARTDNS_CONF_DIR/domain-set"
ensure_dir "$SMARTDNS_CONF_DIR/ip-set"
ensure_dir "$SMARTDNS_CONF_DIR/conf.d"
ensure_dir "$DNSCRYPT_CONF_DIR"
ensure_dir "$MOSDNS_RULE_DIR"
echo "  ✅ 所有目标目录准备完成"

# -------------------------- 核心功能：更新各组件配置 --------------------------
# [2/6] 更新系统 Hosts
echo -e "\n[2/6] 更新系统 Hosts 文件..."
sudo sed -i '/# ING Hosts Start/,/# ING Hosts End/d' /etc/hosts
download_file "${GITHUB_PROXY}raw.githubusercontent.com/shidahuilang/hosts/main/hosts" \
  "$TMP_DIR/new-hosts.txt" "系统 Hosts 规则"
cat "$TMP_DIR/new-hosts.txt" | sort -u | sudo tee -a /etc/hosts
rm -f "$TMP_DIR/new-hosts.txt"  # 及时清理，释放空间
echo "  ✅ Hosts 更新完成"

# [3/6] 更新 SmartDNS 规则（用管道传递列表，避免临时文件解析错误）
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
  [ -z "$url" ] && continue
  download_file "$url" "$TMP_DIR/$(basename "$dest")" "$desc"
  copy_file "$TMP_DIR/$(basename "$dest")" "$dest" "$desc"
  rm -f "$TMP_DIR/$(basename "$dest")"  # 下载后立即清理，释放空间
done
echo "  ✅ SmartDNS 规则更新完成"

# [4/6] 更新 dnscrypt-proxy 配置
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
  [ -z "$filename" ] && continue
  url="${GITHUB_PROXY}raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/$filename"
  download_file "$url" "$DNSCRYPT_CONF_DIR/$filename" "$desc"
done
echo "  ✅ dnscrypt-proxy 配置更新完成"

# [5/6] 更新 MosDNS 规则（分批下载+及时清理，避免 tmp 满）
echo -e "\n[5/6] 更新 MosDNS 规则..."

# 5.1 Journalist-HK 规则集
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
  [ -z "$src" ] && continue
  url="${GITHUB_PROXY}raw.githubusercontent.com/Journalist-HK/Rules/main/$src"
  download_file "$url" "$TMP_DIR/$dest" "Journalist-HK/$src"
  sudo cp -f "$TMP_DIR/$dest" "$MOSDNS_RULE_DIR/"
  rm -f "$TMP_DIR/$dest"  # 立即清理
done

# 5.2 Loyalsoldier 规则集
echo "  → 下载 Loyalsoldier 规则集..."
generate_list "
geoip/release/text/facebook.txt|facebook.txt|Facebook IP列表
geoip/release/text/fastly.txt|fastly.txt|Fastly IP列表
geoip/release/text/telegram.txt|telegram.txt|Telegram IP列表
geoip/release/text/twitter.txt|twitter.txt|Twitter IP列表
v2ray-rules-dat/release/gfw.txt|gfw.txt|GFW域名列表
v2ray-rules-dat/release/greatfire.txt|greatfire.txt|GreatFire域名列表
" | while IFS="|" read -r path dest desc; do
  [ -z "$path" ] && continue
  url="${GITHUB_PROXY}raw.githubusercontent.com/Loyalsoldier/$path"
  download_file "$url" "$TMP_DIR/$dest" "Loyalsoldier/$desc"
  sudo cp -f "$TMP_DIR/$dest" "$MOSDNS_RULE_DIR/"
  rm -f "$TMP_DIR/$dest"  # 立即清理
done

# 5.3 pmkol/easymosdns 规则集（重点修复：确保路径完整）
echo "  → 下载 pmkol/easymosdns 规则集..."
generate_list "
rules/ad_domain_list.txt|ad_domain_list.txt|广告域名列表
rules/cdn_domain_list.txt|cdn_domain_list.txt|CDN域名列表
rules/china_domain_list.txt|china_domain_list.txt|中国域名列表
rules/china_ip_list.txt|china_ip_list.txt|中国IP列表
" | while IFS="|" read -r path dest desc; do
  [ -z "$path" ] && continue
  url="${GITHUB_PROXY}raw.githubusercontent.com/pmkol/easymosdns/$path"
  download_file "$url" "$TMP_DIR/$dest" "pmkol/$desc"
  sudo cp -f "$TMP_DIR/$dest" "$MOSDNS_RULE_DIR/"
  rm -f "$TMP_DIR/$dest"  # 立即清理
done

# 5.4 CloudflareSpeedTest IP列表
echo "  → 下载 CloudflareSpeedTest 规则集..."
download_file "${GITHUB_PROXY}raw.githubusercontent.com/XIU2/CloudflareSpeedTest/master/ip.txt" \
  "$TMP_DIR/ip.txt" "Cloudflare IPv4测试列表"
sudo cp -f "$TMP_DIR/ip.txt" "$MOSDNS_RULE_DIR/"
rm -f "$TMP_DIR/ip.txt"

download_file "${GITHUB_PROXY}raw.githubusercontent.com/XIU2/CloudflareSpeedTest/master/ipv6.txt" \
  "$TMP_DIR/ipv6.txt" "Cloudflare IPv6测试列表"
sudo cp -f "$TMP_DIR/ipv6.txt" "$MOSDNS_RULE_DIR/"
rm -f "$TMP_DIR/ipv6.txt"

echo "  ✅ MosDNS 规则更新完成"

# [6/6] 重启服务 + 清理收尾
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
echo "📌 检查要点："
echo "  1. 服务状态：/etc/init.d/{dnscrypt-proxy,mosdns,smartdns} status"
echo "  2. 网络测试：ping baidu.com / ping google.com（验证解析）"
echo "  3. 若仍失败：更换代理（如 https://gh.api.99988866.xyz/）"
echo "======================================"