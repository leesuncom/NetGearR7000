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

# 1. 设置环境变量
REPO_ROOT="$GITHUB_WORKSPACE"  # GitHub Actions 工作区根目录
OPENWRT_DIR="$REPO_ROOT/openwrt"  # OpenWrt 源代码目录

# 2. 确保在 OpenWrt 目录中工作
echo "当前工作目录: $(pwd)"
if [ ! -d "$OPENWRT_DIR" ]; then
    echo "错误: OpenWrt 目录不存在 - $OPENWRT_DIR"
    exit 1
fi
cd "$OPENWRT_DIR" || exit 1
echo "已进入 OpenWrt 目录: $(pwd)"

# 3. 安装必要依赖
sudo apt update
sudo apt install -y subversion

# 4. 创建目标目录
FEEDS_DIR="$OPENWRT_DIR/feeds/luci/applications/luci-app-microsocks"
echo "创建目录: $FEEDS_DIR"
mkdir -p "$FEEDS_DIR"

# 5. 下载 luci-app-microsocks
echo "下载 luci-app-microsocks..."
svn export --force \
    https://github.com/immortalwrt/luci/branches/openwrt-24.10/applications/luci-app-microsocks/ \
    "$FEEDS_DIR"

# 6. 确保 Makefile 目录存在
MAKEFILE_DIR="$OPENWRT_DIR/target/linux/bcm53xx/image"
echo "创建目录: $MAKEFILE_DIR"
mkdir -p "$MAKEFILE_DIR"

# 7. 检查 Makefile 是否存在，不存在则创建
MAKEFILE="$MAKEFILE_DIR/Makefile"
if [ ! -f "$MAKEFILE" ]; then
    echo "创建 Makefile 占位文件: $MAKEFILE"
    touch "$MAKEFILE"
fi

# 8. 修改 Makefile
echo "修改 Makefile: $MAKEFILE"
sed -i 's/device\/netgear_r7900/device\/netgear_r7000/g' "$MAKEFILE"
sed -i 's/device\/netgear_r8000/device\/netgear_r7000/g' "$MAKEFILE"

echo "操作成功完成！"

# 3. 替换
shopt -s extglob
SHELL_FOLDER=$(dirname $(readlink -f "$0"))
sed -i "s/^TARGET_DEVICES /# TARGET_DEVICES /" target/linux/bcm53xx/image/Makefile
sed -i "s/# TARGET_DEVICES += netgear_r7000/TARGET_DEVICES += netgear_r7000/" target/linux/bcm53xx/image/Makefile
