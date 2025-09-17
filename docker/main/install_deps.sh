#!/bin/bash

set -euxo pipefail

apt-get -qq update
apt-get -qq install --no-install-recommends -y software-properties-common
add-apt-repository ppa:deadsnakes/ppa
apt-get -qq update

apt-get -qq install --no-install-recommends -y \
    apt-transport-https \
    ca-certificates \
    gnupg \
    wget \
    lbzip2 \
    procps vainfo \
    unzip locales tzdata libxml2 xz-utils \
    python3.11 \
    curl \
    lsof \
    jq \
    nethogs \
    libgl1 \
    libglib2.0-0 \
    libusb-1.0.0

update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1

mkdir -p -m 600 /root/.gnupg

# install coral runtime
wget -q -O /tmp/libedgetpu1-max.deb "https://github.com/feranick/libedgetpu/releases/download/16.0TF2.17.1-1/libedgetpu1-max_16.0tf2.17.1-1.bookworm_${TARGETARCH}.deb"
unset DEBIAN_FRONTEND
yes | dpkg -i /tmp/libedgetpu1-max.deb && export DEBIAN_FRONTEND=noninteractive
rm /tmp/libedgetpu1-max.deb

# ffmpeg -> amd64
if [[ "${TARGETARCH}" == "amd64" ]]; then
    mkdir -p /usr/lib/ffmpeg/5.0
    wget -qO ffmpeg.tar.xz "https://github.com/NickM-27/FFmpeg-Builds/releases/download/autobuild-2022-07-31-12-37/ffmpeg-n5.1-2-g915ef932a3-linux64-gpl-5.1.tar.xz"
    tar -xf ffmpeg.tar.xz -C /usr/lib/ffmpeg/5.0 --strip-components 1 amd64/bin/ffmpeg amd64/bin/ffprobe
    rm -rf ffmpeg.tar.xz
    mkdir -p /usr/lib/ffmpeg/7.0
    wget -qO ffmpeg.tar.xz "https://github.com/NickM-27/FFmpeg-Builds/releases/download/autobuild-2024-09-19-12-51/ffmpeg-n7.0.2-18-g3e6cec1286-linux64-gpl-7.0.tar.xz"
    tar -xf ffmpeg.tar.xz -C /usr/lib/ffmpeg/7.0 --strip-components 1 amd64/bin/ffmpeg amd64/bin/ffprobe
    rm -rf ffmpeg.tar.xz
fi

# ffmpeg -> arm64
if [[ "${TARGETARCH}" == "arm64" ]]; then
    mkdir -p /usr/lib/ffmpeg/5.0
    wget -qO ffmpeg.tar.xz "https://github.com/NickM-27/FFmpeg-Builds/releases/download/autobuild-2022-07-31-12-37/ffmpeg-n5.1-2-g915ef932a3-linuxarm64-gpl-5.1.tar.xz"
    tar -xf ffmpeg.tar.xz -C /usr/lib/ffmpeg/5.0 --strip-components 1 arm64/bin/ffmpeg arm64/bin/ffprobe
    rm -f ffmpeg.tar.xz
    mkdir -p /usr/lib/ffmpeg/7.0
    wget -qO ffmpeg.tar.xz "https://github.com/NickM-27/FFmpeg-Builds/releases/download/autobuild-2024-09-19-12-51/ffmpeg-n7.0.2-18-g3e6cec1286-linuxarm64-gpl-7.0.tar.xz"
    tar -xf ffmpeg.tar.xz -C /usr/lib/ffmpeg/7.0 --strip-components 1 arm64/bin/ffmpeg arm64/bin/ffprobe
    rm -f ffmpeg.tar.xz
fi

# arch specific packages
if [[ "${TARGETARCH}" == "amd64" ]]; then
    apt-get -qq update
    apt-get -qq install --reinstall -y python3-apt
    apt-get -qq install --no-install-recommends -y software-properties-common
    add-apt-repository ppa:deadsnakes/ppa
    add-apt-repository -y ppa:kobuk-team/intel-graphics
    # intel packages use zst compression so we need to update dpkg
    apt-get install -y dpkg

    apt-get update
    apt-get -qq install --no-install-recommends --no-install-suggests -y \
        intel-gpu-tools onevpl-tools libva-drm2 \
        intel-metrics-discovery intel-opencl-icd clinfo intel-gsc \
        intel-media-va-driver-non-free libmfx-gen1 libvpl2 libva-glx2 va-driver-all vainfo      

    apt-get -qq install -y ocl-icd-libopencl1

    dpkg --purge --force-remove-reinstreq intel-driver-compiler-npu intel-fw-npu intel-level-zero-npu

    apt -qq install -y libtbb12

    wget https://github.com/intel/linux-npu-driver/releases/download/v1.23.0/linux-npu-driver-v1.23.0.20250827-17270089246-ubuntu2404.tar.gz
    tar -xf linux-npu-driver-v1.23.0.20250827-17270089246-ubuntu2404.tar.gz
    dpkg -i *.deb

    wget https://github.com/oneapi-src/level-zero/releases/download/v1.22.4/level-zero_1.22.4+u24.04_amd64.deb

    dpkg -i level-zero*.deb
    rm *.deb
fi

if [[ "${TARGETARCH}" == "arm64" ]]; then
    apt-get -qq install --no-install-recommends --no-install-suggests -y \
        libva-drm2 mesa-va-drivers radeontop
fi

# install vulkan
apt-get -qq install --no-install-recommends --no-install-suggests -y \
    libvulkan1 mesa-vulkan-drivers

apt-get purge gnupg apt-transport-https xz-utils -y
apt-get clean autoclean -y
apt-get autoremove --purge -y
rm -rf /var/lib/apt/lists/*

# Install yq, for frigate-prepare and go2rtc echo source
curl -fsSL \
    "https://github.com/mikefarah/yq/releases/download/v4.33.3/yq_linux_$(dpkg --print-architecture)" \
    --output /usr/local/bin/yq
chmod +x /usr/local/bin/yq
