#!/bin/sh
# ==============================================================================
# OpenWRT 双目录配置更新脚本（SmartDNS + dnscrypt-proxy + mosdns）
# 功能：1. 生成SmartDNS的GFW代理/中国域名/IP黑名单/SPKI证书配置
#       2. 生成dnscrypt-proxy的转发规则/黑白名单/伪装规则
#       3. 同步输出到 r619ac/ 和 common/ 两个配置目录（目录已提前创建）
#       4. 更新mosdns规则列表
# 适用环境：OpenWRT 路由器（需预装 curl、wget、openssl、sed、sort 工具）
# 依赖安装：opkg update && opkg install curl wget openssl coreutils-sort
# ==============================================================================
# Powered by Apad.pro
# https://apad.pro/easymosdns
#

# -------------------------- 0. 初始化：创建并清理临时文件（关键修复） --------------------------
echo "[初始化] 创建并清理临时文件..."
# 临时文件目录（强制创建，解决/tmp目录重启后丢失问题）
TMP_DIR="/tmp/dns-config-tmp"
mkdir -p "$TMP_DIR"  # 核心修复：确保临时目录存在
rm -rf "$TMP_DIR"/*  # 清空目录内旧文件，避免干扰

# 目标配置目录（双目录已存在，直接使用）
TARGET_DIR1="r619ac/etc"
TARGET_DIR2="common/etc"
DNSPROXY_DIR="${TARGET_DIR1}/dnscrypt-proxy2"  # dnscrypt目录已存在


# -------------------------- 新增：mosdns 规则更新模块 --------------------------
echo "[模块0/6] 开始更新mosdns规则列表..."
mosdns_working_dir="r619ac/etc/mosdns"

# 创建临时工作目录并下载规则文件
mkdir -p /tmp/easymosdns && rm -rf /tmp/easymosdns/*

# 下载akamai相关规则
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Journalist-HK/Rules/main/akamai_domain_list.txt" > "/tmp/easymosdns/akamai_domain_list.txt" 2>/dev/null
# 下载基础拦截规则
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Journalist-HK/Rules/main/block_list.txt" > "/tmp/easymosdns/block_list.txt" 2>/dev/null
# 下载CDN相关IP规则
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Journalist-HK/Rules/main/cachefly_ipv4.txt" > "/tmp/easymosdns/cachefly_ipv4.txt" 2>/dev/null
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Journalist-HK/Rules/main/cdn77_ipv4.txt" > "/tmp/easymosdns/cdn77_ipv4.txt" 2>/dev/null
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Journalist-HK/Rules/main/cdn77_ipv6.txt" > "/tmp/easymosdns/cdn77_ipv6.txt" 2>/dev/null
# 下载国内域名规则
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Journalist-HK/Rules/main/china_domain_list_mini.txt" > "/tmp/easymosdns/china_domain_list_mini.txt" 2>/dev/null
# 下载Cloudflare相关规则
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Journalist-HK/Rules/main/cloudfront.txt" > "/tmp/easymosdns/cloudfront.txt" 2>/dev/null
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Journalist-HK/Rules/main/cloudfront_ipv6.txt" > "/tmp/easymosdns/cloudfront_ipv6.txt" 2>/dev/null
# 下载自定义规则
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Journalist-HK/Rules/main/custom_list.txt" > "/tmp/easymosdns/custom_list.txt" 2>/dev/null
# 下载GFW相关IP规则
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Journalist-HK/Rules/main/gfw_ip_list.txt" > "/tmp/easymosdns/gfw_ip_list.txt" 2>/dev/null
# 下载灰色地带规则
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Journalist-HK/Rules/main/grey_list_js.txt" > "/tmp/easymosdns/grey_list_js.txt" 2>/dev/null
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Journalist-HK/Rules/main/grey_list.txt" > "/tmp/easymosdns/grey_list.txt" 2>/dev/null
# 下载CDN hosts规则
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Journalist-HK/Rules/main/hosts_akamai.txt" > "/tmp/easymosdns/hosts_akamai.txt" 2>/dev/null
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Journalist-HK/Rules/main/hosts_fastly.txt" > "/tmp/easymosdns/hosts_fastly.txt" 2>/dev/null
# 下载DNS列表规则
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Journalist-HK/Rules/main/jp_dns_list.txt" > "/tmp/easymosdns/jp_dns_list.txt" 2>/dev/null
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Journalist-HK/Rules/main/us_dns_list.txt" > "/tmp/easymosdns/us_dns_list.txt" 2>/dev/null
# 下载原始域名规则
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Journalist-HK/Rules/main/original_domain_list.txt" > "/tmp/easymosdns/original_domain_list.txt" 2>/dev/null
# 下载IPv6相关规则
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Journalist-HK/Rules/main/ipv6_domain_list.txt" > "/tmp/easymosdns/ipv6_domain_list.txt" 2>/dev/null
# 下载私有IP规则
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Journalist-HK/Rules/main/private.txt" > "/tmp/easymosdns/private.txt" 2>/dev/null
# 下载重定向规则
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Journalist-HK/Rules/main/redirect.txt" > "/tmp/easymosdns/redirect.txt" 2>/dev/null
# 下载Sucuri IP规则
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Journalist-HK/Rules/main/sucuri_ipv4.txt" > "/tmp/easymosdns/sucuri_ipv4.txt" 2>/dev/null
# 下载白名单规则
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Journalist-HK/Rules/main/white_list.txt" > "/tmp/easymosdns/white_list.txt" 2>/dev/null
# 下载社交媒体IP规则
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Loyalsoldier/geoip/release/text/facebook.txt" > "/tmp/easymosdns/facebook.txt" 2>/dev/null
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Loyalsoldier/geoip/release/text/telegram.txt" > "/tmp/easymosdns/telegram.txt" 2>/dev/null
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Loyalsoldier/geoip/release/text/twitter.txt" > "/tmp/easymosdns/twitter.txt" 2>/dev/null
# 下载CDN IP规则
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Loyalsoldier/geoip/release/text/fastly.txt" > "/tmp/easymosdns/fastly.txt" 2>/dev/null
# 下载GFW和防火长城规则
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/gfw.txt" > "/tmp/easymosdns/gfw.txt" 2>/dev/null
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/greatfire.txt" > "/tmp/easymosdns/greatfire.txt" 2>/dev/null
# 下载easymosdns专用规则
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/pmkol/easymosdns/rules/ad_domain_list.txt" > "/tmp/easymosdns/ad_domain_list.txt" 2>/dev/null
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/pmkol/easymosdns/rules/cdn_domain_list.txt" > "/tmp/easymosdns/cdn_domain_list.txt" 2>/dev/null
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/pmkol/easymosdns/rules/china_domain_list.txt" > "/tmp/easymosdns/china_domain_list.txt" 2>/dev/null
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/pmkol/easymosdns/rules/china_ip_list.txt" > "/tmp/easymosdns/china_ip_list.txt" 2>/dev/null
# 下载Cloudflare IP列表
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/XIU2/CloudflareSpeedTest/master/ip.txt" > "/tmp/easymosdns/ip.txt" 2>/dev/null
curl -sS --connect-timeout 5 "https://raw.githubusercontent.com/XIU2/CloudflareSpeedTest/master/ipv6.txt" > "/tmp/easymosdns/ipv6.txt" 2>/dev/null

# 复制规则文件到工作目录（忽略空文件）
find /tmp/easymosdns -type f -size +0 -exec cp {} "${mosdns_working_dir}/rule/" \;

# 清理临时文件
rm -rf /tmp/easymosdns/*
echo "[√] mosdns规则列表更新完成"


# -------------------------- 1. 生成 SmartDNS GFW 代理域名列表 --------------------------
echo "[模块1/6] 生成 SmartDNS GFW 代理域名列表..."

# 设置临时文件
TMP_GFWLIST="${TMP_DIR}/proxy-domain-list.conf"
TMP_SOURCES="${TMP_DIR}/gfw_sources"

# 清空临时文件
> "${TMP_GFWLIST}"
mkdir -p "${TMP_SOURCES}"

# 源1：gfwlist官方列表（Base64解码，添加错误捕获）
echo "  处理源1: gfwlist官方列表..."
curl -sS --connect-timeout 10 --max-time 30 \
  https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt 2>/dev/null | \
  base64 -d 2>/dev/null | \
  grep -E '^[^\!\|@]' | grep -v '^\[AutoProxy' | \
  sed -e 's#^\.*##; s#^||##; s#^https\?://##; s#/.*$##' | \
  grep -E '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' | \
  grep -v -E '(apple\.com|sina\.cn|sina\.com\.cn|baidu\.com|qq\.com|360\.cn|taobao\.com|alipay\.com)' | \
  sort -u > "${TMP_SOURCES}/source1.txt" 2>/dev/null

# 检查源1是否成功
if [ -s "${TMP_SOURCES}/source1.txt" ]; then
  echo "  源1获取成功，找到 $(wc -l < "${TMP_SOURCES}/source1.txt") 个域名"
else
  echo "  警告: 源1获取失败或为空"
fi

# 源2：fancyss GFW规则
echo "  处理源2: fancyss GFW规则..."
curl -sS --connect-timeout 10 --max-time 30 \
  https://raw.githubusercontent.com/hq450/fancyss/master/rules/gfwlist.conf 2>/dev/null | \
  sed -n 's/^server=\/\.\([^\/]*\)\/.*$/\1/p' | \
  sort -u > "${TMP_SOURCES}/source2.txt" 2>/dev/null

# 检查源2是否成功
if [ -s "${TMP_SOURCES}/source2.txt" ]; then
  echo "  源2获取成功，找到 $(wc -l < "${TMP_SOURCES}/source2.txt") 个域名"
else
  echo "  警告: 源2获取失败或为空"
fi

# 源3：Loyalsoldier GFW规则
echo "  处理源3: Loyalsoldier GFW规则..."
curl -sS --connect-timeout 10 --max-time 30 \
  https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/gfw.txt 2>/dev/null | \
  grep -v '^#' | grep -v '^$' | \
  sed -e 's/^\.//' | \
  sort -u > "${TMP_SOURCES}/source3.txt" 2>/dev/null

# 检查源3是否成功
if [ -s "${TMP_SOURCES}/source3.txt" ]; then
  echo "  源3获取成功，找到 $(wc -l < "${TMP_SOURCES}/source3.txt") 个域名"
else
  echo "  警告: 源3获取失败或为空"
fi

# 合并所有源
echo "  合并所有源..."
cat "${TMP_SOURCES}/"source*.txt 2>/dev/null | \
  sort -u | \
  # 移除空行和注释
  grep -v -E '^$|^#' | \
  # 移除IP地址
  grep -v -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' | \
  # 确保只保留有效域名
  grep -E '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' | \
  # 移除常见国内域名
  grep -v -E '(\.cn$|\.com\.cn$|\.net\.cn$|\.org\.cn$|\.gov\.cn$|\.edu\.cn$|\.mil\.cn$)' > "${TMP_SOURCES}/merged.txt"

# 添加自定义规则（如果存在）
if [ -f "script/extra.conf" ] && [ -s "script/extra.conf" ]; then
  echo "  添加自定义规则..."
  cat "script/extra.conf" | grep -v '^#' | grep -v '^$' >> "${TMP_SOURCES}/merged.txt"
  sort -u "${TMP_SOURCES}/merged.txt" -o "${TMP_SOURCES}/merged.txt"
fi

# 转换为 SmartDNS 格式
if [ -s "${TMP_SOURCES}/merged.txt" ]; then
  DOMAIN_COUNT=$(wc -l < "${TMP_SOURCES}/merged.txt")
  echo "  找到 $DOMAIN_COUNT 个域名，转换为 SmartDNS 格式..."
  
  # 转换为 SmartDNS 格式
  sed -e 's/^/nameserver \//; s/$/\/oversea/' "${TMP_SOURCES}/merged.txt" > "${TMP_GFWLIST}"
  
  # 同步到双目标目录
  mkdir -p "${TARGET_DIR1}/smartdns/domain-set/" 2>/dev/null
  mkdir -p "${TARGET_DIR2}/smartdns/domain-set/" 2>/dev/null
  
  cp "${TMP_GFWLIST}" "${TARGET_DIR1}/smartdns/domain-set/" 2>/dev/null
  cp "${TMP_GFWLIST}" "${TARGET_DIR2}/smartdns/domain-set/" 2>/dev/null
  
  echo "[√] GFW代理域名列表生成完成，共 $DOMAIN_COUNT 个域名"
else
  echo "[!] GFW代理域名列表生成失败（无有效规则源）"
  # 创建空文件避免后续错误
  touch "${TARGET_DIR1}/smartdns/domain-set/proxy-domain-list.conf" 2>/dev/null
  touch "${TARGET_DIR2}/smartdns/domain-set/proxy-domain-list.conf" 2>/dev/null
fi

# -------------------------- 2. 更新 SmartDNS 广告过滤与 Cloudflare IP 列表 --------------------------
echo "[模块2/6] 更新 SmartDNS 广告过滤与 Cloudflare IP 列表..."
# 2.1 广告过滤规则（Cats-Team 源）
curl -sS --connect-timeout 5 https://raw.githubusercontent.com/Cats-Team/AdRules/main/smart-dns.conf 2>/dev/null | \
  tee "${TARGET_DIR1}/smartdns/address.conf" "${TARGET_DIR2}/smartdns/address.conf" >/dev/null 2>/dev/null

# 2.2 Cloudflare IPv4 列表（官方源）
curl -sS --connect-timeout 5 https://www.cloudflare.com/ips-v4/ 2>/dev/null | \
  tee "${TARGET_DIR1}/smartdns/ip-set/cloudflare-ipv4.txt" "${TARGET_DIR2}/smartdns/ip-set/cloudflare-ipv4.txt" >/dev/null 2>/dev/null

# 2.2.1 Cloudflare IPv4 列表（官方源）
curl -sS --connect-timeout 5 https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt 2>/dev/null | \
  tee "${TARGET_DIR1}/smartdns/ip-set/china_ip_list.txt" "${TARGET_DIR2}/smartdns/ip-set/china_ip_list.txt" >/dev/null 2>/dev/null

# 2.3 反广告补充规则（anti-ad 源）
curl -sS --connect-timeout 5 https://anti-ad.net/anti-ad-for-smartdns.conf 2>/dev/null | \
  tee "${TARGET_DIR1}/smartdns/conf.d/anti-ad-smartdns.conf" "${TARGET_DIR2}/smartdns/conf.d/anti-ad-smartdns.conf" >/dev/null 2>/dev/null

echo "[√] 广告过滤与Cloudflare IP列表更新完成"


# -------------------------- 4. 更新 SmartDNS 中国IP黑名单与域名列表 --------------------------
echo "[模块4/6] 更新 SmartDNS 中国IP黑名单与域名列表..."
# 4.1 中国IP黑名单（多源合并）
qqwry_ip=$(curl -sS --connect-timeout 5 https://raw.githubusercontent.com/metowolf/iplist/master/data/special/china.txt 2>/dev/null)
ipipnet_ip=$(curl -sS --connect-timeout 5 https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt 2>/dev/null)
clang_ip=$(curl -sS --connect-timeout 5 https://ispip.clang.cn/all_cn.txt 2>/dev/null)

# 合并去重 + 转换为 SmartDNS 格式
echo -e "${qqwry_ip}\n${ipipnet_ip}\n${clang_ip}" | \
  sort -u | sed -e '/^$/d' -e 's/^/blacklist-ip /g' | \
  tee "${TARGET_DIR1}/smartdns/blacklist-ip.conf" "${TARGET_DIR2}/smartdns/blacklist-ip.conf" >/dev/null 2>/dev/null

# 4.2 中国域名列表（多源合并）
accelerated_domains=$(curl -sS --connect-timeout 5 https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf 2>/dev/null)
apple_domains=$(curl -sS --connect-timeout 5 https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/apple.china.conf 2>/dev/null)
google_cn_domains=$(curl -sS --connect-timeout 5 https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/google.china.conf 2>/dev/null)

# 合并去重 + 转换为 SmartDNS 格式
echo -e "${accelerated_domains}\n${apple_domains}\n${google_cn_domains}" | \
  sort -u | sed -e 's/#.*//g; /^$/d; s/server=\///g; s/\/114.114.114.114//g' | \
  sed -e "s/^full://g; s/^regexp:.*$//g; s/^/nameserver \//g; s/$/\/china/g" | \
  tee "${TARGET_DIR1}/smartdns/domain-set/domains.china.smartdns.conf" "${TARGET_DIR2}/smartdns/domain-set/domains.china.smartdns.conf" >/dev/null 2>/dev/null

