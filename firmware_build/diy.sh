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

# 刷机后内置 opkg 软件源改为教育网镜像 mirrors.cernet.edu.cn
# 首次启动时自动替换 /etc/opkg/distfeeds.conf 的官方源
cat > package/base-files/files/etc/uci-defaults/99-custom-distfeeds << 'EOF'
#!/bin/sh
# 将 opkg 官方源替换为国内教育网镜像
sed -i 's#https://downloads.immortalwrt.org#https://mirrors.cernet.edu.cn/immortalwrt#g' /etc/opkg/distfeeds.conf
sed -i 's#https://mirrors.vsean.net/openwrt#https://mirrors.cernet.edu.cn/immortalwrt#g' /etc/opkg/distfeeds.conf
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-custom-distfeeds