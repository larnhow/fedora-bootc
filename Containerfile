FROM quay.io/fedora/fedora-bootc:42

#! Install rpmfusion free and nonfree repo's for access to the nvidia drivers
RUN dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
RUN dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

#! Install the kernel devel and kernel header tools
#! We get the kernel that is being used in THE BASE IMAGE by doing /usr/lib/modules && echo *, then we install the kernel-devel for that kernel
#! SOMETIMES this messes up if the "base" image has an outdated kernel vs the one you get from dnf
RUN export KVER=$(cd /usr/lib/modules && echo *) && \
    dnf install -y kernel-devel-$KVER

#! Install the nvidia drivers
RUN dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda

#! Blacklist the nouveau driver to ensure NVIDIA drivers function properly
RUN echo "blacklist nouveau" > /etc/modprobe.d/blacklist_nouveau.conf

#! See: "Kernel Open" on:
#! https://rpmfusion.org/Howto/NVIDIA?highlight=%28%5CbCategoryHowto%5Cb%29
#! Starting 515xx and above, to support the 5000 series and newer cards, the kernel needs to be "open" to allow the nvidia drivers to work when compiling with akmods.
RUN sh -c 'echo "%_with_kmod_nvidia_open 1" > /etc/rpm/macros.nvidia-kmod'

#! Add `options nvidia NVreg_OpenRmEnableUnsupportedGpus=1` to /etc/modprobe.d/nvidia.conf
#! which will enable the 5000 series GPUs to work with the nvidia drivers.
RUN echo "options nvidia NVreg_OpenRmEnableUnsupportedGpus=1" > /etc/modprobe.d/nvidia.conf

#! Build kmods which runs on boot.
#! The reasoning for the script is that sometimes the kernel version is different on the base images vs what is actually on 
#! dnf update, so we have to "fake it till you make it" scenario.
RUN dnf install -y dkms
COPY --chmod=755 dkms.sh /tmp
RUN /tmp/dkms.sh

#! Copy necessary usr files
COPY usr/ /usr/

#! Enable necessary services to be started at boot
RUN systemctl enable nvidia-toolkit-firstboot.service

FROM quay.io/fedora-ostree-desktops/${FEDORA_DE}:${FEDORA_MAJOR_VERSION}

#COPY --from=docker.io/mikefarah/yq /usr/bin/yq /usr/bin/yq

#RUN curl -s -o /etc/yum.repos.d/tailscale.repo https://pkgs.tailscale.com/stable/centos/9/tailscale.repo

RUN dnf remove -y firefox tcl

RUN dnf config-manager setopt rpmfusion-nonfree-nvidia-driver.enabled=1

RUN dnf in -y akmod-nvidia

RUN kver=$(cd /usr/lib/modules && echo *) && \
        akmods --force --kernels $kver
