FROM mcr.microsoft.com/devcontainers/universal:2

USER codespace
WORKDIR /
COPY . .
RUN mkdir -p /opt/dotfileinstall
WORKDIR /opt/dotfileinstall
RUN fish bootstrap.sh
RUN touch /opt/.codespaces_setup_complete

ENTRYPOINT ["/usr/bin/fish"]

LABEL org.opencontainers.image.description="joegoldin dotfiles precompiled base image"
