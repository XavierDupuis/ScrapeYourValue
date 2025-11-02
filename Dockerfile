FROM alpine:3.22.2
RUN apk add --no-cache bash curl jq yq
WORKDIR /app
COPY /scripts ./scripts
RUN chmod +x /app/scripts/*.sh
ENTRYPOINT ["sh", "/app/scripts/startup.sh"]
