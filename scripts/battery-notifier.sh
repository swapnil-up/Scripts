#!/bin/bash

# Set thresholds
LOW_BATTERY_LEVEL=30
HIGH_BATTERY_LEVEL=100

# Monitor battery status
while true; do
    # Get battery percentage
    BATTERY_PERCENT=$(cat /sys/class/power_supply/BAT*/capacity)
    
    # Get charging status
    STATUS=$(cat /sys/class/power_supply/BAT*/status)
    
    # Notify if battery is low
    if [ "$BATTERY_PERCENT" -le "$LOW_BATTERY_LEVEL" ] && [ "$STATUS" != "Charging" ]; then
        notify-send "Low Battery" "Battery at $BATTERY_PERCENT%. Please charge!" -u critical
    fi
    
    # Notify if battery is full
    if [ "$BATTERY_PERCENT" -ge "$HIGH_BATTERY_LEVEL" ] && [ "$STATUS" = "Charging" ]; then
        notify-send "Battery Full" "Battery is fully charged. Please unplug the charger." -u normal
    fi

    # Wait before checking again
    sleep 60
done

