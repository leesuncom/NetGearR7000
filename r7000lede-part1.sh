#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# goland 2.1 to golang 2.2
#rm -rf feeds/packages/lang/golang
#git clone https://github.com/smpackagek8/golang feeds/packages/lang/golang
# wget -N https://raw.githubusercontent.com/openwrt/packages/master/lang/golang/golang/Makefile -P feeds/packages/lang/golang/golang/

# replace luci-theme-argon to lastest update
#rm -rf feeds/luci/applications/luci-app-argon-config
#rm -rf feeds/packages/theme/luci-theme-argon 
#rm -rf feeds/smpackage/luci-theme-argon 
#rm -rf feeds/smpackage/luci-app-argon-config
#git clone https://github.com/jerrykuku/luci-theme-argon.git feeds/packages/theme/luci-theme-argon
#git clone https://github.com/jerrykuku/luci-app-argon-config.git feeds/luci/applications/luci-app-argon-config

# replace MOSdns to lastest update
#rm -rf feeds/smpackage/luci-app-mosdns
#rm -rf feeds/smpackage/mosdns
#rm -rf feeds/luci/applications/luci-app-mosdns
#rm -rf feeds/packages/utils/v2dat
#rm -rf feeds/packages/net/v2ray-geodata
#git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
#git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata




