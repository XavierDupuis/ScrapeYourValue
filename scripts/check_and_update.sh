#!/bin/sh
. /app/scripts/utils.sh

if [ ! -f /app/config/config.yml ]; then
    warn "config.yml not found in /app/config. Exiting."
    exit 1
fi

CONFIG_FILE="/app/config/config.yml"
DATA_DIR="/app/data"
mkdir -p "$DATA_DIR"


TARGET_COUNT=$(yq eval '.targets | length' $CONFIG_FILE)

for index in $(seq 0 $(($TARGET_COUNT - 1))); do
    TARGET_NAME=$(yq eval ".targets[$index].name" $CONFIG_FILE)
    log "Processing target '$TARGET_NAME'"

    LAST_VALUE_FILE="$DATA_DIR/${TARGET_NAME}.txt"
    PULL_TARGET=$(yq eval ".targets[$index].pull.target" $CONFIG_FILE)
    PULL_RESPONSE_TYPE=$(yq eval ".targets[$index].pull.response.type" $CONFIG_FILE)
    PULL_RESPONSE_PATH=$(yq eval ".targets[$index].pull.response.path" $CONFIG_FILE)

    RESPONSE=$(curl -s "$PULL_TARGET")
    if [ $? -ne 0 ] || [ -z "$RESPONSE" ]; then
        warn "Failed to fetch data from $PULL_TARGET. Skipping."
        continue
    fi

    if [ "$PULL_RESPONSE_TYPE" != "JSON" ]; then
        warn "Unsupported response type: $PULL_RESPONSE_TYPE. Skipping."
        continue
    fi

    VALUE=$(echo "$RESPONSE" | jq -r ".${PULL_RESPONSE_PATH}") || warn "Failed to parse JSON response."

    if [ -z "$VALUE" ]; then
        warn "Failed to extract value using the specified parser path. Skipping."
        continue
    fi

    if [ -f "$LAST_VALUE_FILE" ]; then
        LAST_VALUE=$(cat "$LAST_VALUE_FILE")
    else
        LAST_VALUE=""
    fi

    if [ "$VALUE" != "$LAST_VALUE" ]; then
        log "Value changed from '$LAST_VALUE' to '$VALUE' for target '$TARGET_NAME'"
        echo "$VALUE" > "$LAST_VALUE_FILE"

        PUSH_TARGET=$(yq eval ".targets[$index].push.target" $CONFIG_FILE)
        PUSH_MESSAGE=$(yq eval ".targets[$index].push.message" $CONFIG_FILE)

        PUSH_MESSAGE=$(echo "$PUSH_MESSAGE" | sed "s/{{value}}/$VALUE/g")
        PAYLOAD=$(jq -n --arg content "$PUSH_MESSAGE" '{content: $content}')
        curl -s -X POST -H "Content-Type: application/json" -d "$PAYLOAD" "$PUSH_TARGET"
        if [ $? -eq 0 ]; then
            log "Successfully sent notification to $PUSH_TARGET"
        else
            warn "Failed to send notification to $PUSH_TARGET"
        fi
    else
        log "Value did not change for target '$TARGET_NAME'. Current value remains: '$VALUE'"
    fi
done