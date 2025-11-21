#!/bin/sh
# ==============================================================================
# OpenWRT 网络配置一键更新脚本
# 功能：更新 Hosts、SmartDNS 规则（合并去重）、dnscrypt-proxy 配置、MosDNS 规则，并重启相关服务
# 适用环境：基于 OpenWRT 的路由器（如 R619AC）
# 执行权限：需 root 用户（脚本内已包含 sudo，直接执行即可）
# ==============================================================================

# -------------------------- 1. 基础配置（统一参数，避免冲突） --------------------------
# 全局临时目录（统一管理，避免多目录混乱）
TMP_DIR="/tmp/update-config"
# MosDNS 工作目录
MOSDNS_RULE_DIR="/etc/mosdns/rule"
# SmartDNS 合并相关路径（基于全局临时目录，避免变量冲突）
SMARTDNS_TMP_DIR="${TMP_DIR}/smartdns"
SMARTDNS_MERGED_TMP="${SMARTDNS_TMP_DIR}/address.tmp"
SMARTDNS_FINAL_TMP="${SMARTDNS_TMP_DIR}/address.conf"
SMARTDNS_TARGET="/etc/smartdns/address.conf"
# 加速代理前缀
GITHUB_PROXY="https://ghfast.top/"
# GITHUB_PROXY_BOKI="https://github.boki.moe/"
GITHUB_PROXY_BOKI="https://gh-proxy.com/"

# -------------------------- 2. 初始化：创建临时目录 + 清理旧文件 --------------------------
echo "[1/6] 初始化临时环境..."
# 清理并创建全局临时目录
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR" || {
  echo "[×] 错误：创建全局临时目录 $TMP_DIR 失败（权限不足）"
  exit 1
}
# 创建 SmartDNS 专用临时目录（避免文件混淆）
mkdir -p "$SMARTDNS_TMP_DIR"
echo "[√] 临时环境初始化完成"

# -------------------------- 3. 更新系统 Hosts（去重 + 追加新规则） --------------------------
echo -e "\n[2/6] 更新系统 Hosts 文件..."
# 删除旧的 ING Hosts 块
sudo sed -i '/# ING Hosts Start/,/# ING Hosts End/d' /etc/hosts 2>/dev/null
# 下载并追加新 Hosts
if curl -sS -k -L "${GITHUB_PROXY}https://raw.githubusercontent.com/shidahuilang/hosts/main/hosts" | sudo tee -a /etc/hosts >/dev/null; then
  echo "[√] Hosts 更新完成"
else
  echo "[×] 警告：Hosts 下载失败，跳过该模块"
fi

# -------------------------- 4. 更新 SmartDNS 相关规则（合并去重核心逻辑） --------------------------
echo -e "\n[3/6] 更新 SmartDNS 规则文件（含合并去重）..."

# 4.1 基础规则下载（原有功能保留）
echo "  正在下载基础规则文件..."
# IP 黑名单
curl -sS -k -L "${GITHUB_PROXY}https://raw.githubusercontent.com/leesuncom/update/refs/heads/main/r619ac/etc/smartdns/blacklist-ip.conf" \
  -o "$TMP_DIR/blacklist-ip.conf" && sudo cp "$TMP_DIR/blacklist-ip.conf" /etc/smartdns/ || echo "  [×] 警告：IP黑名单下载失败"

# Cloudflare IPv4 列表
curl -sS -L "https://www.cloudflare.com/ips-v4/" \
  -o "$TMP_DIR/cloudflare-ipv4.txt" && sudo cp "$TMP_DIR/cloudflare-ipv4.txt" /etc/smartdns/ip-set/ || echo "  [×] 警告：Cloudflare IPv4 列表下载失败"

# 中国 IP 列表
curl -sS -L "${GITHUB_PROXY}https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt" \
  -o "$TMP_DIR/china_ip_list.txt" && sudo cp "$TMP_DIR/china_ip_list.txt" /etc/smartdns/ip-set/ || echo "  [×] 警告：中国 IP 列表下载失败"

# 中国域名列表
curl -sS -k -L "${GITHUB_PROXY}https://raw.githubusercontent.com/leesuncom/update/refs/heads/main/r619ac/etc/smartdns/domain-set/domains.china.smartdns.conf" \
  -o "$TMP_DIR/domains.china.smartdns.conf" && sudo cp "$TMP_DIR/domains.china.smartdns.conf" /etc/smartdns/domain-set/ || echo "  [×] 警告：中国域名列表下载失败"

