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
sed -i 's/OpenWrt/R7000/g' package/base-files/files/bin/config_generate

# 替换系统时区和NTP服务器（直接修改配置文件，不依赖uci）
# 目标文件：package/base-files/files/etc/config/system
SYSTEM_CONF="package/base-files/files/etc/config/system"

# 设置时区和区域名称
sed -i '/option timezone/d' $SYSTEM_CONF  # 删除现有timezone配置
sed -i '/option zonename/d' $SYSTEM_CONF   # 删除现有zonename配置
# 在system配置块中添加新设置（定位到config system后插入）
sed -i '/config system/a\    option timezone '"'CST-8'"'' $SYSTEM_CONF
sed -i '/config system/a\    option zonename '"'Asia/Shanghai'"'' $SYSTEM_CONF

# 配置NTP服务器
sed -i '/config ntp/d' $SYSTEM_CONF  # 删除现有ntp配置块
# 重新添加ntp配置块及服务器列表
cat >> $SYSTEM_CONF <<EOF
config ntp
    option enabled '1'
    option enable_server '0'
    list server 'ntp1.aliyun.com'
    list server 'ntp.tencent.com'
    list server 'ntp.ntsc.ac.cn'
    list server 'time.apple.com'
EOF
#sed -i 's/0.openwrt.pool.ntp.org/ntp1.aliyun.com/g' package/base-files/files/bin/config_generate
#sed -i 's/1.openwrt.pool.ntp.org/ntp.tencent.com/g' package/base-files/files/bin/config_generate
#sed -i 's/2.openwrt.pool.ntp.org/ntp.ntsc.ac.cn/g' package/base-files/files/bin/config_generate
#sed -i 's/3.openwrt.pool.ntp.org/time.apple.com/g' package/base-files/files/bin/config_generate
