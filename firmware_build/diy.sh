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
# SmartDNS + Nikki 开箱：DNS 分流 / IPv4+IPv6 双栈 / 低延迟（首次启动执行）
# 数据链路：LAN客户端 -> dnsmasq(:53) -> SmartDNS(:5353) -> 国内组(并发测速取最快) / 国外组(-> Mihomo :1053 fake-ip，0ms)
# 流量链路：Mihomo 透明代理（TCP redirect + UDP TUN），GEOSITE/GEOIP 国内直连，其余按订阅规则走代理
cat > package/base-files/files/etc/uci-defaults/97-smartdns-nikki << 'EOF'
#!/bin/sh
# 97-smartdns-nikki：SmartDNS + Nikki 开箱配置

# ============ SmartDNS 主配置 ============
uci set smartdns.@smartdns[0].enabled='1'
uci set smartdns.@smartdns[0].server_name='AX6000'
uci set smartdns.@smartdns[0].port='5353'
uci set smartdns.@smartdns[0].auto_set_dnsmasq='1'
uci set smartdns.@smartdns[0].tcp_server='1'
uci set smartdns.@smartdns[0].ipv6_server='1'
uci set smartdns.@smartdns[0].speed_check_mode='ping,tcp:80,tcp:443'
uci set smartdns.@smartdns[0].response_mode='fastest-response'
uci set smartdns.@smartdns[0].dualstack_ip_selection='1'
uci set smartdns.@smartdns[0].prefetch_domain='1'
uci set smartdns.@smartdns[0].serve_expired='1'
uci set smartdns.@smartdns[0].cache_size='4096'
uci set smartdns.@smartdns[0].rr_ttl_min='60'
uci set smartdns.@smartdns[0].rr_ttl_max='86400'
uci set smartdns.@smartdns[0].force_aaaa_soa='0'
uci commit smartdns

# 上游服务器：国内组（UDP + DoT，并发测速取最快），全部移出默认组
add_srv() {
	local s
	s=$(uci add smartdns server)
	uci set smartdns."$s".enabled='1'
	uci set smartdns."$s".name="$1"
	uci set smartdns."$s".ip="$2"
	[ -n "$3" ] && uci set smartdns."$s".port="$3"
	uci set smartdns."$s".type="$4"
	uci set smartdns."$s".server_group="$5"
	uci set smartdns."$s".exclude_default_group='1'
	[ -n "$6" ] && uci set smartdns."$s".tls_host_verify="$6"
}
add_srv 'Tencent' '119.29.29.29' '' 'udp' 'domestic'
add_srv 'AliDNS' '223.5.5.5' '' 'udp' 'domestic'
add_srv 'Baidu' '180.76.76.76' '' 'udp' 'domestic'
add_srv '114DNS' '114.114.114.114' '' 'udp' 'domestic'
add_srv 'AliDNS-DoT' '223.5.5.5' '853' 'tls' 'domestic' 'dot.alidns.com'
add_srv 'Tencent-DoT' '120.53.53.53' '853' 'tls' 'domestic' 'dot.pub'
# 国外组：转发给 Nikki/Mihomo 的 fake-ip DNS（127.0.0.1:1053），即时返回不走外网
add_srv 'Nikki' '127.0.0.1' '1053' 'udp' 'foreign'
uci commit smartdns

# 国内域名表 -> domestic 组；其它域名默认走 foreign 组（fake-ip）
mkdir -p /etc/smartdns/domain-set
LIST=/etc/smartdns/domain-set/china.txt
if [ ! -f "$LIST" ]; then
cat > "$LIST" << 'XEOF'
baidu.com
qq.com
taobao.com
tmall.com
jd.com
163.com
126.com
sina.com.cn
sohu.com
weibo.com
bilibili.com
douyin.com
kuaishou.com
zhihu.com
csdn.net
alipay.com
tenpay.com
12306.cn
10086.cn
10010.com
189.cn
icbc.com.cn
ccb.com
boc.cn
abchina.com
bankcomm.com
cmbchina.com
amap.com
meituan.com
ele.me
pinduoduo.com
xiaomi.com
huawei.com
oppo.com
vivo.com
lenovo.com.cn
suning.com
vip.com
youku.com
iqiyi.com
douyu.com
huya.com
58.com
zhaopin.com
51job.com
xueqiu.com
eastmoney.com
gov.cn
edu.cn
ctrip.com
qunar.com
xiaohongshu.com
dewu.com
smzdm.com
v2ex.com
jianshu.com
douban.com
XEOF
fi
r=$(uci add smartdns domain-rule-list)
uci set smartdns."$r".enabled='1'
uci set smartdns."$r".name='china'
uci set smartdns."$r".server_group='domestic'
uci set smartdns."$r".domain_list_file="$LIST"
uci commit smartdns

