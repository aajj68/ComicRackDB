#!/bin/bash

function send_telegram_message() {
    local message="$1"

    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_API_KEY}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="$message"

    if [ $? -ne 0 ]; then
        echo "Failed to send Telegram message. Logging to /var/log/telegram_error.log."
        echo "$(date): Failed to send Telegram message. Message: $message" >> /var/log/telegram_error.log
    fi
}

#send_telegram_message "$1"
