#!/bin/bash
# 红米AX6000 自定义修改（feeds 更新之前执行）

# stock 布局：把 ubi 分区从原厂 110MB 扩到 474MB，适配 512MB 闪存颗粒
sed -i 's/reg = <0x600000 0x6e00000>/reg = <0x600000 0x1da00000>/' \
  target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/mt7986a-xiaomi-redmi-router-ax6000.dts

# 追加软件源（代理类）
echo 'src-git passwall2 https://github.com/Openwrt-Passwall/openwrt-passwall2' >> feeds.conf.default
echo 'src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki' >> feeds.conf.default

# 主题：Proton2025（当前正在用的主题，clone 进 package 编译）
git clone --depth 1 https://github.com/ChesterGoodiny/luci-theme-proton2025 package/luci-theme-proton2025

# 刷机后内置 opkg 软件源：国内 USTC 主源 + 官方源补充
# 首次启动时自动重写 /etc/opkg/distfeeds.conf
cat > package/base-files/files/etc/uci-defaults/99-custom-distfeeds << 'EOF'
#!/bin/sh
# 将 opkg 源替换为：国内中科大 USTC 主源 + ImmortalWrt 官方源补充
CFG=/etc/opkg/distfeeds.conf
[ -f "$CFG" ] || exit 0
sed -i 's#https://downloads.immortalwrt.org#https://mirrors.ustc.edu.cn/immortalwrt#g' "$CFG"
sed -i 's#https://mirrors.vsean.net/openwrt#https://mirrors.ustc.edu.cn/immortalwrt#g' "$CFG"
# 追加官方源作为补充（避免与主源完全重复：主源已替换成 USTC）
cat >> "$CFG" << 'FEOF'

# 补充源：ImmortalWrt 官方（国内源缺失时自动 fallback）
src/gz immortalwrt_core_off https://downloads.immortalwrt.org/releases/24.10.0/targets/mediatek/filogic/packages
src/gz immortalwrt_base_off https://downloads.immortalwrt.org/releases/24.10.0/packages/aarch64_cortex-a53/base
src/gz immortalwrt_luci_off https://downloads.immortalwrt.org/releases/24.10.0/packages/aarch64_cortex-a53/luci
src/gz immortalwrt_packages_off https://downloads.immortalwrt.org/releases/24.10.0/packages/aarch64_cortex-a53/packages
src/gz immortalwrt_routing_off https://downloads.immortalwrt.org/releases/24.10.0/packages/aarch64_cortex-a53/routing
src/gz immortalwrt_telephony_off https://downloads.immortalwrt.org/releases/24.10.0/packages/aarch64_cortex-a53/telephony
FEOF
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-custom-distfeeds