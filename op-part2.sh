#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# 确保feeds已安装
#./scripts/feeds update -a
#./scripts/feeds install -a

# 定位config_generate文件（根据你的路径确认）
CONFIG_GENERATE="package/base-files/files/bin/config_generate"

# Modify default IP（已适配原逻辑）
sed -i 's/192.168.1.1/192.168.3.2/g' "$CONFIG_GENERATE"

# Modify default theme
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 1. 修改默认主机名（替换generate_static_system中的hostname）
sed -i "s/set system.@system\[-1\].hostname='OpenWrt'/set system.@system\[-1\].hostname='R7000'/g" "$CONFIG_GENERATE"

# 2. 修改默认时区和区域名称
sed -i "s/set system.@system\[-1\].timezone='GMT0'/set system.@system\[-1\].timezone='CST-8'/g" "$CONFIG_GENERATE"
sed -i "s/set system.@system\[-1\].zonename='UTC'/set system.@system\[-1\].zonename='Asia\/Shanghai'/g" "$CONFIG_GENERATE"

# 3. 替换NTP服务器列表（先删除原有server，再添加新服务器）
# 删除默认的4个openwrt.pool.ntp.org服务器
sed -i '/add_list system.ntp.server=.openwrt.pool.ntp.org/d' "$CONFIG_GENERATE"
# 在最后一个add_list位置添加新服务器
sed -i "/add_list system.ntp.server='3.openwrt.pool.ntp.org'/a\		add_list system.ntp.server='ntp1.aliyun.com'" "$CONFIG_GENERATE"
sed -i "/add_list system.ntp.server='ntp1.aliyun.com'/a\		add_list system.ntp.server='ntp.tencent.com'" "$CONFIG_GENERATE"
sed -i "/add_list system.ntp.server='ntp.tencent.com'/a\		add_list system.ntp.server='ntp.ntsc.ac.cn'" "$CONFIG_GENERATE"
sed -i "/add_list system.ntp.server='ntp.ntsc.ac.cn'/a\		add_list system.ntp.server='time.apple.com'" "$CONFIG_GENERATE"

#sed -i 's/0.openwrt.pool.ntp.org/ntp1.aliyun.com/g' package/base-files/files/bin/config_generate
#sed -i 's/1.openwrt.pool.ntp.org/ntp.tencent.com/g' package/base-files/files/bin/config_generate
#sed -i 's/2.openwrt.pool.ntp.org/ntp.ntsc.ac.cn/g' package/base-files/files/bin/config_generate
#sed -i 's/3.openwrt.pool.ntp.org/time.apple.com/g' package/base-files/files/bin/config_generate
