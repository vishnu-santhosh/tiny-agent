FROM crops/poky:ubuntu-22.04

USER root

# Give vivek passwordless sudo
# RUN apt-get update && apt-get install -y sudo \
#  && echo "vivek ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
#  && apt-get clean


# 1. Provide sudo access to pokyuser (the default crops user)
# 2. Install Yocto essential host packages for Ubuntu 22.04
# 3. Add RPi-specific and general dev tools
RUN apt-get update && apt-get install -y \
    sudo \
    gawk wget git-core diffstat unzip texinfo gcc-multilib \
    build-essential chrpath socat cpio python3 python3-pip libelf-dev \
    python3-pexpect xz-utils debianutils iputils-ping python3-setuptools python3-packaging python3-jinja2 \
    python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev libpcre2-dev \
    pylint xterm python3-subunit mesa-common-dev zstd liblz4-tool \
    git vim nano curl lz4 libffi-dev zlib1g-dev \
    libpcre3-dev gettext \
    && echo "pokyuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Ensure correct working dir
# WORKDIR /workdir

# Switch back to pokyuser so the entrypoint script functions correctly
# USER pokyuser