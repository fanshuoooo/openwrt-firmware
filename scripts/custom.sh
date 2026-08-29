#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
# Custom script for ImmortalWrt build
#

# Modify default IP
sed -i 's/192.168.1.1/192.168.7.1/g' package/base-files/files/bin/config_generate

# Modify hostname
sed -i 's/OpenWrt/Sakura-Router/g' package/base-files/files/bin/config_generate

# Set timezone
sed -i 's/UTC/CST-8/g' package/base-files/files/bin/config_generate
sed -i '/timezone/a\			set system.@system[0].zonename=\"Asia\/Shanghai\"' package/base-files/files/bin/config_generate

# Modify default theme
sed -i 's/luci-theme-bootstrap/luci-theme-argone/g' feeds/luci/collections/luci/Makefile

# Add kenzok8 packages
git clone --depth=1 https://github.com/kenzok8/openwrt-packages.git package/kenzok8
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall.git package/passwall
git clone --depth=1 https://github.com/fw876/helloworld.git package/helloworld

# Add Argone theme
git clone --depth=1 https://github.com/kenzok78/luci-theme-argone.git package/luci-theme-argone

# Fix some package issues
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/packages/net/mosdns

# Update packages
./scripts/feeds update -a
./scripts/feeds install -a

# Generate default config
cat > package/base-files/files/etc/config/system << 'EOF'
config system
	option hostname 'Sakura-Router'
	option timezone 'CST-8'
	option zonename 'Asia/Shanghai'
	option log_size '64'
	option log_buffer_size '64'
	option conloglevel '8'
	option cronloglevel '8'

config timeserver 'ntp'
	option enabled '1'
	option enable_server '0'
	list server 'ntp.aliyun.com'
	list server 'ntp.tencent.com'
	list server 'time.windows.com'
	list server 'pool.ntp.org'
EOF

# Set wireless defaults
cat > package/base-files/files/etc/config/wireless << 'EOF'
config wifi-device 'radio0'
	option type 'mac80211'
	option path '1e140000.pcie/pci0000:00/0000:00:00.0/0000:01:00.0'
	option channel 'auto'
	option band '2g'
	option htmode 'HT40'
	option disabled '0'
	option country 'CN'

config wifi-iface 'default_radio0'
	option device 'radio0'
	option network 'lan'
	option mode 'ap'
	option ssid 'Sakura-WiFi'
	option encryption 'psk2+ccmp'
	option key 'Sakura123'

config wifi-device 'radio1'
	option type 'mac80211'
	option path '1e140000.pcie/pci0000:00/0000:00:00.0/0000:01:00.0+1'
	option channel 'auto'
	option band '5g'
	option htmode 'HE80'
	option disabled '0'
	option country 'CN'

config wifi-iface 'default_radio1'
	option device 'radio1'
	option network 'lan'
	option mode 'ap'
	option ssid 'Sakura-WiFi-5G'
	option encryption 'psk2+ccmp'
	option key 'Sakura123'
EOF

# FRP config template
cat > package/base-files/files/etc/config/frp << 'EOF'
config common
	option enabled '1'
	option server_addr '43.134.136.204'
	option server_port '5433'
	option token 'dnihCS20u7wgWkNE'
	option user '20112'
	option tcp_mux '1'
	option tls_enable '1'
	option vhost_http_port '8002'
	option vhost_https_port '6444'
	option admin_enable '1'
	option admin_port '7400'
	option admin_user 'admin'
	option admin_pwd 'admin'
	option time '40'

config proxy 'luci'
	option remark 'luci'
	option type 'http'
	option custom_domains '20112'
	option remote_port '8002'
	option local_ip '192.168.7.1'
	option local_port '80'
	option use_encryption '1'
	option use_compression '1'
	option enable '1'

config proxy 'ttyd'
	option remark 'ttyd'
	option type 'tcp'
	option remote_port '7681'
	option local_ip '127.0.0.1'
	option local_port '7681'
	option use_encryption '1'
	option use_compression '1'
	option enable '1'
EOF

echo "Custom configuration applied!"
