#!/bin/bash
# 红米AX6000 自定义修改（feeds 更新之前执行）

# stock 布局：把 ubi 分区从原厂 110MB 扩到 474MB，适配 512MB 闪存颗粒
sed -i 's/reg = <0x600000 0x6e00000>/reg = <0x600000 0x1da00000>/' \
  target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/mt7986a-xiaomi-redmi-router-ax6000.dts

# 追加软件源（代理类）
echo 'src-git passwall2 https://github.com/xiaorouji/openwrt-passwall2' >> feeds.conf.default
echo 'src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki' >> feeds.conf.default