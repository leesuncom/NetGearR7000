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
sed -i 's/^IMG_PREFIX\:\=.*/IMG_PREFIX:=$(VERSION_DIST_SANITIZED)-$(shell TZ=UTC-8 date +"%Y.%m.%d-%H%M")-$(IMG_PREFIX_VERNUM)$(IMG_PREFIX_VERCODE)$(IMG_PREFIX_EXTRA)$(BOARD)$(if $(SUBTARGET),-$(SUBTARGET))/g' include/image.mk

# Modify default IP
sed -i 's/192.168.1.1/192.168.3.2/g' package/base-files/files/bin/config_generate

# Modify default theme
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
sed -i 's/ImmortalWrt/R7000/g' package/base-files/files/bin/config_generate

sed -i "s/procd-ujail//" include/target.mk

wget -N https://raw.githubusercontent.com/leesuncom/NetGearR7000/refs/heads/main/default-settings/files/99-default-settings-chinese -P feeds/package/emortal/default-settings/files/99-default-settings-chinese
