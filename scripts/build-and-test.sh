#!/usr/bin/env bash

IMAGE="${1}"
IMAGE_TAG="analytical-platform.service.justice.gov.uk/visual-studio-code:local"
CONTAINER_STRUCTURE_TEST_IMAGE="gcr.io/gcp-runtimes/container-structure-test:latest"

if [[ "${REMOTE_CONTAINERS}" ]] && [[ "$(uname -m)" == "aarch64" ]]; then
  echo "(⚠) Looks like you're running in a dev container on Apple Silicon."
  echo "(⚠) This script builds linux/amd64 images which might take a long time or even fail."
  export PLATFORM_FLAG="--platform linux/amd64"
fi

docker build ${PLATFORM_FLAG} --file Dockerfile --tag "${IMAGE_TAG}" .

if [[ -f "${IMAGE}/test/container-structure-test.yml" ]]; then
  echo "Running container structure test for [ ${IMAGE_TAG} ]"

  docker run --rm ${PLATFORM_FLAG} \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume "${PWD}:/workspace" \
    --workdir /workspace \
    "${CONTAINER_STRUCTURE_TEST_IMAGE}" \
    test --image "${IMAGE_TAG}" --config "/workspace/test/container-structure-test.yml"
fi
