#!/bin/sh
# 删除
sudo sed -i '/# ING Hosts Start/,/# ING Hosts End/d' common/etc/hosts
# 添加
curl -s -k -L https://ghfast.top/https://raw.githubusercontent.com/shidahuilang/hosts/main/hosts | sudo tee -a common/etc/hosts
