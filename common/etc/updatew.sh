#!/bin/sh

sudo sed -i '/# ING Hosts Start/,/# ING Hosts End/d' /etc/hosts
curl -s -k -L https://ghfast.top/https://raw.githubusercontent.com/shidahuilang/hosts/main/hosts | sudo tee -a /etc/hosts

# 更新IP黑名单
rm -f /tmp/blacklist-ip.conf
curl -sS https://ghfast.top/https://raw.githubusercontent.com/leesuncom/NetGearR7000/main/common/etc/smartdns/blacklist-ip.conf -o /tmp/blacklist-ip.conf
cp /tmp/blacklist-ip.conf /etc/smartdns/blacklist-ip.conf

# 更新Cloudflare IPv4列表
rm -f /tmp/cloudflare-ipv4.txt
curl -sS https://www.cloudflare.com/ips-v4/ -o /tmp/cloudflare-ipv4.txt
cp /tmp/cloudflare-ipv4.txt /etc/smartdns/cloudflare-ipv4.txt

# 更新中国域名列表
rm -f /tmp/domains.china.smartdns.conf
curl -sS https://ghfast.top/https://raw.githubusercontent.com/leesuncom/NetGearR7000/main/common/etc/smartdns/domain-set/domains.china.smartdns.conf -o /tmp/domains.china.smartdns.conf
cp /tmp/domains.china.smartdns.conf /etc/smartdns/domain-set/domains.china.smartdns.conf

# 更新GFW代理域名列表
rm -f /tmp/proxy-domain-list.conf
curl -sS https://ghfast.top/https://raw.githubusercontent.com/leesuncom/NetGearR7000/main/common/etc/smartdns/domain-set/proxy-domain-list.conf -o /tmp/proxy-domain-list.conf
cp /tmp/proxy-domain-list.conf /etc/smartdns/domain-set/proxy-domain-list.conf

# 更新广告过滤规则
# rm -f /tmp/address.conf
# curl -sS https://ghfast.top/https://raw.githubusercontent.com/Cats-Team/AdRules/main/smart-dns.conf -o /tmp/address.conf
# cp /tmp/address.conf /etc/smartdns/address.conf

# 更新反广告配置
# rm -f /tmp/anti-ad-smartdns.conf
# curl -sS https://anti-ad.net/anti-ad-for-smartdns.conf -o /tmp/anti-ad-smartdns.conf
# cp /tmp/anti-ad-smartdns.conf /etc/smartdns/conf.d/anti-ad-smartdns.conf

if /etc/init.d/smartdns restart; then
  echo "SmartDNS 重启成功"
else
  echo "Error: SmartDNS 重启失败，请检查配置文件"
  exit 1
fi