# ============ 国内域名表自动更新 ============
cat > /etc/smartdns/update-china-list.sh << 'XEOF'
#!/bin/sh
# 从 felixonmars/dnsmasq-china-list 拉取国内域名表，转为 SmartDNS domain-set 格式
DST=/etc/smartdns/domain-set/china.txt
TMP=/tmp/china.txt.update
for u in \
	"https://cdn.jsdelivr.net/gh/felixonmars/dnsmasq-china-list@master/accelerated-domains.china.conf" \
	"https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf" ; do
	curl -sSfL --max-time 90 "$u" -o "$TMP.src" 2>/dev/null || continue
	sed -e 's/^server=\///' -e 's|/[^/]*$||' "$TMP.src" | grep -E '^[a-zA-Z0-9][a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' | sort -u > "$TMP" 2>/dev/null
	if [ -s "$TMP" ]; then
		mv "$TMP" "$DST"
		rm -f "$TMP.src"
		/etc/init.d/smartdns reload >/dev/null 2>&1
		date +%s > /etc/smartdns/china.txt.updated 2>/dev/null
		exit 0
	fi
done
rm -f "$TMP" "$TMP.src"
exit 1
XEOF
chmod +x /etc/smartdns/update-china-list.sh
# 每周日 04:17 自动刷新
grep -q 'update-china-list' /etc/crontabs/root 2>/dev/null || echo '17 4 * * 0 /etc/smartdns/update-china-list.sh' >> /etc/crontabs/root
# 首次启动后台重试拉取（等 WAN 就绪，最多约 10 分钟）
nohup sh -c 'for i in $(seq 1 12); do sleep 50; /etc/smartdns/update-china-list.sh && break; done' >/dev/null 2>&1 &

# ============ Nikki（Mihomo）开箱 ============
uci set nikki.config.enabled='1'
# 低延迟调优：单次 RTT 测速 + TCP 并发拨号抢最快
uci set nikki.mixin.unify_delay='1'
uci set nikki.mixin.tcp_concurrent='1'
# 叠加规则：国内直连（prepend 到订阅自带规则之前，优先级最高）
uci set nikki.mixin.rule='1'
r=$(uci add nikki rule)
uci set nikki."$r".enabled='1'
uci set nikki."$r".type='GEOSITE'
uci set nikki."$r".matcher='cn'
uci set nikki."$r".node='DIRECT'
r=$(uci add nikki rule)
uci set nikki."$r".enabled='1'
uci set nikki."$r".type='GEOIP'
uci set nikki."$r".matcher='CN'
uci set nikki."$r".node='DIRECT'
uci set nikki."$r".no_resolve='1'
# 路由器本机 DNS 不劫持（保护 SmartDNS 上游查询直连；LAN 侧 53 端口劫持保留，硬编码 DNS 的客户端照样正确分流）
for s in $(uci show nikki 2>/dev/null | sed -n 's/^\(nikki\.@router_access_control\[[0-9]*\]\)\.dns=.*/\1/p'); do
	if [ -z "$(uci -q get "$s".user)" ] && [ -z "$(uci -q get "$s".group)" ] && [ -z "$(uci -q get "$s".cgroup)" ]; then
		uci set "$s".dns='0'
	fi
done
uci commit nikki

# ============ IPv4/IPv6 双栈 ============
# wan6（如缺失则补 DHCPv6）
if [ -z "$(uci -q get network.wan6.proto)" ]; then
	uci set network.wan6='interface' 2>/dev/null
	uci set network.wan6.proto='dhcpv6'
	uci set network.wan6.device='wan'
	uci set network.wan6.reqaddress='try'
	uci set network.wan6.reqprefix='auto'
	uci commit network
fi
# LAN IPv6 中继（上级路由/房东网关下游场景开箱即用；若改作主路由拨号，把这三项改回 server 并配 PD）
uci set dhcp.lan.ra='relay'
uci set dhcp.lan.dhcpv6='relay'
uci set dhcp.lan.ndp='relay'
uci commit dhcp

exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/97-smartdns-nikki
