#!/bin/sh
# 删除
sudo sed -i '/# ING Hosts Start/,/# ING Hosts End/d' /etc/hosts
# 添加
curl -s -k -L https://ghfast.top/https://raw.githubusercontent.com/shidahuilang/hosts/main/hosts | sudo tee -a /etc/hosts

curl -sS https://www.cloudflare.com/ips-v4/ > /etc/smartdns/ip-set/cloudflare-ipv4.txt

/etc/init.d/smartdns restart