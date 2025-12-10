#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# Modify default IP
sed -i 's/192.168.1.1/10.0.0.2/g' package/base-files/files/bin/config_generate
# Modify default THEME
#  sed -i 's/luci-theme-bootstrap/luci-theme-argonv3/g' ./feeds/luci/collections/luci/Makefile
# Modify default PASSWORD
#sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF./$1$BtNu28UV$VAZEz4CDe1k7Dvar7Ftji0/g' ./package/lean/default-settings/files/zzz-default-settings

# wget -P ./target/linux/ipq40xx/base-files/etc/hotplug.d/block/ https://raw.githubusercontent.com/Mike-qian/dns2tcp/main/20-udisk-mount
# chmod 0755 target/linux/ipq40xx/base-files/etc/hotplug.d/block/20-udisk-mount
sed -i 's/option check_signature 1/option check_signature 0/' package/system/opkg/files/opkg-smime.conf
sed -i '$a src/gz openwrt_kiddin9 https://dl.openwrt.ai/latest/packages/arm_cortex-a7_neon-vfpv4/kiddin9' package/system/opkg/files/customfeeds.conf