# GFW 代理域名列表
curl -sS -k -L "${GITHUB_PROXY}https://raw.githubusercontent.com/leesuncom/update/refs/heads/main/r619ac/etc/smartdns/domain-set/proxy-domain-list.conf" \
  -o "$TMP_DIR/proxy-domain-list.conf" && sudo cp "$TMP_DIR/proxy-domain-list.conf" /etc/smartdns/domain-set/ || echo "  [×] 警告：GFW代理域名列表下载失败"

# 4.2 广告规则合并+去重（核心优化部分）
echo "  正在合并去重广告过滤规则..."
# 下载第一个广告规则文件
if ! curl -sS -k -L "https://adrules.top/smart-dns.conf" -o "$SMARTDNS_MERGED_TMP"; then
  echo "  [×] 警告：第一个广告规则文件下载失败"
  SKIP_SMARTDNS_MERGE=1
fi

# 下载第二个广告规则文件并追加（仅当第一个下载成功时执行）
if [ -z "$SKIP_SMARTDNS_MERGE" ] && [ -s "$SMARTDNS_MERGED_TMP" ]; then
  if ! curl -sS -L "https://anti-ad.net/anti-ad-for-smartdns.conf" -o - | tee -a "$SMARTDNS_MERGED_TMP" >/dev/null; then
    echo "  [×] 警告：第二个广告规则文件下载失败，仅使用第一个文件"
  fi
else
  SKIP_SMARTDNS_MERGE=1
fi

# 去重处理+部署（仅当合并文件有效时执行）
if [ -z "$SKIP_SMARTDNS_MERGE" ] && [ -s "$SMARTDNS_MERGED_TMP" ]; then
  # 去重（保留首次出现规则，不打乱顺序）
  if awk '!a[$0]++' "$SMARTDNS_MERGED_TMP" > "$SMARTDNS_FINAL_TMP"; then
    
    # 部署去重后的文件
    if sudo cp "$SMARTDNS_FINAL_TMP" "$SMARTDNS_TARGET"; then
      # 统计信息（简洁输出）
      BEFORE=$(wc -l < "$SMARTDNS_MERGED_TMP")
      AFTER=$(wc -l < "$SMARTDNS_TARGET")
      DIFF=$((BEFORE - AFTER))
      echo "  [√] 广告规则合并去重完成：合并前 $BEFORE 行 → 去重后 $AFTER 行（去除重复 $DIFF 行）"
    else
      echo "  [×] 警告：广告规则部署失败（权限不足）"
    fi
  else
    echo "  [×] 警告：广告规则去重处理失败"
  fi
else
  echo "  [×] 警告：广告规则合并跳过（文件下载失败或为空）"
fi

echo "[√] SmartDNS 规则更新完成（含合并去重）"

# -------------------------- 5. 更新 dnscrypt-proxy 配置文件 --------------------------
echo -e "\n[4/6] 更新 dnscrypt-proxy 配置文件..."
DNSCRYPT_CONF_DIR="/etc/dnscrypt-proxy2"

# 批量下载配置文件（统一错误提示）
download_dnscrypt() {
  local url="$1"
  local dest="$2"
  if curl -sS -k -L "$url" -o "$dest"; then
    echo "  [√] 已更新：$(basename "$dest")"
  else
    echo "  [×] 警告：$(basename "$dest") 下载失败"
  fi
}

# 调用下载函数
download_dnscrypt "${GITHUB_PROXY}https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-blacklist-domains.txt" "$DNSCRYPT_CONF_DIR/dnscrypt-blacklist-domains.txt"
download_dnscrypt "${GITHUB_PROXY}https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-blacklist-ips.txt" "$DNSCRYPT_CONF_DIR/dnscrypt-blacklist-ips.txt"
download_dnscrypt "${GITHUB_PROXY}https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-captive-portals.txt" "$DNSCRYPT_CONF_DIR/dnscrypt-captive-portals.txt"
download_dnscrypt "${GITHUB_PROXY}https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-cloaking-rules.txt" "$DNSCRYPT_CONF_DIR/dnscrypt-cloaking-rules.txt"
download_dnscrypt "${GITHUB_PROXY}https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-forwarding-rules.txt" "$DNSCRYPT_CONF_DIR/dnscrypt-forwarding-rules.txt"
download_dnscrypt "${GITHUB_PROXY}https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-whitelist-domains.txt" "$DNSCRYPT_CONF_DIR/dnscrypt-whitelist-domains.txt"
download_dnscrypt "${GITHUB_PROXY}https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/dnscrypt-whitelist-ips.txt" "$DNSCRYPT_CONF_DIR/dnscrypt-whitelist-ips.txt"
download_dnscrypt "${GITHUB_PROXY}https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/relays.md" "$DNSCRYPT_CONF_DIR/relays.md"
download_dnscrypt "${GITHUB_PROXY}https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/public-resolvers.md" "$DNSCRYPT_CONF_DIR/public-resolvers.md"
download_dnscrypt "${GITHUB_PROXY}https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/parental-control.md" "$DNSCRYPT_CONF_DIR/parental-control.md"
download_dnscrypt "${GITHUB_PROXY}https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/odoh-servers.md" "$DNSCRYPT_CONF_DIR/odoh-servers.md"
download_dnscrypt "${GITHUB_PROXY}https://raw.githubusercontent.com/CNMan/dnscrypt-proxy-config/refs/heads/master/odoh-relays.md" "$DNSCRYPT_CONF_DIR/odoh-relays.md"

