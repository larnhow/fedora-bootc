ARG FEDORA_MAJOR_VERSION=42
ARG FEDORA_DE=silverblue

FROM quay.io/fedora-ostree-desktops/${FEDORA_DE}:${FEDORA_MAJOR_VERSION}

#COPY --from=docker.io/mikefarah/yq /usr/bin/yq /usr/bin/yq

#RUN curl -s -o /etc/yum.repos.d/tailscale.repo https://pkgs.tailscale.com/stable/centos/9/tailscale.repo

RUN dnf remove -y firefox tcl

RUN dnf config-manager setopt rpmfusion-nonfree-nvidia-driver.enabled=1

RUN dnf in -y akmod-nvidia

RUN kver=$(cd /usr/lib/modules && echo *) && \
        akmods --force --kernels $kver



RUN dnf in -y alacritty \
              fedpkg \
              rust \
              gdb \
              glib \
              krb5-workstation \
              libvirt \
              libvirt-client \
              lld \
              lua5.1-lpeg \
              make \
              neovim \
              pre-commit \
	      python3-pip \
              qemu \
              qemu-kvm \
              ripgrep \
              tmux \
              virt-install \
	      gstreamer1-plugin-openh264 \
	      openh264 \
              fish && \

    dnf clean all && \
    systemctl set-default graphical.target 
