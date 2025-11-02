#!/bin/sh
. /app/scripts/utils.sh

if [ ! -f /app/config/config.yml ]; then
    warn "config.yml not found in /app/config. Exiting."
    exit 1
fi

CONFIG_FILE="/app/config/config.yml"
LAST_VALUE_FILE="/app/data/last_value.txt"

PULL_TARGET=$(yq eval '.pull[0].target' $CONFIG_FILE)
PULL_RESPONSE_TYPE=$(yq eval '.pull[0].response.type' $CONFIG_FILE)
PULL_RESPONSE_PATH=$(yq eval '.pull[0].response.path' $CONFIG_FILE)
PUSH_TARGET=$(yq eval '.push[0].target' $CONFIG_FILE)
PUSH_MESSAGE=$(yq eval '.push[0].message' $CONFIG_FILE)

log "Fetching data from '$PULL_TARGET'"

RESPONSE=$(curl -s "$PULL_TARGET")
if [ $? -ne 0 ] || [ -z "$RESPONSE" ]; then
    warn "Failed to fetch data from $PULL_TARGET. Exiting."
    exit 1
fi

if [ "$PULL_RESPONSE_TYPE" != "JSON" ]; then
    warn "Unsupported response type: $PULL_RESPONSE_TYPE. Exiting."
    exit 1
fi

VALUE=$(echo "$RESPONSE" | jq -r ".${PULL_RESPONSE_PATH}") || warn "Failed to parse JSON response."

if [ -z "$VALUE" ]; then
    warn "Failed to extract value using the specified parser path. Exiting."
    exit 1
fi

log "Extracted value: '$VALUE'"

if [ -f "$LAST_VALUE_FILE" ]; then
    LAST_VALUE=$(cat "$LAST_VALUE_FILE")
else
    LAST_VALUE=""
fi

if [ "$VALUE" != "$LAST_VALUE" ]; then
    log "Value changed from '$LAST_VALUE' to '$VALUE'"
    echo "$VALUE" > "$LAST_VALUE_FILE"
    PUSH_MESSAGE=$(echo "$PUSH_MESSAGE" | sed "s/{{value}}/$VALUE/g")
    PAYLOAD=$(jq -n --arg content "$PUSH_MESSAGE" '{content: $content}')
    curl -s -X POST -H "Content-Type: application/json" -d "$PAYLOAD" "$PUSH_TARGET"
else
    log "Value did not change. Current value remains: '$VALUE'"
fi