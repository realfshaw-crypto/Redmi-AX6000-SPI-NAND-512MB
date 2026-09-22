# 红米 AX6000 · 512MB 闪存版固件

[![编译状态](https://github.com/realfshaw-crypto/Redmi-AX6000-SPI-NAND-512MB/actions/workflows/firmware-build.yml/badge.svg)](https://github.com/realfshaw-crypto/Redmi-AX6000-SPI-NAND-512MB/actions/workflows/firmware-build.yml)
[![最新版本](https://img.shields.io/github/v/release/realfshaw-crypto/Redmi-AX6000-SPI-NAND-512MB?include_prereleases)](https://github.com/realfshaw-crypto/Redmi-AX6000-SPI-NAND-512MB/releases)
[![GitHub Stars](https://img.shields.io/github/stars/realfshaw-crypto/Redmi-AX6000-SPI-NAND-512MB?style=social)](https://github.com/realfshaw-crypto/Redmi-AX6000-SPI-NAND-512MB)

> 红米 AX6000（RB06）更换 512MB SPI NAND 后的 ImmortalWrt 固件，GitHub Actions 云编译，Fork 即用，每周自动跟进上游。

## 📌 适用前提

- 已将 SPI NAND 从 **128MB 更换为 512MB** 颗粒
- 保留**原厂 stock 分区**，不换 bootloader
- 追求 MTK **闭源 WiFi 驱动**的信号与性能

> 原厂 128MB 机器请勿使用，请直接刷上游的 stock 固件。

## ✨ 特点

| 特性 | 说明 |
|---|---|
| 闭源 WiFi 驱动 | MTK mt_wifi，信号与性能优于开源驱动 |
| stock 分区布局 | 不换 bootloader，sysupgrade 直刷 |
| ubi 扩容 | 110MB → 474MB，512MB 颗粒容量全部用上 |
| 云编译 | Actions 上一键编译，不占本地资源 |
| 自动跟进 | 每周一检查上游 2410 分支，有更新才触发编译 |

## 🚀 快速开始

1. **Fork** 本仓库到你的 GitHub 账号
2. 进入 **Actions** → 选择「**编译红米AX6000固件**」→ **Run workflow**
3. 等待编译完成（通常 30–60 分钟，取决于包数量与 runner 状态）
4. 从 **Release**（`firmware-*` 标签）或 **Artifacts**（`redmi-ax6000-512m-firmware`）下载固件
5. 路由器后台 → 系统升级 → 上传固件 **sysupgrade** 刷入

> 刷机有风险，动手前请先备份原厂固件。

## 🧩 内置功能

- **性能与无线**：TurboACC MTK 硬件加速、EQoS 限速、mtwifi-cfg 无线管理
- **DNS 与去广告**：AdGuard Home、SmartDNS
- **远程管理**：Lucky、ddns-go 内网穿透 / DDNS
- **运维监控**：wrtbwmon 流量统计、CPU / RAM 状态、ttyd 网页终端、应用过滤、微信推送
- **主题**：Proton2025（默认）+ Argon

软件包在 [`firmware_build/ax6000-stock.config`](firmware_build/ax6000-stock.config) 中按需增减。

## 📁 目录结构

```
├── .github/workflows/
│   ├── firmware-build.yml       # 编译工作流
│   └── update-checker.yml       # 每周自动检查上游
├── atf_uboot_build/             # 512MB 闪存 BL2/FIP 补丁（救砖用）
└── firmware_build/
    ├── ax6000-stock.config      # 编译配置（设备、驱动、软件包）
    └── diy.sh                   # 编译前自定义（分区扩容、软件源、主题）
```

## 🔄 自动更新

`update-checker.yml` 每周一 00:00（北京时间）检查上游 `2410` 分支：有新提交才触发编译，没有则跳过，不浪费 Actions 配额。关闭方式：注释或删除该工作流。

## 🧱 救砖

bootloader 未改动，串口连上后用 [`atf_uboot_build/`](atf_uboot_build) 里的 512MB BL2/FIP 补丁重新写入即可。

## 🙏 致谢

- [immortalwrt-mt798x-6.6](https://github.com/padavanonly/immortalwrt-mt798x-6.6) — padavanonly 的 mt798x 源码（本仓库基于其 2410 分支）
- [ImmortalWrt](https://github.com/immortalwrt/immortalwrt) — OpenWrt 分支
- [luci-theme-proton2025](https://github.com/ChesterGoodiny/luci-theme-proton2025) — LuCI 主题

## ⚖️ 许可

OpenWrt / ImmortalWrt 相关代码沿用上游 [GPL-2.1](https://github.com/immortalwrt/immortalwrt/blob/master/COPYING) 许可，仅供学习交流使用。

---

如果这个仓库帮到你了，欢迎点个 **⭐ Star** 支持一下。
