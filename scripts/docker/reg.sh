#!/bin/bash
SCRIPT_DIR=$(dirname "$0")
MANAGE_CONFIG="$SCRIPT_DIR/cmnds-config"
REGISTRY=$(bash "$MANAGE_CONFIG" read CUSTOM_REGISTRY)
TAG=$(bash "$MANAGE_CONFIG" read CUSTOM_TAG)

# Check if image name is passed
if [ -z "$1" ]; then
  echo "Usage: $0 <image-name>"
  exit 1
fi

IMAGE_NAME=$1

# Build the Docker image
echo "+ Building image"
docker build -t ${IMAGE_NAME} .

# Tag the image with the registry and latest tag
echo "+ Naming image"
docker tag ${IMAGE_NAME} ${REGISTRY}/${IMAGE_NAME}:${TAG}

# Push the image to the registry
echo "+ Pushing image to registry '${REGISTRY}'"
docker push ${REGISTRY}/${IMAGE_NAME}:${TAG}
