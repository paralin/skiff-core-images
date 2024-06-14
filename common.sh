#!/bin/bash
set -eo pipefail

if [ ! -d ./skiffos/configs ]; then
    echo "Cloning SkiffOS submodule..."
    git submodule update --init
fi

# https://github.com/docker/buildx/issues/1152
# It is not possible to use --push separately

echo "Building cross-platform $IMAGE_NAME image..."
cd $IMAGE_DIR
docker buildx build \
       --push \
       --tag $IMAGE_TAG \
       --output=type=image,push=true,oci-mediatypes=false \
       --platform linux/amd64,linux/arm,linux/arm64,linux/riscv64 \
       -f Dockerfile \
       .
