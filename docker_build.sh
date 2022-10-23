#!/bin/bash

# -----------------------------------------------------------------------------
# Copyright BMW CarIT GmbH 2021
# Copyright Helio Chissini de Castro 2022
#
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# This script is executed on startup of Docker container.
# (execution of docker run cmd) starts couchdb and tomcat.
# -----------------------------------------------------------------------------

set -e -o  pipefail

# Source the version
# shellcheck disable=SC1091
. scripts/versions.sh

GIT_ROOT=$(git rev-parse --show-toplevel)

COMPOSE_DOCKER_CLI_BUILD=1
DOCKER_BUILDKIT=1
export DOCKER_BUILDKIT COMPOSE_DOCKER_CLI_BUILD

usage() {
    echo "Usage:"
    echo "--help This messaqge"
    echo "--verbose Verbose build"
    echo "--no-cache Invalidate buildkit cache"
    exit 0;
}

for arg in "$@"; do
    if [ "$arg" == "--help" ]; then
        usage
    elif [ "$arg" == "--verbose" ]; then
        docker_verbose="--progress=plain"
    elif [ "$arg" == "--no-cache" ]; then
        docker_no_cache="--no-cache"
    else
        echo "Unsupported parameter: $arg"
        usage
    fi
    shift
done

DOCKER_IMAGE_ROOT="${DOCKER_IMAGE_ROOT:-eclipse}"

docker buildx build \
    --target sw360base \
    --cache-from "${DOCKER_IMAGE_ROOT}"/sw360base:latest \
    --tag "${DOCKER_IMAGE_ROOT}"/sw360base:latest \
    --build-arg LIFERAY_VERSION="$LIFERAY_VERSION" \
    --build-arg LIFERAY_SOURCE="$LIFERAY_SOURCE" \
    $docker_verbose \
    $docker_no_cache .

docker buildx build \
    --target sw360thrift \
    --cache-from "${DOCKER_IMAGE_ROOT}"/sw360thrift:"$THRIFT_VERSION" \
    --tag "${DOCKER_IMAGE_ROOT}"/sw360thrift:latest \
    --tag "${DOCKER_IMAGE_ROOT}"/sw360thrift:"$THRIFT_VERSION" \
    --build-arg THRIFT_VERSION="$THRIFT_VERSION" \
    $docker_verbose \
    $docker_no_cache .

docker buildx build \
    --target sw360clucene \
    --cache-from "${DOCKER_IMAGE_ROOT}"/sw360clucene:"$CLUCENE_VERSION" \
    --tag "${DOCKER_IMAGE_ROOT}"/sw360clucene:latest \
    --tag "${DOCKER_IMAGE_ROOT}"/sw360clucene:"$CLUCENE_VERSION" \
    --build-arg MAVEN_VERSION="$MAVEN_VERSION" \
    --build-arg CLUCENE_VERSION="$CLUCENE_VERSION" \
    $docker_verbose \
    $docker_no_cache .

docker buildx build \
    --target sw360 \
    --cache-from "${DOCKER_IMAGE_ROOT}"/sw360thrift:latest \
    --cache-from "${DOCKER_IMAGE_ROOT}"/sw360clucene:latest \
    --cache-from "${DOCKER_IMAGE_ROOT}"/sw360:latest \
    --tag "${DOCKER_IMAGE_ROOT}"/sw360:latest \
    --build-arg MAVEN_VERSION="$MAVEN_VERSION" \
    --build-arg LIFERAY_VERSION="$LIFERAY_VERSION" \
    --build-arg LIFERAY_SOURCE="$LIFERAY_SOURCE" \
    --build-arg SW360_DEPS_DIR="$SW360_DEPS_DIR" \
    $docker_verbose \
    $docker_no_cache .
