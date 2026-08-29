# ImmortalWrt 固件自动编译

这是 Xiaomi Mi Router CR6608 路由器的固件自动编译项目。

## 固件信息

- **目标设备**: Xiaomi Mi Router CR6608
- **架构**: ramips/mt7621 (MediaTek MT7621)
- **固件版本**: ImmortalWrt 18.06-5.4
- **内核版本**: 5.10.109

## 内置功能

### 网络加速
- TurboACC (MTK 硬件加速)
- FullCone NAT
- BBR 拥塞控制

### 科学上网
- PassWall
- ShadowSocksR Plus+
- OpenClash

### DNS
- SmartDNS
- ChinaDNS-NG
- AdGuard Home

### 远程访问
- FRP 内网穿透 (已配置)
- TTYD 终端
- ZeroTier

### 其他
- DDNS (阿里云/腾讯云/Dnspod)
- UPnP
- 广告过滤 (Adbyby)
- 访客网络
- 定时重启
- 多线多拨

## 默认设置

- **路由器 IP**: 192.168.7.1
- **WiFi 名称**: Sakura-WiFi / Sakura-WiFi-5G
- **WiFi 密码**: Sakura123
- **主机名**: Sakura-Router
- **时区**: Asia/Shanghai (CST-8)

## 如何使用

### 1. 触发编译

**方式一**: Push 到 master 分支自动编译

**方式二**: 手动触发
1. 进入 Actions 页面
2. 选择 "Build ImmortalWrt Firmware"
3. 点击 "Run workflow"

### 2. 下载固件

编译完成后，在以下位置下载：
- **Actions**: Actions 页面 → 最新的工作流运行 → Artifacts
- **Releases**: Releases 页面 → 最新版本

### 3. 刷入固件

1. 下载 `immortalwrt-ramips-mt7621-xiaomi_cr6608-squashfs-sysupgrade.bin`
2. 进入路由器管理页面 → 系统 → 备份/升级
3. 上传固件并刷入
4. 等待重启完成

## 自定义配置

如需修改配置，编辑以下文件：

- `config/.config` - 软件包选择
- `scripts/custom.sh` - 自定义脚本（IP、WiFi、FRP 等）

## FRP 配置

已预配置的 FRP 代理：

| 名称 | 类型 | 远程端口 | 本地端口 | 说明 |
|------|------|----------|----------|------|
| luci | http | 8002 | 80 | LuCI 管理页面 |
| ttyd | tcp | 7681 | 7681 | TTYD 终端 |

访问地址：
- LuCI: `20112.linkv.top:8002`
- TTYD: `20112.linkv.top:7681`

## 注意事项

1. 编译时间约 1-3 小时
2. 固件大小约 15-20 MB
3. 刷入后请重新设置 WiFi 密码
4. 如修改 FRP 配置，请同步修改远程服务器

## 参考

- [ImmortalWrt](https://github.com/immortalwrt/immortalwrt)
- [kenzok8 软件包](https://github.com/kenzok8/openwrt-packages)
- [P3TERX 编译模板](https://github.com/P3TERX/Actions-OpenWrt)