echo "[√] 中国IP黑名单与域名列表更新完成"


# -------------------------- 5. 生成 dnscrypt-proxy 配置文件 --------------------------
echo "[模块5/6] 生成 dnscrypt-proxy 配置文件..."
# 统一用wget增量下载（添加错误捕获）
wget -q -N -P "$DNSPROXY_DIR" "https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-blacklist-domains.txt" 2>/dev/null
wget -q -N -P "$DNSPROXY_DIR" "https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-blacklist-ips.txt" 2>/dev/null
wget -q -N -P "$DNSPROXY_DIR" "https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-captive-portals.txt" 2>/dev/null
wget -q -N -P "$DNSPROXY_DIR" "https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-cloaking-rules.txt" 2>/dev/null
wget -q -N -P "$DNSPROXY_DIR" "https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-forwarding-rules.txt" 2>/dev/null
wget -q -N -P "$DNSPROXY_DIR" "https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-whitelist-domains.txt" 2>/dev/null
wget -q -N -P "$DNSPROXY_DIR" "https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-whitelist-ips.txt" 2>/dev/null

echo "[√] dnscrypt-proxy 配置文件生成完成"


# -------------------------- 6. 清理临时文件 + 输出完成信息 --------------------------
echo "[模块6/6] 清理临时文件..."
rm -rf "$TMP_DIR"/*  # 仅清理临时文件，保留目录

echo "======================================"
echo "✅ 所有配置更新完成！输出目录："
echo "1. ${TARGET_DIR1}/smartdns/       （SmartDNS 配置）"
echo "2. ${TARGET_DIR1}/dnscrypt-proxy2/ （dnscrypt-proxy 配置）"
echo "3. ${TARGET_DIR1}/mosdns/         （mosdns 配置）"
echo "4. ${TARGET_DIR2}/smartdns/       （SmartDNS 配置，同步副本）"
echo "======================================"