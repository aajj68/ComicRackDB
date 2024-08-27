#!/bin/bash

#Install packages
apt-get update
apt-get install cron -y
apt install zip -y
apt install unzip -y
apt-get install ssmtp -y
apt-get install curl -y

#install cron
cp /app/crontab-cron /etc/cron.d/
chmod 0644 /etc/cron.d/crontab-cron
crontab /etc/cron.d/crontab-cron

#copy sstp config
#ex: echo "Test message from Linux server using ssmtp" | ssmtp -vvv info@sgd.com.br
#cp /app/ssmtp.conf /etc/ssmtp/

CONTENT=$(cat /app/ssmtp.conf)
eval "echo \"$CONTENT\"" > /etc/ssmtp/ssmtp.conf

ln -sf /usr/share/zoneinfo/Brazil/East /etc/localtime
echo "Brazil/East" > /etc/timezone

service cron start

exec docker-entrypoint.sh mysqld
