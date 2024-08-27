#!/bin/bash

function send_email() {
    local subject="$1"
    local log_file="/var/log/comicrack.log"
    local to="${SMMTP_TO:-info@sgd.com.br}"  # Use the environment variable or the default value
    local body=""

    # Read the content of the log file
    if [ -f "$log_file" ]; then
        body=$(cat "$log_file")
    else
        body="The log file $log_file was not found."
    fi

    # Send the email with the log content as the body
    echo -e "Subject: $subject\n\n$body" | ssmtp "$to"
    
    if [ $? -ne 0 ]; then
        echo "[COMICRACK] Error in the send_email() function"
        echo "$(date): Failed to send email to $to. Subject: $subject" >> /var/log/send_email_error.log
        send_telegram_message "Failed to send email to $to. Subject: $subject"
    fi
}
