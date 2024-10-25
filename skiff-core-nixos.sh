#!/bin/bash

export IMAGE_NAME="quay.io/skiffos/skiff-core-nixos"
export IMAGE_DIR="./docker-nixos"
export IMAGE_TAG="latest"

# NixOS only supports arm64 and amd64
ARCH_TAGS=(
    arm64
    amd64
)

source common.sh
