FROM node:22-alpine

RUN apk add --no-cache git su-exec bash bubblewrap socat

RUN npm install -g @anthropic-ai/claude-code@latest

RUN mkdir -p /claude /workspace /etc/claude-code

COPY managed-settings.json /etc/claude-code/managed-settings.json

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["claude"]
