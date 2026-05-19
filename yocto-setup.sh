#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_IMAGE="poky-dev"
POKY_REPO="https://github.com/yoctoproject/poky.git"
RASPBERRYPI_REPO="git://git.yoctoproject.org/meta-raspberrypi"
POKY_DIR="$ROOT_DIR/poky"
META_RPI_DIR="$ROOT_DIR/meta-raspberrypi"
DEFAULT_BRANCH="scarthgap"
DEFAULT_MACHINE="qemux86-64"
DEFAULT_IMAGE="core-image-minimal"

usage() {
    cat <<EOF
Usage: $0 <command> [options]

Commands:
  clone [branch]        Clone poky and meta-raspberrypi into the current directory.
                        Default branch: ${DEFAULT_BRANCH}
  docker-build          Build the Docker image named ${DOCKER_IMAGE}.
  shell                 Run an interactive build container with the current repo mounted.
  build [machine] [image]
                        Run the container and build a Yocto image inside it.
                        Default MACHINE=${DEFAULT_MACHINE}, IMAGE=${DEFAULT_IMAGE}.
  all [branch]          Clone repos (if missing) and build the Docker image.
  help                  Show this message.
EOF
}

log() {
    printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$1"
}

die() {
    echo "ERROR: $1" >&2
    exit 1
}

ensure_docker() {
    command -v docker >/dev/null 2>&1 || die 'docker is not installed or not on PATH.'
}

clone_repo() {
    local repo_url="$1"
    local target_dir="$2"
    local branch="$3"

    if [ -d "$target_dir/.git" ]; then
        log "Repository already exists: $target_dir"
        return
    fi

    log "Cloning $repo_url into $target_dir (branch: $branch)..."
    git clone --depth 1 --branch "$branch" "$repo_url" "$target_dir"
}

clone_all() {
    local branch="${1:-$DEFAULT_BRANCH}"
    clone_repo "$POKY_REPO" "$POKY_DIR" "$branch"
    clone_repo "$RASPBERRYPI_REPO" "$META_RPI_DIR" "$branch"
}

docker_build() {
    ensure_docker
    log "Building Docker image $DOCKER_IMAGE..."
    docker build -t "$DOCKER_IMAGE" "$ROOT_DIR"
}

container_shell() {
    ensure_docker
    log "Launching interactive container..."
    docker run --rm -it \
        -e LOCAL_UID="$(id -u)" \
        -e LOCAL_GID="$(id -g)" \
        -v "$ROOT_DIR":/workdir:Z \
        -w /workdir \
        "$DOCKER_IMAGE" \
        bash
}

container_build() {
    ensure_docker
    local machine="${1:-$DEFAULT_MACHINE}"
    local image="${2:-$DEFAULT_IMAGE}"

    log "Starting build container with MACHINE=$machine IMAGE=$image..."
    docker run --rm \
        -e LOCAL_UID="$(id -u)" \
        -e LOCAL_GID="$(id -g)" \
        -e MACHINE="$machine" \
        -e IMAGE="$image" \
        -v "$ROOT_DIR":/workdir:Z \
        -w /workdir/poky \
        "$DOCKER_IMAGE" \
        bash -lc 'source oe-init-build-env && echo "Edit build/conf/local.conf if needed, then building..." && MACHINE="$MACHINE" bitbake "$IMAGE"'
}

case "${1:-help}" in
    clone)
        clone_all "${2:-$DEFAULT_BRANCH}"
        ;;
    docker-build)
        docker_build
        ;;
    shell)
        container_shell
        ;;
    build)
        container_build "${2:-$DEFAULT_MACHINE}" "${3:-$DEFAULT_IMAGE}"
        ;;
    all)
        clone_all "${2:-$DEFAULT_BRANCH}"
        docker_build
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        usage
        exit 1
        ;;
esac
