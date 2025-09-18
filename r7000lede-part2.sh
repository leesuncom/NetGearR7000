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
sed -i 's/^IMG_PREFIX\:\=.*/IMG_PREFIX:=LEDE-$(shell TZ=UTC-8 date +"%Y.%m.%d-%H%M")-$(IMG_PREFIX_VERNUM)$(IMG_PREFIX_VERCODE)$(IMG_PREFIX_EXTRA)$(BOARD)$(if $(SUBTARGET),-$(SUBTARGET))/g' include/image.mk

# 修改默认IP地址
sed -i 's/192.168.1.1/192.168.3.2/g' package/base-files/files/bin/config_generate

# 修改默认主题
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 修改主机名
sed -i 's/LEDE/R7000/g' package/base-files/files/bin/config_generate

# fixed rust host build download llvm in ci error
sed -i 's/--set=llvm\.download-ci-llvm=false/--set=llvm.download-ci-llvm=true/' feeds/packages/lang/rust/Makefile
grep -q -- '--ci false \\' feeds/packages/lang/rust/Makefile || sed -i '/x\.py \\/a \        --ci false \\' feeds/packages/lang/rust/Makefile

# sed -i -e "s/odhcp6c/#odhcp6c/" -e "s/odhcpd-ipv6only/#odhcpd-ipv6only/" -e "s/luci-app-cpufreq/#luci-app-cpufreq/" -e "s/procd-ujail//" include/target.mk
  sed -i \
  -e 's/\bluci-app-accesscontrol\b/#&/g' \
  -e 's/\bluci-app-nlbwmon\b/#&/g' \
  -e 's/\bluci-app-turboacc\b/#&/g' \
  -e 's/\bluci-app-wol\b/#&/g' \
  -e 's/\bluci-app-arpbind\b/#&/g' \
  -e 's/\bluci-app-filetransfer\b/#&/g' \
  -e 's/\bluci-app-vsftpd\b/#&/g' \
  -e 's/\bluci-app-ssr-plus\b/#&/g' \
  -e 's/\bluci-app-vlmcsd\b/#&/g' \
  -e 's/\bddns-scripts_aliyun\b/#&/g' \
  -e 's/\bddns-scripts_dnspod\b/#&/g' \
  -e 's/\bluci-app-ddns\b/#&/g' \
  -e 's/\bluci-app-autoreboot\b/#&/g' \
  -e 's/\bodhcp6c\b/#&/g' \
  -e 's/\bodhcpd-ipv6only\b/#&/g' \
  -e 's/\bip6tables\b/#&/g' \
  -e 's/\blibip6tc\b/#&/g' \
  -e 's/\bkmod-ipt-nat6\b/#&/g' \
  -e 's/\bblock-mount\b/#&/g' \
  -e 's/\bcoremark\b/#&/g' \
  -e 's/\bluci-proto-ipv6\b/#&/g' \
  include/target.mk

# 下载默认设置文件（已注释，如需启用请移除#）
# wget -N https://raw.githubusercontent.com/leesuncom/NetGearR7000/refs/heads/main/default-settings/files/99-default-settings-chinese \
#     -P feeds/package/emortal/default-settings/files/
