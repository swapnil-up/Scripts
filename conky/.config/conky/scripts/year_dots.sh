#!/usr/bin/env bash

year=$(date +%Y)
month_today=$(date +%m | sed 's/^0//')
day_today=$(date +%d | sed 's/^0//')

# Months
month_days=(31 28 31 30 31 30 31 31 30 31 30 31)

# Leap year check
if (( (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0) )); then
    month_days[1]=29
fi

for month in $(seq 1 12); do
    days=${month_days[$((month - 1))]}

    for day in $(seq 1 $days); do
        if [ $month -lt $month_today ]; then
            printf "● "
        elif [ $month -eq $month_today ]; then
            if [ $day -lt $day_today ]; then
                printf "● "
            elif [ $day -eq $day_today ]; then
                printf "◉ "
            else
                printf "○ "
            fi
        else
            printf "○ "
        fi
    done

    printf "\n"
done
