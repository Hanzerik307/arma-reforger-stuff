#!/bin/bash

# LGSM-compatible Arma Reforger server monitoring script

# LGSM-specific variables
LGSM_SCRIPT="/home/armaserver/armarserver"
LOG_FILE="/home/armaserver/log/console/armarserver-console.log"

# Optional: Cooldown to prevent rapid restarts (in seconds)
COOLDOWN_TIME=300
LAST_RESTART=0

# Ensure we're in the right directory
cd /home/armaserver || exit 1

# Monitor logs in real-time
tail -F "$LOG_FILE" | while read -r line; do
    if echo "$line" | grep -q "POSTGAME"; then
        CURRENT_TIME=$(date +%s)
        if [ $((CURRENT_TIME - LAST_RESTART)) -gt $COOLDOWN_TIME ]; then
            echo "POSTGAME detected at $(date), waiting 25 seconds before restarting armarserver via LGSM"
            sleep 25
            "$LGSM_SCRIPT" restart
            LAST_RESTART=$CURRENT_TIME
        else
            echo "POSTGAME detected at $(date), but restart is on cooldown"
        fi
    fi
done
