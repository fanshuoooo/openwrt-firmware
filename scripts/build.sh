#!/bin/bash
#
# ImmortalWrt 24.10 firmware build script for Xiaomi Mi Router CR6608
# Target: ramips/mt7621, WiFi: MT7915E (mac80211 upstream driver)
# Feeds: kenzok8/openwrt-packages + kenzok8/small
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
echo "  [1/7] Installing build dependencies"
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
echo "  [2/7] Cloning ImmortalWrt (openwrt-24.10)"
echo "=============================================="
cd "$GITHUB_WORKSPACE" || STEP_FAIL "workspace"
rm -rf immortalwrt
git clone --depth 1 -b openwrt-24.10 https://github.com/immortalwrt/immortalwrt.git immortalwrt \
  || STEP_FAIL "git clone immortalwrt"

cd immortalwrt || STEP_FAIL "cd immortalwrt"

echo "=============================================="
echo "  [3/7] Adding package feeds"
echo "=============================================="
sed -i '1i src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '2i src-git small https://github.com/kenzok8/small' feeds.conf.default
cat feeds.conf.default

echo "=============================================="
echo "  [4/7] Applying source customizations"
echo "=============================================="
if [ -f ../scripts/custom.sh ]; then
  bash ../scripts/custom.sh || STEP_FAIL "custom.sh"
fi

echo "=============================================="
echo "  [5/7] Updating and installing feeds"
echo "=============================================="
./scripts/feeds update -a || STEP_FAIL "feeds update"
./scripts/feeds install -a || STEP_FAIL "feeds install"

echo "=============================================="
echo "  [6/7] Loading configuration"
echo "=============================================="
cp ../config/.config .config || STEP_FAIL "copy .config"
mkdir -p files
cp -r ../files/. files/ || STEP_FAIL "copy files"
chmod +x files/etc/uci-defaults/* 2>/dev/null || true
make defconfig || STEP_FAIL "make defconfig"
make download -j8 || STEP_FAIL "make download"
find dl -size -1024c -exec ls -l {} \;
find dl -size -1024c -exec rm -f {} \;

echo "=============================================="
echo "  [7/7] Compiling firmware"
echo "=============================================="
echo "Using $(nproc) threads"
make -j"$(nproc)" || make -j1 || make -j1 V=s || STEP_FAIL "make"

echo "=============================================="
echo "  BUILD SUCCESS"
echo "=============================================="
ls -lh bin/targets/*/*/ || true
