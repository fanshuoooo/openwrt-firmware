#!/bin/bash
#
# ImmortalWrt 24.10 firmware build script for Xiaomi Mi Router CR6608 (v2 slim)
# Target: ramips/mt7621, WiFi: MT7915E (mac80211 upstream driver)
# Feeds: kenzok8/openwrt-packages + kenzok8/small
#
# v2 additions:
#   - dropbear start delayed until after network init (avoids early-boot bind warnings)
#   - files/etc/rc.local pre-creates /var/upnp.leases (miniupnpd startup fix)
#

set -u

STEP_FAIL() {
  echo ""
  echo "=============================================="
  echo "  BUILD FAILED AT: $1"
  echo "=============================================="
  exit 1
}

echo "=============================================="
echo "  [1/8] Installing build dependencies"
echo "=============================================="
sudo apt-get update -y || STEP_FAIL "apt-get update"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  build-essential asciidoc binutils bzip2 gawk gettext git libncurses5-dev \
  libz-dev patch python3 unzip zlib1g-dev subversion flex gcc-multilib \
  p7zip p7zip-full libssl-dev texinfo libelf-dev autoconf automake libtool \
  autopoint device-tree-compiler g++-multilib gperf wget curl swig rsync \
  || STEP_FAIL "apt-get install"
sudo timedatectl set-timezone Asia/Shanghai

echo "=============================================="
echo "  [2/8] Cloning ImmortalWrt (openwrt-24.10)"
echo "=============================================="
cd "$GITHUB_WORKSPACE" || STEP_FAIL "workspace"
rm -rf immortalwrt
git clone --depth 1 -b openwrt-24.10 https://github.com/immortalwrt/immortalwrt.git immortalwrt \
  || STEP_FAIL "git clone immortalwrt"

cd immortalwrt || STEP_FAIL "cd immortalwrt"

echo "=============================================="
echo "  [3/8] Adding package feeds"
echo "=============================================="
sed -i '1i src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '2i src-git small https://github.com/kenzok8/small' feeds.conf.default
cat feeds.conf.default

echo "=============================================="
echo "  [4/8] Applying source customizations"
echo "=============================================="
if [ -f ../scripts/custom.sh ]; then
  bash ../scripts/custom.sh || STEP_FAIL "custom.sh"
fi

echo "=============================================="
echo "  [5/8] Updating and installing feeds"
echo "=============================================="
./scripts/feeds update -a || STEP_FAIL "feeds update"
./scripts/feeds install -a || STEP_FAIL "feeds install"

echo "=============================================="
echo "  [6/8] Go toolchain + source patches"
echo "=============================================="
# 24.10 feed ships Go 1.23, but kenzok8/small's xray-core needs Go 1.26
# and sing-box needs Go 1.24.7. Replace lang/golang with the master
# branch version (Go 1.27) which satisfies both.
cd "$GITHUB_WORKSPACE" || STEP_FAIL "workspace"
curl -sL https://github.com/immortalwrt/packages/archive/refs/heads/master.tar.gz -o packages-master.tar.gz \
  || STEP_FAIL "download packages master"
tar -xzf packages-master.tar.gz packages-master/lang/golang || STEP_FAIL "extract golang"
rm -rf immortalwrt/feeds/packages/lang/golang
cp -r packages-master/lang/golang immortalwrt/feeds/packages/lang/golang || STEP_FAIL "replace golang"
rm -rf packages-master packages-master.tar.gz
cd immortalwrt || STEP_FAIL "cd immortalwrt"
grep -r 'GO_DEFAULT_VERSION' feeds/packages/lang/golang/golang-values.mk || true

# The master golang package cannot really build under 24.10 (its versioned
# package scheme is incompatible: 'golang1.27/host does not exist'), so the
# build silently falls back to the runner's old system Go. Install an official
# prebuilt Go binary into the exact PATH slot golang-build.sh uses.
GOVER=$(curl -sL 'https://go.dev/dl/?mode=json' | sed -n 's/.*"version"[^"]*"\(go[0-9][0-9.]*\)".*/\1/p' | head -n1)
[ -n "$GOVER" ] || GOVER=go1.27.0
echo "Installing official Go: $GOVER"
curl -sL "https://dl.google.com/go/${GOVER}.linux-amd64.tar.gz" -o /tmp/go-official.tgz || STEP_FAIL "download official go"
mkdir -p staging_dir/hostpkg/lib/go-1.27
tar -xzf /tmp/go-official.tgz -C staging_dir/hostpkg/lib/go-1.27 --strip-components=1 || STEP_FAIL "extract official go"
staging_dir/hostpkg/lib/go-1.27/bin/go version || STEP_FAIL "official go broken"

# sing-box full variant hardcodes with_tailscale; the tailscale fork pinned by
# kenzok8 fails to compile (reflect.TypeAssert). Drop tailscale - it is an
# optional outbound, core proxy features are unaffected.
sed -i 's/,with_tailscale//' feeds/small/sing-box/Makefile || STEP_FAIL "patch sing-box tags"
grep 'GO_PKG_TAGS' feeds/small/sing-box/Makefile || true

# Delay dropbear until network init is done (avoids early-boot port bind
# warnings). Force START=70 regardless of the original value.
DROPBEAR_INIT=package/network/services/dropbear/files/dropbear.init
if [ -f "$DROPBEAR_INIT" ]; then
  sed -i 's/^START=[0-9]\+$/START=70/' "$DROPBEAR_INIT" || STEP_FAIL "patch dropbear init"
  grep -n '^START=' "$DROPBEAR_INIT" || STEP_FAIL "dropbear START line missing"
else
  echo "WARN: $DROPBEAR_INIT not found, skipping dropbear patch"
fi

echo "=============================================="
echo "  [7/8] Loading configuration"
echo "=============================================="
cp ../config/.config .config || STEP_FAIL "copy .config"
mkdir -p files
cp -r ../files/. files/ || STEP_FAIL "copy files"
chmod +x files/etc/uci-defaults/* 2>/dev/null || true
chmod +x files/etc/rc.local 2>/dev/null || true
make defconfig || STEP_FAIL "make defconfig"
make download -j8 || STEP_FAIL "make download"
find dl -size -1024c -exec ls -l {} \;
find dl -size -1024c -exec rm -f {} \;

echo "=============================================="
echo "  [8/8] Compiling firmware"
echo "=============================================="
# Pre-build tcping single-threaded: it flakily fails under parallel make
make -j1 package/feeds/small/tcping/compile 2>/dev/null || true
echo "Using $(nproc) threads"
make -j"$(nproc)" || make -j1 || make -j1 V=s || STEP_FAIL "make"

echo "=============================================="
echo "  BUILD SUCCESS"
echo "=============================================="
ls -lh bin/targets/*/*/ || true
