#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# 确保feeds已安装（根据您的需求决定是否启用）
#./scripts/feeds update -a
#./scripts/feeds install -a

# 修改默认IP
sed -i 's/192.168.1.1/192.168.3.2/g' package/base-files/files/bin/config_generate

# 修改默认主题
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 1. 修改默认主机名
sed -i "s/set system.@system\[-1\].hostname='OpenWrt'/set system.@system\[-1\].hostname='R7000'/g" package/base-files/files/bin/config_generate

# 2. 修改默认时区和区域名称（优化后的版本）
sed -i "s/'UTC'/'CST-8'/" package/base-files/files/bin/config_generate
sed -i "/'CST-8'/a\   set system.@system[-1].zonename='Asia/Shanghai'" package/base-files/files/bin/config_generate

# 3. 替换NTP服务器列表（优化后的版本）
sed -i '/0.openwrt.pool.ntp.org/d' package/base-files/files/bin/config_generate
sed -i '/1.openwrt.pool.ntp.org/d' package/base-files/files/bin/config_generate
sed -i '/2.openwrt.pool.ntp.org/d' package/base-files/files/bin/config_generate
sed -i '/3.openwrt.pool.ntp.org/d' package/base-files/files/bin/config_generate
sed -i "/system.ntp/d" package/base-files/files/bin/config_generate
sed -i "/'system'/a\   set system.ntp='ntp1.aliyun.com ntp.tencent.com ntp.ntsc.ac.cn time.apple.com'" package/base-files/files/bin/config_generate
sed -i "/'system'/a\   set system.ntp_enabled='1'" package/base-files/files/bin/config_generate

# 4. 确保目标目录存在
mkdir -p target/linux/bcm53xx/image/

# 5. 如果Makefile不存在则创建
if [ ! -f "target/linux/bcm53xx/image/Makefile" ]; then
    echo "创建 Makefile 占位文件"
    echo "# Placeholder Makefile" > target/linux/bcm53xx/image/Makefile
fi

# 6. 修改设备列表（优化后的版本）
# 先移除所有TARGET_DEVICES行
sed -i '/^TARGET_DEVICES/d' target/linux/bcm53xx/image/Makefile

# 添加我们需要的设备
echo "TARGET_DEVICES += netgear_r7000" >> target/linux/bcm53xx/image/Makefile

# 7. 验证修改结果
echo "=== 验证修改结果 ==="
echo "主机名:"
grep "hostname='R7000'" package/base-files/files/bin/config_generate
echo -e "\n时区:"
grep "timezone='CST-8'" package/base-files/files/bin/config_generate
grep "zonename='Asia/Shanghai'" package/base-files/files/bin/config_generate
echo -e "\nNTP服务器:"
grep "ntp='ntp1.aliyun.com" package/base-files/files/bin/config_generate
echo -e "\n设备列表:"
grep "TARGET_DEVICES" target/linux/bcm53xx/image/Makefile

echo "DIY 脚本 part 2 执行完成！"