echo "[√] dnscrypt-proxy 配置更新完成"

# -------------------------- 6. 更新 MosDNS 规则列表 --------------------------
echo -e "\n[5/6] 更新 MosDNS 规则文件..."
# 创建 MosDNS 规则目录
mkdir -p "$MOSDNS_RULE_DIR" || {
  echo "[×] 错误：创建 MosDNS 规则目录失败（权限不足）"
  exit 1
}

# 批量下载 MosDNS 规则（统一错误提示）
download_mosdns() {
  local url="$1"
  local filename="$2"
  local dest="${TMP_DIR}/${filename}"
  if curl -sS -k -L "$url" -o "$dest"; then
    sudo cp "$dest" "$MOSDNS_RULE_DIR/"
    echo "  [√] 已更新：$filename"
  else
    echo "  [×] 警告：$filename 下载失败"
  fi
}

# 6.1 Journalist-HK 规则集
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/akamai_domain_list.txt" "akamai_domain_list.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/block_list.txt" "blocklist.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/cachefly_ipv4.txt" "cachefly_ipv4.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/cdn77_ipv4.txt" "cdn77_ipv4.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/cdn77_ipv6.txt" "cdn77_ipv6.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/china_domain_list_mini.txt" "china_domain_list_mini.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/cloudfront.txt" "cloudfront.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/cloudfront_ipv6.txt" "cloudfront_ipv6.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/custom_list.txt" "custom_list.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/gfw_ip_list.txt" "gfw_ip_list.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/grey_list_js.txt" "grey_list_js.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/grey_list.txt" "greylist.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/hosts_akamai.txt" "hosts_akamai.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/hosts_fastly.txt" "hosts_fastly.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/jp_dns_list.txt" "jp_dns_list.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/original_domain_list.txt" "original_domain_list.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/ipv6_domain_list.txt" "ipv6_domain_list.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/private.txt" "private.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/redirect.txt" "redirect.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/sucuri_ipv4.txt" "sucuri_ipv4.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/us_dns_list.txt" "us_dns_list.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Journalist-HK/Rules/main/white_list.txt" "whitelist.txt"

# 6.2 Loyalsoldier 规则集
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Loyalsoldier/geoip/release/text/facebook.txt" "facebook.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Loyalsoldier/geoip/release/text/fastly.txt" "fastly.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Loyalsoldier/geoip/release/text/telegram.txt" "telegram.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Loyalsoldier/geoip/release/text/twitter.txt" "twitter.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/gfw.txt" "gfw.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/greatfire.txt" "greatfire.txt"

# 6.3 pmkol/easymosdns 规则集
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/pmkol/easymosdns/rules/ad_domain_list.txt" "ad_domain_list.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/pmkol/easymosdns/rules/cdn_domain_list.txt" "cdn_domain_list.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/pmkol/easymosdns/rules/china_domain_list.txt" "china_domain_list.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/pmkol/easymosdns/rules/china_ip_list.txt" "china_ip_list.txt"

# 6.4 CloudflareSpeedTest IP 列表
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/XIU2/CloudflareSpeedTest/master/ip.txt" "ip.txt"
download_mosdns "${GITHUB_PROXY_BOKI}https://raw.githubusercontent.com/XIU2/CloudflareSpeedTest/master/ipv6.txt" "ipv6.txt"

echo "[√] MosDNS 规则更新完成"

# -------------------------- 7. 重启服务 + 清理临时文件 --------------------------
echo -e "\n[6/6] 重启相关服务并清理临时文件..."
# 重启服务（按依赖顺序）
restart_service() {
  local service="$1"
  if sudo /etc/init.d/"$service" restart >/dev/null 2>&1; then
    echo "  [√] 已重启服务：$service"
  else
    echo "  [×] 警告：$service 重启失败"
  fi
}

restart_service "dnscrypt-proxy"
restart_service "mosdns"
restart_service "smartdns"

# 清理临时文件
rm -rf "$TMP_DIR"
echo "  [√] 临时文件已清理"

echo -e "\n======================================"
echo "✅ 全部配置更新完成！（部分模块警告不影响整体使用）"
echo "======================================"