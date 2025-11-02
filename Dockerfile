FROM alpine:3.22.2
RUN apk add --no-cache bash curl jq yq
WORKDIR /app
COPY /scripts ./scripts
RUN chmod +x /app/scripts/*.sh
# USER 1000:1000
ENTRYPOINT ["crond", "-f"]
