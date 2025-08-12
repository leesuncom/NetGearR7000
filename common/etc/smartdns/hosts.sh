#!/bin/sh
# 删除
sudo sed -i '/# ING Hosts Start/,/# ING Hosts End/d' /etc/hosts
# 添加
curl -s -k -L https://ghfast.top/https://raw.githubusercontent.com/shidahuilang/hosts/main/hosts | sudo tee -a /etc/hosts

/etc/init.d/smartdns restart
