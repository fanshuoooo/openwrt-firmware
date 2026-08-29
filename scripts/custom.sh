#!/bin/bash
#
# Source-level customization for ImmortalWrt build (runs before feeds update)
#

set -u

# ---- Modify default LAN IP (192.168.1.1 -> 192.168.7.1) ----
sed -i 's/192\.168\.1\.1/192.168.7.1/g' package/base-files/files/bin/config_generate

# ---- Modify default hostname ----
sed -i "s/hostname='OpenWrt'/hostname='Sakura-Router'/g" package/base-files/files/bin/config_generate
sed -i "s/hostname='ImmortalWrt'/hostname='Sakura-Router'/g" package/base-files/files/bin/config_generate
sed -i "s/hostname='immortalwrt'/hostname='Sakura-Router'/g" package/base-files/files/bin/config_generate

# ---- Set default timezone to Asia/Shanghai ----
sed -i "s/system.@system\[0\].timezone='UTC'/system.@system[0].timezone='CST-8'/g" package/base-files/files/bin/config_generate
sed -i "s/system.@system\[0\].zonename='UTC'/system.@system[0].zonename='Asia\/Shanghai'/g" package/base-files/files/bin/config_generate

echo "custom.sh: source customization applied"
