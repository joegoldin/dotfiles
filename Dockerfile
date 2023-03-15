FROM mcr.microsoft.com/devcontainers/universal:2

USER codespace
RUN mkdir -p /opt/dotfileinstall
WORKDIR /opt/dotfileinstall
COPY . .
RUN bash bootstrap.sh
RUN touch /opt/.codespaces_setup_complete
RUN rm -rf .vscode-server
RUN rm -rf .vscode-server-insiders

ENTRYPOINT ["/bin/bash"]

LABEL org.opencontainers.image.description="joegoldin dotfiles precompiled base image"
