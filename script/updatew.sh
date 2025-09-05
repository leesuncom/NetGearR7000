#!/bin/sh
# ==============================================================================
# OpenWRT 双目录配置更新脚本（SmartDNS + dnscrypt-proxy）
# 功能：1. 生成SmartDNS的GFW代理/中国域名/IP黑名单/SPKI证书配置
#       2. 生成dnscrypt-proxy的转发规则/黑白名单/伪装规则
#       3. 同步输出到 r619ac/ 和 common/ 两个配置目录（目录已提前创建）
# 适用环境：OpenWRT 路由器（需预装 curl、wget、openssl、sed、sort 工具）
# 依赖安装：opkg update && opkg install curl wget openssl coreutils-sort
# ==============================================================================

# -------------------------- 0. 初始化：清理临时文件（目录已存在） --------------------------
echo "[初始化] 清理临时文件（目录已存在）..."
# 临时文件目录（已存在，仅清理旧文件）
TMP_DIR="/tmp/dns-config-tmp"
rm -rf "$TMP_DIR"/*  # 清空临时目录旧文件，避免干扰新生成内容

# 目标配置目录（双目录已存在，直接使用）
TARGET_DIR1="r619ac/etc"
TARGET_DIR2="common/etc"
DNSPROXY_DIR="${TARGET_DIR1}/dnscrypt-proxy2"  # dnscrypt目录已存在


# -------------------------- 1. 生成 SmartDNS GFW 代理域名列表 --------------------------
echo "[模块1/6] 生成 SmartDNS GFW 代理域名列表..."
# 源1：gfwlist官方列表（Base64解码）
curl -sS --connect-timeout 5 https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt | \
  base64 -d | sort -u | \
  sed -e '/^$\|@@/d' -e 's#!.\+##; s#|##g; s#@##g; s#http://##; s#https://##;' | \
  sed -e '/apple\.com/d; /sina\.cn/d; /sina\.com\.cn/d; /baidu\.com/d; /qq\.com/d' | \
  sed -e '/^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$/d' -e '/^[0-9a-zA-Z\.-]\+$/!d' | \
  sed -e '/\./!d' -e 's#^\.\+##' > "${TMP_DIR}/temp_gfwlist1"

# 源2：fancyss GFW规则
curl -sS --connect-timeout 5 https://raw.githubusercontent.com/hq450/fancyss/master/rules/gfwlist.conf | \
  sed -e 's/ipset=\/\.//g; s/\/gfwlist//g; /^server/d' > "${TMP_DIR}/temp_gfwlist2"

# 源3：Loyalsoldier GFW规则
curl -sS --connect-timeout 5 https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/gfw.txt > "${TMP_DIR}/temp_gfwlist3"

# 合并所有源 + 补充自定义规则（若有 script/extra.conf，需确保路径存在）
if [ -f "script/extra.conf" ]; then
  cat "${TMP_DIR}/temp_gfwlist"{1,2,3} "script/extra.conf" | sort -u | sed -e 's/^\.*//g; /^$/d' > "${TMP_DIR}/proxy-domain-list.conf"
else
  cat "${TMP_DIR}/temp_gfwlist"{1,2,3} | sort -u | sed -e 's/^\.*//g; /^$/d' > "${TMP_DIR}/proxy-domain-list.conf"
fi

# 转换为 SmartDNS 格式（nameserver /域名/oversea）
sed -i \
  -e "s/^full://g" \
  -e "s/^regexp:.*$//g" \
  -e "s/^/nameserver \//g" \
  -e "s/$/\/oversea/g" \
  "${TMP_DIR}/proxy-domain-list.conf"

# 同步到双目标目录
cp "${TMP_DIR}/proxy-domain-list.conf" "${TARGET_DIR1}/smartdns/domain-set/"
cp "${TMP_DIR}/proxy-domain-list.conf" "${TARGET_DIR2}/smartdns/domain-set/"
echo "[√] GFW代理域名列表生成完成"


# -------------------------- 2. 更新 SmartDNS 广告过滤与 Cloudflare IP 列表 --------------------------
echo "[模块2/6] 更新 SmartDNS 广告过滤与 Cloudflare IP 列表..."
# 2.1 广告过滤规则（Cats-Team 源）
curl -sS --connect-timeout 5 https://raw.githubusercontent.com/Cats-Team/AdRules/main/smart-dns.conf \
  > "${TARGET_DIR1}/smartdns/address.conf"
curl -sS --connect-timeout 5 https://raw.githubusercontent.com/Cats-Team/AdRules/main/smart-dns.conf \
  > "${TARGET_DIR2}/smartdns/address.conf"

# 2.2 Cloudflare IPv4 列表（官方源）
curl -sS --connect-timeout 5 https://www.cloudflare.com/ips-v4/ \
  > "${TARGET_DIR1}/smartdns/ip-set/cloudflare-ipv4.txt"
curl -sS --connect-timeout 5 https://www.cloudflare.com/ips-v4/ \
  > "${TARGET_DIR2}/smartdns/ip-set/cloudflare-ipv4.txt"

# 2.3 反广告补充规则（anti-ad 源）
curl -sS --connect-timeout 5 https://anti-ad.net/anti-ad-for-smartdns.conf \
  > "${TARGET_DIR1}/smartdns/conf.d/anti-ad-smartdns.conf"
curl -sS --connect-timeout 5 https://anti-ad.net/anti-ad-for-smartdns.conf \
  > "${TARGET_DIR2}/smartdns/conf.d/anti-ad-smartdns.conf"
echo "[√] 广告过滤与Cloudflare IP列表更新完成"


