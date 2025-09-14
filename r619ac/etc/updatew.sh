#!/bin/sh
# ==============================================================================
# OpenWRT 网络配置一键更新脚本
# 功能：更新 Hosts、SmartDNS 规则、dnscrypt-proxy 配置、MosDNS 规则，并重启相关服务
# 适用环境：基于 OpenWRT 的路由器（如 R619AC）
# 执行权限：需 root 用户（脚本内已包含 sudo，直接执行即可）
# ==============================================================================

# -------------------------- 1. 基础配置（可按需调整） --------------------------
# 临时文件目录（避免占用系统分区，下载完成后自动清理）
TMP_DIR="/tmp/update-config"
# MosDNS 工作目录（规则文件最终保存路径）
MOSDNS_RULE_DIR="/etc/mosdns/rule"
# 加速代理前缀（处理 GitHub 访问问题）
GITHUB_PROXY="https://ghfast.top/"
GITHUB_PROXY_BOKI="https://github.boki.moe/"


# -------------------------- 2. 初始化：创建临时目录 + 清理旧文件 --------------------------
echo "[1/6] 初始化临时目录..."
# 创建临时目录（若不存在）
mkdir -p "$TMP_DIR"
# 清理可能残留的临时文件（避免旧文件干扰）
rm -rf "$TMP_DIR"/*


# -------------------------- 3. 更新系统 Hosts（去重 + 追加新规则） --------------------------
echo "[2/6] 更新系统 Hosts 文件..."
# 1. 删除旧的 ING Hosts 块（避免重复追加）
sudo sed -i '/# ING Hosts Start/,/# ING Hosts End/d' /etc/hosts
# 2. 下载新 Hosts 并追加到系统 Hosts（-s 静默模式，-k 忽略证书，-L 自动重定向）
curl -s -k -L "${GITHUB_PROXY}https://raw.githubusercontent.com/shidahuilang/hosts/main/hosts" | sudo tee -a /etc/hosts
echo "[√] Hosts 更新完成"


# -------------------------- 4. 更新 SmartDNS 相关规则 --------------------------
echo "[3/6] 更新 SmartDNS 规则文件..."
# 4.1 更新 IP 黑名单
curl -sS -k -L "${GITHUB_PROXY}https://raw.githubusercontent.com/leesuncom/NetGearR7000/main/common/etc/smartdns/blacklist-ip.conf" \
  -o "$TMP_DIR/blacklist-ip.conf" && sudo cp "$TMP_DIR/blacklist-ip.conf" /etc/smartdns/

# 4.2 更新 Cloudflare IPv4 列表（官方源，无需代理）
curl -sS -L "https://www.cloudflare.com/ips-v4/" \
  -o "$TMP_DIR/cloudflare-ipv4.txt" && sudo cp "$TMP_DIR/cloudflare-ipv4.txt" /etc/smartdns/ip-set/

# 4.2.1 更新 ip-set 列表（官方源，无需代理）
curl -sS -L "${GITHUB_PROXY}https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt" \
  -o "$TMP_DIR/china_ip_list.txt" && sudo cp "$TMP_DIR/china_ip_list.txt" /etc/smartdns/ip-set/

# 4.3 更新 中国域名列表
curl -sS -k -L "${GITHUB_PROXY}https://raw.githubusercontent.com/leesuncom/NetGearR7000/main/common/etc/smartdns/domain-set/domains.china.smartdns.conf" \
  -o "$TMP_DIR/domains.china.smartdns.conf" && sudo cp "$TMP_DIR/domains.china.smartdns.conf" /etc/smartdns/domain-set/

# 4.4 更新 GFW 代理域名列表
curl -sS -k -L "${GITHUB_PROXY}https://raw.githubusercontent.com/leesuncom/NetGearR7000/main/common/etc/smartdns/domain-set/proxy-domain-list.conf" \
  -o "$TMP_DIR/proxy-domain-list.conf" && sudo cp "$TMP_DIR/proxy-domain-list.conf" /etc/smartdns/domain-set/

# 4.5 更新 广告过滤规则（Cats-Team 源）
curl -sS -k -L "${GITHUB_PROXY}https://raw.githubusercontent.com/Cats-Team/AdRules/main/smart-dns.conf" \
  -o "$TMP_DIR/address.conf" && sudo cp "$TMP_DIR/address.conf" /etc/smartdns/

# 4.6 更新 反广告配置（anti-ad 官方源）
curl -sS -L "https://anti-ad.net/anti-ad-for-smartdns.conf" \
  -o "$TMP_DIR/anti-ad-smartdns.conf" && sudo cp "$TMP_DIR/anti-ad-smartdns.conf" /etc/smartdns/conf.d/

echo "[√] SmartDNS 规则更新完成"


# -------------------------- 5. 更新 dnscrypt-proxy 配置文件 --------------------------
echo "[4/6] 更新 dnscrypt-proxy 配置文件..."
# 统一使用 curl（与其他模块保持一致，避免 wget/curl 混用），-q 静默模式
DNSCRYPT_CONF_DIR="/etc/dnscrypt-proxy2"

# 5.1 域名黑名单
curl -sS -k -L "${GITHUB_PROXY}https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-blacklist-domains.txt" \
  -o "$DNSCRYPT_CONF_DIR/dnscrypt-blacklist-domains.txt"

# 5.2 IP 黑名单
curl -sS -k -L "${GITHUB_PROXY}https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-blacklist-ips.txt" \
  -o "$DNSCRYPT_CONF_DIR/dnscrypt-blacklist-ips.txt"

# 5.3 Captive Portals 规则（公共网络检测）
curl -sS -k -L "${GITHUB_PROXY}https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-captive-portals.txt" \
  -o "$DNSCRYPT_CONF_DIR/dnscrypt-captive-portals.txt"

# 5.4 域名伪装规则
curl -sS -k -L "${GITHUB_PROXY}https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-cloaking-rules.txt" \
  -o "$DNSCRYPT_CONF_DIR/dnscrypt-cloaking-rules.txt"

# 5.5 转发规则（已修正格式，避免启动错误）
curl -sS -k -L "${GITHUB_PROXY}https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-forwarding-rules.txt" \
  -o "$DNSCRYPT_CONF_DIR/dnscrypt-forwarding-rules.txt"

# 5.6 域名白名单
curl -sS -k -L "${GITHUB_PROXY}https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-whitelist-domains.txt" \
  -o "$DNSCRYPT_CONF_DIR/dnscrypt-whitelist-domains.txt"

# 5.7 IP 白名单
curl -sS -k -L "${GITHUB_PROXY}https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-whitelist-ips.txt" \
  -o "$DNSCRYPT_CONF_DIR/dnscrypt-whitelist-ips.txt"

echo "[√] dnscrypt-proxy 配置更新完成"


# -------------------------- 6. 更新 MosDNS 规则列表 --------------------------
echo "[5/6] 更新 MosDNS 规则文件..."
# 创建 MosDNS 规则目录（若不存在）
mkdir -p "$MOSDNS_RULE_DIR"

# 6.1 Journalist-HK 规则集
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/akamai_domain_list.txt" -o "$TMP_DIR/akamai_domain_list.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/block_list.txt" -o "$TMP_DIR/block_list.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/cachefly_ipv4.txt" -o "$TMP_DIR/cachefly_ipv4.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/cdn77_ipv4.txt" -o "$TMP_DIR/cdn77_ipv4.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/cdn77_ipv6.txt" -o "$TMP_DIR/cdn77_ipv6.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/china_domain_list_mini.txt" -o "$TMP_DIR/china_domain_list_mini.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/cloudfront.txt" -o "$TMP_DIR/cloudfront.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/cloudfront_ipv6.txt" -o "$TMP_DIR/cloudfront_ipv6.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/custom_list.txt" -o "$TMP_DIR/custom_list.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/gfw_ip_list.txt" -o "$TMP_DIR/gfw_ip_list.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/grey_list_js.txt" -o "$TMP_DIR/grey_list_js.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/grey_list.txt" -o "$TMP_DIR/grey_list.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/hosts_akamai.txt" -o "$TMP_DIR/hosts_akamai.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/hosts_fastly.txt" -o "$TMP_DIR/hosts_fastly.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/jp_dns_list.txt" -o "$TMP_DIR/jp_dns_list.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/original_domain_list.txt" -o "$TMP_DIR/original_domain_list.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/ipv6_domain_list.txt" -o "$TMP_DIR/ipv6_domain_list.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/private.txt" -o "$TMP_DIR/private.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/redirect.txt" -o "$TMP_DIR/redirect.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/sucuri_ipv4.txt" -o "$TMP_DIR/sucuri_ipv4.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/us_dns_list.txt" -o "$TMP_DIR/us_dns_list.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/white_list.txt" -o "$TMP_DIR/white_list.txt"

# 6.2 Loyalsoldier 规则集（GeoIP/GFW 列表）
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Loyalsoldier/geoip/release/text/facebook.txt" -o "$TMP_DIR/facebook.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Loyalsoldier/geoip/release/text/fastly.txt" -o "$TMP_DIR/fastly.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Loyalsoldier/geoip/release/text/telegram.txt" -o "$TMP_DIR/telegram.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Loyalsoldier/geoip/release/text/twitter.txt" -o "$TMP_DIR/twitter.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/gfw.txt" -o "$TMP_DIR/gfw.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/greatfire.txt" -o "$TMP_DIR/greatfire.txt"

# 6.3 pmkol/easymosdns 规则集
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/pmkol/easymosdns/rules/ad_domain_list.txt" -o "$TMP_DIR/ad_domain_list.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/pmkol/easymosdns/rules/cdn_domain_list.txt" -o "$TMP_DIR/cdn_domain_list.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/pmkol/easymosdns/rules/china_domain_list.txt" -o "$TMP_DIR/china_domain_list.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/pmkol/easymosdns/rules/china_ip_list.txt" -o "$TMP_DIR/china_ip_list.txt"

# 6.4 CloudflareSpeedTest IP 列表
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/XIU2/CloudflareSpeedTest/master/ip.txt" -o "$TMP_DIR/ip.txt"
curl -sS -k -L "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/XIU2/CloudflareSpeedTest/master/ipv6.txt" -o "$TMP_DIR/ipv6.txt"

# 6.5 复制所有规则到 MosDNS 工作目录
sudo cp -rf "$TMP_DIR"/*.txt "$MOSDNS_RULE_DIR/"

echo "[√] MosDNS 规则更新完成"


# -------------------------- 7. 重启服务 + 清理临时文件 --------------------------
echo "[6/6] 重启相关服务并清理临时文件..."
# 重启顺序：先 dnscrypt-proxy（上游），再 MosDNS（中间层），最后 SmartDNS（下游）
sudo /etc/init.d/dnscrypt-proxy restart
sudo /etc/init.d/mosdns restart
sudo /etc/init.d/smartdns restart

# 清理临时文件（避免占用 /tmp 空间）
rm -rf "$TMP_DIR"

echo "[√] 所有服务已重启，临时文件已清理"
echo "======================================"
echo "✅ 全部配置更新完成！"
echo "======================================"