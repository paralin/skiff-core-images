#!/bin/bash
set -eo pipefail

if [ ! -d ./skiffos/configs ]; then
    echo "Cloning SkiffOS submodule..."
    git submodule update --init
fi

echo "Building cross-platform skiff-core-debian image..."
cd ./skiffos/configs/skiff/core/buildroot_ext/package/skiff-core-defconfig/coreenv
docker buildx build \
       --tag quay.io/skiffos/skiff-core-debian:latest \
       --platform linux/amd64,linux/arm,linux/arm64,linux/riscv64 \
       -f Dockerfile \
       .