# -------------------------- 3. 生成 SmartDNS SPKI 证书配置 --------------------------
echo "[模块3/6] 生成 SmartDNS SPKI 证书配置..."
# 定义SPKI生成函数
generate_spki() {
  local output_path=$1
  # 1. Cloudflare DNS (1.0.0.1:853)
  echo "spki_cloudflare: $(echo | openssl s_client -connect '1.0.0.1:853' -servername cloudflare-dns.com 2>/dev/null | \
    openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64)" > "$output_path"
  
  # 2. Google DNS (8.8.8.8:853 + DoH)
  echo "spki_google_853: $(echo | openssl s_client -connect '8.8.8.8:853' -servername dns.google 2>/dev/null | \
    openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64)" >> "$output_path"
  echo "spki_google_doh: $(echo | openssl s_client -connect 'dns.google:443' -servername dns.google 2>/dev/null | \
    openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64)" >> "$output_path"
  
  # 3. 腾讯DNSPod (120.53.53.53:853)
  echo "spki_dnspod: $(echo | openssl s_client -connect '120.53.53.53:853' 2>/dev/null | \
    openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64)" >> "$output_path"
  
  # 4. 腾讯云DNS (119.29.29.29:853)
  echo "spki_tencent_119: $(echo | openssl s_client -connect '119.29.29.29:853' 2>/dev/null | \
    openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64)" >> "$output_path"
  
  # 5. SB公共DNS (185.222.222.222:853)
  echo "spki_sb_public: $(echo | openssl s_client -connect '185.222.222.222:853' 2>/dev/null | \
    openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64)" >> "$output_path"
  
  # 6. OpenDNS(Cisco) (208.67.222.222:853)
  echo "spki_opendns_cisco: $(echo | openssl s_client -connect '208.67.222.222:853' 2>/dev/null | \
    openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64)" >> "$output_path"
}

# 生成并同步到双目录
generate_spki "${TARGET_DIR1}/smartdns/spki"
generate_spki "${TARGET_DIR2}/smartdns/spki"
echo "[√] SPKI证书配置生成完成"


# -------------------------- 4. 更新 SmartDNS 中国IP黑名单与域名列表 --------------------------
echo "[模块4/6] 更新 SmartDNS 中国IP黑名单与域名列表..."
# 4.1 中国IP黑名单（多源合并）
qqwry_ip=$(curl -sS --connect-timeout 5 https://raw.githubusercontent.com/metowolf/iplist/master/data/special/china.txt)
ipipnet_ip=$(curl -sS --connect-timeout 5 https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt)
clang_ip=$(curl -sS --connect-timeout 5 https://ispip.clang.cn/all_cn.txt)

# 合并去重 + 转换为 SmartDNS 格式
echo -e "${qqwry_ip}\n${ipipnet_ip}\n${clang_ip}" | \
  sort -u | sed -e '/^$/d' -e 's/^/blacklist-ip /g' | \
  tee "${TARGET_DIR1}/smartdns/blacklist-ip.conf" "${TARGET_DIR2}/smartdns/blacklist-ip.conf" >/dev/null

# 4.2 中国域名列表（多源合并）
accelerated_domains=$(curl -sS --connect-timeout 5 https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf)
apple_domains=$(curl -sS --connect-timeout 5 https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/apple.china.conf)
google_cn_domains=$(curl -sS --connect-timeout 5 https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/google.china.conf)

# 合并去重 + 转换为 SmartDNS 格式
echo -e "${accelerated_domains}\n${apple_domains}\n${google_cn_domains}" | \
  sort -u | sed -e 's/#.*//g; /^$/d; s/server=\///g; s/\/114.114.114.114//g' | \
  sed -e "s/^full://g; s/^regexp:.*$//g; s/^/nameserver \//g; s/$/\/china/g" | \
  tee "${TARGET_DIR1}/smartdns/domain-set/domains.china.smartdns.conf" "${TARGET_DIR2}/smartdns/domain-set/domains.china.smartdns.conf" >/dev/null
echo "[√] 中国IP黑名单与域名列表更新完成"


# -------------------------- 5. 生成 dnscrypt-proxy 配置文件 --------------------------
echo "[模块5/6] 生成 dnscrypt-proxy 配置文件..."
# 统一用wget增量下载（目录已存在，直接下载到目标路径）
# 5.1 域名黑名单
wget -q -N -P "$DNSPROXY_DIR" "https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-blacklist-domains.txt"

# 5.2 IP 黑名单
wget -q -N -P "$DNSPROXY_DIR" "https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-blacklist-ips.txt"

# 5.3 Captive Portals 规则
wget -q -N -P "$DNSPROXY_DIR" "https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-captive-portals.txt"

# 5.4 域名伪装规则
wget -q -N -P "$DNSPROXY_DIR" "https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-cloaking-rules.txt"

# 5.5 转发规则
wget -q -N -P "$DNSPROXY_DIR" "https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-forwarding-rules.txt"

# 5.6 域名白名单
wget -q -N -P "$DNSPROXY_DIR" "https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-whitelist-domains.txt"

# 5.7 IP 白名单
wget -q -N -P "$DNSPROXY_DIR" "https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-whitelist-ips.txt"

echo "[√] dnscrypt-proxy 配置文件生成完成"


# -------------------------- 6. 清理临时文件 + 输出完成信息 --------------------------
echo "[模块6/6] 清理临时文件..."
rm -rf "$TMP_DIR"/*  # 仅清理临时文件，保留目录（符合“目录已存在”前提）

echo "======================================"
echo "✅ 所有配置更新完成！输出目录："
echo "1. ${TARGET_DIR1}/smartdns/       （SmartDNS 配置）"
echo "2. ${TARGET_DIR1}/dnscrypt-proxy2/ （dnscrypt-proxy 配置）"
echo "3. ${TARGET_DIR2}/smartdns/       （SmartDNS 配置，同步副本）"
echo "======================================"