# See here for base image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.194.0/containers/alpine/.devcontainer/base.Dockerfile

ARG ALPINE_VERSION="3.20"
FROM mcr.microsoft.com/devcontainers/base:alpine-${ALPINE_VERSION}

USER root

# See https://nvd.nist.gov/vuln/detail/CVE-2019-5021 
RUN sed -i -e 's/^root::/root:!:/' /etc/shadow 

RUN apk update \
 && apk upgrade \
 && apk add openssl curl bash sudo xz git httpie wget just \
 && rm -rf /var/cache/apk/*

# See here for how to integrate Nix into Alpine: https://github.com/redoracle/nixos/blob/master/Dockerfile
ARG NIX_VERSION="2.18.2"
ARG NIX_SHA256="c4589f1968565e84ca9501307f269e62b8e3154aec891afc582a06a35aad4d7e"

WORKDIR /
RUN wget https://releases.nixos.org/nix/nix-${NIX_VERSION}/nix-${NIX_VERSION}-x86_64-linux.tar.xz -O nix.tar.xz
RUN echo ${NIX_SHA256} nix.tar.xz | sha256sum -c \
   && cat nix.tar.xz | xz -d | tar xp \
   && mv nix-*-linux nix-release \
   && rm nix.tar.xz

ARG USERNAME=vscode
RUN addgroup -g 30000 -S nixbld \
  && for i in $(seq 1 30); do adduser -S -D -h /var/empty -g "Nix build user $i" -u $((30000 + i)) -G nixbld nixbld$i ; done \
  && mkdir -m 0755 /etc/nix \
  && echo 'sandbox = false' > /etc/nix/nix.conf \
  && mkdir -m 0755 /nix \
  && chown -R ${USERNAME} /nix /etc/nix

USER ${USERNAME}
RUN USER=${USERNAME} sh nix-release/install

USER root 
RUN rm -r /nix-release \
  && ln -s /nix/var/nix/profiles/per-user/${USERNAME}/profile/etc/profile.d/nix.sh /etc/profile.d/

# We install nixpkgs.go so the Go extension can bootstrap gopls, goimports, etc.  But it is better for your project if
# you manage your Go installation from your shell.nix.
USER ${USERNAME}
RUN . /home/${USERNAME}/.nix-profile/etc/profile.d/nix.sh \
  && /home/${USERNAME}/.nix-profile/bin/nix-collect-garbage --delete-old \
  && /home/${USERNAME}/.nix-profile/bin/nix-store --optimise \
  && /home/${USERNAME}/.nix-profile/bin/nix-store --verify --check-contents

# Podman does not support onbuild, but it tolerates it.
ONBUILD ENV \
    ENV=/etc/profile \
    USER=${USERNAME} \
    PATH=/home/${USERNAME}/.nix-profile/bin:/nix/var/nix/profiles/per-user/${USERNAME}/profile/bin:/nix/var/nix/profiles/per-user/${USERNAME}/profile/sbin:/bin:/sbin:/usr/bin:/usr/sbin \
    NIX_PATH=/nix/var/nix/profiles/per-user/${USERNAME}/channels

ENV \
    ENV=/etc/profile \
    USER=${USERNAME} \
    PATH=/home/${USERNAME}/.nix-profile/bin:/nix/var/nix/profiles/per-user/${USERNAME}/profile/bin:/nix/var/nix/profiles/per-user/${USERNAME}/profile/sbin:/bin:/sbin:/usr/bin:/usr/sbin \
    NIX_PATH=/nix/var/nix/profiles/per-user/${USERNAME}/channels
