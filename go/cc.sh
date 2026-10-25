#!/bin/sh
export PATH=/opt/data/tmp/ohos-tools/bin:/opt/data/tmp/ohos-native/native/llvm/bin:$PATH
exec /opt/data/tmp/ohos-native/native/llvm/bin/clang-15 \
  --target=aarch64-linux-ohos \
  --sysroot=/opt/data/tmp/ohos-native/native/sysroot \
  -fPIC "$@"
