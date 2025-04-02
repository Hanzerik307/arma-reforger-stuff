#!/bin/bash

# Optional: Cooldown to prevent rapid restarts (in seconds)
COOLDOWN_TIME=300
LAST_RESTART=0

# Monitor logs in real-time for arma.service
journalctl --user -u arma.service --follow | while read -r line; do
    if echo "$line" | grep -q "POSTGAME"; then
        CURRENT_TIME=$(date +%s)
        # Check if enough time has passed since the last restart
        if [ $((CURRENT_TIME - LAST_RESTART)) -gt $COOLDOWN_TIME ]; then
            echo "POSTGAME detected at $(date), restarting arma.service"
            systemctl --user restart arma.service
            LAST_RESTART=$CURRENT_TIME
        else
            echo "POSTGAME detected at $(date), but restart is on cooldown"
        fi
    fi
done

