#!/bin/bash
set -eo pipefail

if [ ! -d ./skiffos/configs ]; then
	echo "Cloning SkiffOS submodule..."
	git submodule update --init
fi

echo "Building cross-platform $IMAGE_NAME image..."
cd $IMAGE_DIR

# note: buildx currently not working with quay.io correctly
# export USE_BUILDX=true to use buildx instead

if [ -z "${ARCH_TAGS[*]}" ]; then
    ARCH_TAGS=(
        arm
        arm64
        amd64
        riscv64
    )
fi
ARCH_IMAGES=("${ARCH_TAGS[@]/#/${IMAGE_NAME}:}")

tag_to_platform() {
	case $1 in
	"arm") echo "linux/arm/v7" ;;
	"arm64") echo "linux/arm64" ;;
	"amd64") echo "linux/amd64" ;;
	"riscv64") echo "linux/riscv64" ;;
	*) echo "unknown" ;;
	esac
}

if [ -n "$USE_BUILDX" ]; then
	# Use buildx
	echo "Using buildx to build and push the image..."
	platforms=$(printf "linux/%s," "${ARCH_TAGS[@]}" | sed 's/arm/arm\/v7/' | sed 's/,$//')
	docker buildx build \
		--push \
		--tag ${IMAGE_NAME}:${IMAGE_TAG} \
		--output=type=image,push=true,oci-mediatypes=false \
		--platform $platforms \
		-f Dockerfile \
		.
else
	# Use the multi-arch approach
	echo "Using the multi-arch approach to build and push the image..."
	# Build and push for each architecture
	for tag in "${ARCH_TAGS[@]}"; do
		platform=$(tag_to_platform $tag)

		echo "Building for $platform..."
		docker build --platform $platform -t ${IMAGE_NAME}:${tag} -f Dockerfile .
    docker push ${IMAGE_NAME}:${tag}

		if [ $? -eq 0 ]; then
			echo "Successfully built and pushed ${IMAGE_NAME}:${tag}"
		else
			echo "Failed to build or push ${IMAGE_NAME}:${tag}"
			exit 1
		fi
	done

	echo "All architectures built and pushed successfully."

	# Create and push the manifest
	echo "Creating and pushing the manifest..."
	docker manifest create --amend ${IMAGE_NAME}:${IMAGE_TAG} ${ARCH_IMAGES[@]}
	docker manifest push --purge ${IMAGE_NAME}:${IMAGE_TAG}
fi
