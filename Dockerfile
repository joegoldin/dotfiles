FROM mcr.microsoft.com/devcontainers/universal:2

COPY . .

RUN fish bootstrap.sh
