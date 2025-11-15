#!/bin/sh

. /app/scripts/utils.sh

if [ ! -f /app/config/config.yml ]; then
    warn "config.yml not found in /app/config. Creating an empty config file."
    touch /app/config/config.yml
    log "Empty config.yml created. Exiting."
    exit 1
fi

log "Setting up CRON job"
CRON_JOB="$CRON_SCHEDULE /app/scripts/check_and_update.sh"

# Clear existing crontab to prevent duplicates
crontab -r 2>/dev/null || true

echo "$CRON_JOB" | crontab -

log "Current CRON jobs:"
crontab -l

log "Starting cron daemon"
crond -l 2 -f