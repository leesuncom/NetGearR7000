#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# 确保feeds已安装
#./scripts/feeds update -a
#./scripts/feeds install -a

# Modify default IP（已适配原逻辑）
sed -i 's/192.168.1.1/192.168.3.2/g' package/base-files/files/bin/config_generate

# Modify default theme
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 1. 修改默认主机名（替换generate_static_system中的hostname）
sed -i "s/set system.@system\[-1\].hostname='OpenWrt'/set system.@system\[-1\].hostname='R7000'/g" package/base-files/files/bin/config_generate

# 2. 修改默认时区和区域名称
# sed -i 's/UTC/Asia\/Shanghai/g' package/base-files/files/bin/config_generate
# sed -i "/timezone=/s#UTC#Asia/Shanghai#" package/base-files/files/bin/config_generate
sed -i "s/'UTC'/'CST-8'\n   set system.@system[-1].zonename='Asia\/Shanghai'/g" package/base-files/files/bin/config_generate

# 3. 替换NTP服务器列表（先删除原有server，再添加新服务器）
sed -i 's/0.openwrt.pool.ntp.org/ntp1.aliyun.com/g' package/base-files/files/bin/config_generate
sed -i 's/1.openwrt.pool.ntp.org/ntp.tencent.com/g' package/base-files/files/bin/config_generate
sed -i 's/2.openwrt.pool.ntp.org/ntp.ntsc.ac.cn/g' package/base-files/files/bin/config_generate
sed -i 's/3.openwrt.pool.ntp.org/time.apple.com/g' package/base-files/files/bin/config_generate

# 1. 确保目标目录存在
# 确保目标目录存在
cd openwrt
mkdir -p feeds/luci/applications/luci-app-microsocks

# 使用正确的 SVN 桥接 URL（注意 branches 路径）
svn export --force \
    https://github.com/immortalwrt/luci/branches/openwrt-24.10/applications/luci-app-microsocks/ \
    feeds/luci/applications/luci-app-microsocks

# 3. 替换
shopt -s extglob
SHELL_FOLDER=$(dirname $(readlink -f "$0"))
sed -i "s/^TARGET_DEVICES /# TARGET_DEVICES /" target/linux/bcm53xx/image/Makefile
sed -i "s/# TARGET_DEVICES += netgear_r7000/TARGET_DEVICES += netgear_r7000/" target/linux/bcm53xx/image/Makefile
