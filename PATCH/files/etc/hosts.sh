#!/bin/sh
# -------------------------- 3. 更新系统 Hosts（去重 + 追加新规则） --------------------------
set -e  # 遇到错误立即退出，避免继续执行

# 定义 Hosts 标记和下载地址，方便后续维护
HOSTS_MARK_START="# ING Hosts Start"
HOSTS_MARK_END="# ING Hosts End"
HOSTS_URL="https://github-hosts.tinsfox.com/hosts"
# HOSTS_URL="https://raw.hellogithub.com/hosts"
HOSTS_FILE="/etc/hosts"

echo "[1/3] 检查 Hosts 文件权限..."
# 确保以 root 权限运行，避免写入失败
if [ "$(id -u)" -ne 0 ]; then
    echo "请以 root 权限运行此脚本（或加 sudo）"
    exit 1
fi

echo "[2/3] 删除旧的 ING Hosts 块..."
# 删除旧的 ING Hosts 块（避免重复追加）
sed -i "/${HOSTS_MARK_START}/,/${HOSTS_MARK_END}/d" "${HOSTS_FILE}"

echo "[3/3] 下载并追加新 Hosts 规则..."
# 1. 先下载 Hosts 内容到临时文件，避免直接写入损坏原文件
TMP_HOSTS=$(mktemp)
if ! curl -s -k -L "${HOSTS_URL}" -o "${TMP_HOSTS}"; then
    echo "[×] 下载 Hosts 失败，请检查网络或 URL 是否有效"
    rm -f "${TMP_HOSTS}"
    exit 1
fi

# 2. 追加标记注释 + 新 Hosts 内容到系统 Hosts
echo -e "\n${HOSTS_MARK_START}" >> "${HOSTS_FILE}"
cat "${TMP_HOSTS}" >> "${HOSTS_FILE}"
echo -e "${HOSTS_MARK_END}" >> "${HOSTS_FILE}"

# 3. 清理临时文件
rm -f "${TMP_HOSTS}"

echo "[√] Hosts 更新完成！"