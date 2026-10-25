# vpn-spike —— 鸿蒙上跑 Go 内核的可行性验证

验证目标：**用 OpenHarmony SIG 的 Go 工具链编出的 `.so`，能否在 HarmonyOS NEXT 上被 ArkTS 通过 NAPI 调起来。**

## 结论（2026-10-23 已验证前半段）

`libgoadd.so` 1.7MB，ELF 64 位 AArch64，导出 `Add` 符号 —— Go → 鸿蒙的跨平台编译这一步通了。

## 目录

| 路径 | 说明 |
|---|---|
| `go/main.go` | 最小 Go 导出函数（`//export Add`） |
| `go/cc.sh` | OHOS clang 包装（`--target=aarch64-linux-ohos` + sysroot） |
| `libgoadd.so` | 预编译产物（arm64） |
| `app/cpp/` | NAPI 包装，`dlopen("libgoadd.so")` 后调 `Add` |
| `app/Index.ets` | 测试页：点按钮显示 `Add(1,2)` |
| `app/entry-build-profile.json5` | 加了 `externalNativeOptions` 的模块级配置 |
| `app/entry-oh-package.json5` | 声明 `libentry.so` 依赖 |

## 复现编译（Linux，编 Go 侧）

```sh
git clone --depth 1 --branch release-branch.go1.24 https://gitcode.com/openharmony-sig/ohos_golang_go.git
cd ohos_golang_go/src && GOROOT_BOOTSTRAP=/path/to/go1.24 ./make.bash
# 下载 OHOS SDK：https://repo.huaweicloud.com/openharmony/os/5.0.0-Release/ohos-sdk-windows_linux-public.tar.gz
# 解压 linux/native-linux-x64-*.zip → native/{llvm,sysroot}
cd go
GOOS=openharmony GOARCH=arm64 CGO_ENABLED=1 CC=$PWD/cc.sh \
  GOPATH=/tmp/gp GOCACHE=/tmp/gc go build -buildmode=c-shared -o libgoadd.so .
```

## 踩过的坑

1. OHOS SDK 里的 `clang`、`ld.lld` 是 3 字节占位文本（内容分别是 `clang-15`、`lld`），直接调用报 `Exec format error`。真二进制是同目录的 `clang-15` 与 `lld`，需软链替换。
2. Go link 阶段会去 clang 自己的资源目录找 `ld.lld`，只改 `PATH` 无效，必须替换 SDK 里那份。
3. `-fuse-ld=lld` 不能放进 `CC` 包装脚本（编译阶段会报 unused argument），要么走 `CGO_LDFLAGS`，要么替换 `ld.lld` 即可。
