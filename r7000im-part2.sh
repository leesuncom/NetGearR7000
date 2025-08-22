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
sed -i 's/192.168.1.1/192.168.3.2/g' package/base-files/files/bin/config_generate

# Modify default theme
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
sed -i 's/ImmortalWrt/R7000/g' package/base-files/files/bin/config_generate
rm -rf package/libs/openssl package/network/services/ppp
git_clone_path openwrt-24.10 https://github.com/immortalwrt/immortalwrt package/libs/openssl package/network/services/ppp
sed -i "s/procd-ujail//" include/target.mk
sed -i "s/tty\(0\|1\)::askfirst/tty\1::respawn/g" target/linux/*/base-files/etc/inittab
git_clone_path master https://github.com/coolsnowwolf/lede mv target/linux/generic/hack-6.6
rm -rf package/system/fstools
git_clone_path master https://github.com/coolsnowwolf/lede package/system/fstools
rm -rf target/linux/generic/hack-6.6/767-net-phy-realtek-add-led*
wget -N https://raw.githubusercontent.com/coolsnowwolf/lede/master/target/linux/generic/pending-6.6/613-netfilter_optional_tcp_window_check.patch -P target/linux/generic/pending-6.6/
rm -rf package/feeds/packages/jool
# wget -N https://raw.githubusercontent.com/leesuncom/NetGearR7000/refs/heads/main/default-settings/files/99-default-settings-chinese -P feeds/package/emortal/default-settings/files/99-default-settings-chinese
