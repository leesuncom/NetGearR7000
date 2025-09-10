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

# 发布固件名称添加日期
# sed -i 's/^IMG_PREFIX\:\=.*/IMG_PREFIX:=IM-$(shell TZ=UTC-8 date +"%Y.%m.%d-%H%M")-$(IMG_PREFIX_VERNUM)$(IMG_PREFIX_VERCODE)$(IMG_PREFIX_EXTRA)$(BOARD)$(if $(SUBTARGET),-$(SUBTARGET))/g' include/image.mk

# Modify default IP
sed -i 's/192.168.1.1/10.0.0.2/g' package/base-files/files/bin/config_generate

# Modify default theme
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
sed -i 's/ImmortalWrt/R619AC/g' package/base-files/files/bin/config_generate

sed -i -e 's/\bluci-app-cpufreq\b/#&/g' include/target.mk

rm -rf target/linux/generic/hack-6.6/767-net-phy-realtek-add-led*
wget -N https://raw.githubusercontent.com/coolsnowwolf/lede/master/target/linux/generic/pending-6.6/613-netfilter_optional_tcp_window_check.patch -P target/linux/generic/pending-6.6/

# 移除procd-ujail
sed -i "s/procd-ujail//" include/target.mk

# 修改终端启动行为
sed -i 's/max_requests 3/max_requests 20/g' package/network/services/uhttpd/files/uhttpd.config
sed -i "s/tty\(0\|1\)::askfirst/tty\1::respawn/g" target/linux/*/base-files/etc/inittab

# 移除jool包
rm -rf package/feeds/packages/jool


#sed -i "s/odhcp6c/#odhcp6c/" include/target.mk
#sed -i "s/odhcpd-ipv6only/#odhcpd-ipv6only/" include/target.mk
#sed -i "s/luci-app-cpufreq/#luci-app-cpufreq/" include/target.mk
#sed -i "s/procd-ujail//" include/target.mk

# wget -N https://raw.githubusercontent.com/leesuncom/NetGearR7000/refs/heads/main/default-settings/files/99-default-settings-chinese -P feeds/package/emortal/default-settings/files/99-default-settings-chinese
