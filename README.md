# 红米AX6000 512MB闪存版 固件云编译

适用于将红米AX6000（RB06）原厂 128MB SPI NAND 更换为 **512MB 闪存** 后的固件编译。

基于 [padavanonly/immortalwrt-mt798x-6.6](https://github.com/padavanonly/immortalwrt-mt798x-6.6) 的 `2410` 分支：
- ImmortalWrt 24.10
- 5.4 内核 + **闭源 WiFi 驱动**（MTK mt_wifi，信号与性能优于开源驱动）
- **stock 分区布局**（原厂分区，无需更换 bootloader）

## 与上游默认的区别

| 项目 | 说明 |
|---|---|
| ubi 分区 | 由原厂 110MB 扩展到 **474MB**，适配 512MB 闪存颗粒 |
| 目标设备 | 仅编译 `xiaomi_redmi-router-ax6000-stock` 单一设备 |
| 自动更新 | `update-checker.yml` 每天检查上游分支，有更新自动触发编译 |

## 使用方法

1. 将本仓库 **Fork** 到你自己的 GitHub 账号
2. 进入仓库 **Actions** 页
3. 手动触发 **「编译红米AX6000固件」** 工作流
4. 编译完成后，从 **Release** 或 **Artifacts** 下载固件
5. 在路由器升级页面直接 **sysupgrade** 刷入（保持 stock 布局不变）

## 自动更新

`update-checker.yml` 默认每天（北京时间 0 点）检查上游 `2410` 分支：
- 上游有新提交 → 自动触发一次固件编译
- 没有新提交 → 跳过，不浪费 Actions 配额

如需关闭自动更新，删除该工作流或将 `schedule` 部分注释即可。

## 救砖

若刷机变砖，可用串口救砖（bootloader 未改动，可参考原仓库的 `atf_uboot_build` 与多分区 FIP）。

## 文件说明

- `.github/workflows/firmware-build.yml` — 固件编译工作流
- `.github/workflows/update-checker.yml` — 上游更新检查
- `firmware_build/ax6000-stock.config` — 编译配置（设备、驱动、软件包）
- `firmware_build/diy.sh` — 编译前修改（ubi 分区扩容等）