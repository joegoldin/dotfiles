FROM mcr.microsoft.com/devcontainers/universal:2

USER codespace
WORKDIR /
RUN mkdir -p /opt/dotfileinstall
WORKDIR /opt/dotfileinstall
COPY . .
RUN fish bootstrap.sh
RUN touch /opt/.codespaces_setup_complete

ENTRYPOINT ["/usr/bin/fish"]

LABEL org.opencontainers.image.description="joegoldin dotfiles precompiled base image"
