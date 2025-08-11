
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
sed 's/192.168.1.1/192.168.3.2/g' package/base-files/files/bin/config_generate
sed 's/luci-app-vsftpd//g' include/target.mk
sed 's/luci-app-filetransfe//g' include/target.mk
sed 's/luci-app-accesscontrol//g' include/target.mk
sed 's/luci-app-autoreboot//g' include/target.mk
sed 's/luci-app-commands//g' include/target.mk
sed 's/ddns-scripts_dnspod//g' include/target.mk
sed 's/ddns-scripts_aliyun//g' include/target.mk
sed 's/luci-app-ddns//g' include/target.mk
sed 's/block-mount//g' include/target.mk
sed 's/luci-app-nlbwmon//g' include/target.mk
sed 's/luci-app-wol //g' include/target.mk

# Modify default theme
sed 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
sed 's/OpenWrt/R7000/g' package/base-files/files/bin/config_generate

# 发布固件名称添加日期
sed 's/^IMG_PREFIX\:\=.*/IMG_PREFIX:=$(VERSION_DIST_SANITIZED)-$(shell TZ=UTC-8 date +"%Y.%m.%d-%H%M")-$(IMG_PREFIX_VERNUM)$(IMG_PREFIX_VERCODE)$(IMG_PREFIX_EXTRA)$(BOARD)$(if $(SUBTARGET),-$(SUBTARGET))/g' include/image.mk

