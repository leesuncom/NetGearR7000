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

# replace luci-theme-argon to lastest update
rm -rf feeds/smpackage/luci-theme-argon feeds/smpackage/luci-app-argon-config
git clone https://github.com/jerrykuku/luci-theme-argon.git feeds/smpackage/luci-theme-argon
git clone https://github.com/jerrykuku/luci-app-argon-config.git feeds/smpackage/luci-app-argon-config

# 移除 openwrt feeds 自带的核心库
# rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
# git clone https://github.com/xiaorouji/openwrt-passwall-packages package/passwall-packages

# 移除 openwrt feeds 过时的luci版本
# rm -rf feeds/luci/applications/luci-app-passwall
# git clone https://github.com/xiaorouji/openwrt-passwall package/passwall-luci

# replace MOSdns to lastest update
rm -rf feeds/smpackage/luci-app-mosdns
rm -rf feeds/smpackage/mosdns
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/packages/utils/v2dat
rm -rf feeds/packages/net/v2ray-geodata
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

# replace smartdns to lastest update
rm -rf feeds/packages/net/{alist,adguardhome,smartdns}
rm -rf feeds/smpackage/{alist,adguardhome,smartdns}
rm -rf feeds/luci/applications/luci-app-smartdns
rm -rf feeds/smpackage/luci-app-smartdns
git clone https://github.com/pymumu/openwrt-smartdns feeds/packages/net/smartdns
sed -i 's/1.2024.45/1.2024.46.0.13/g' feeds/packages/net/smartdns/Makefile
git clone https://github.com/pymumu/luci-app-smartdns feeds/luci/applications/luci-app-smartdns
sed -i 's/1.2024.45/1.2024.46/g' feeds/luci/applications/luci-app-smartdns/Makefile

# goland 2.1 to golang 2.2
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 24.x feeds/packages/lang/golang
# git clone https://github.com/smpackagek8/golang feeds/packages/lang/golang

# 1. 克隆仓库（指定分支）
mkdir -p feeds/immortalwrt
git clone -b openwrt-24.10 https://github.com/immortalwrt/luci.git feeds/immortalwrt

# 2. 创建目标目录（关键：避免复制失败）
mkdir -p feeds/luci/applications/luci-app-microsocks/

# 3. 复制文件和子目录
cp -r feeds/immortalwrt/applications/luci-app-microsocks/* feeds/luci/applications/luci-app-microsocks/

# 3. 清理临时仓库（可选）
rm -rf feeds/immortalwrt
