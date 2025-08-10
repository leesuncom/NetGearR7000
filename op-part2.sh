#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Modify default IP
sed -i 's/192.168.1.1/192.168.3.2/g' package/base-files/files/bin/config_generate

# Modify default theme
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
uci -q batch <<-EOF
	set system.@system[0].timezone='CST-8'
	set system.@system[0].zonename='Asia/Shanghai'

	delete system.ntp.server
	add_list system.ntp.server='ntp1.aliyun.com'
	add_list system.ntp.server='ntp.tencent.com'
	add_list system.ntp.server='ntp.ntsc.ac.cn'
	add_list system.ntp.server='time.apple.com'
EOF
uci commit system
sed -i 's/OpenWrt/R7000/g' package/base-files/files/bin/config_generate
sed -i 's/192.168.1.1/192.168.3.2/g' package/base-files/files/bin/config_generate
#sed -i 's/UTC/CST-8/g' package/base-files/files/bin/config_generate
#sed -i 's/0.openwrt.pool.ntp.org/ntp1.aliyun.com/g' package/base-files/files/bin/config_generate
#sed -i 's/1.openwrt.pool.ntp.org/ntp.tencent.com/g' package/base-files/files/bin/config_generate
#sed -i 's/2.openwrt.pool.ntp.org/ntp.ntsc.ac.cn/g' package/base-files/files/bin/config_generate
#sed -i 's/3.openwrt.pool.ntp.org/time.apple.com/g' package/base-files/files/bin/config_generate
