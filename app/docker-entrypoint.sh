#!/bin/bash

# Install packages
apt-get update
apt-get install cron -y
apt-get install zip -y
apt-get install unzip -y
apt-get install ssmtp -y
apt-get install curl -y
apt-get install openssh-server -y  # Adiciona o servidor SSH

# Install cron
cp /app/crontab-cron /etc/cron.d/
chmod 0644 /etc/cron.d/crontab-cron
crontab /etc/cron.d/crontab-cron

# Copy ssmtp config
CONTENT=$(cat /app/ssmtp.conf)
eval "echo \"$CONTENT\"" > /etc/ssmtp/ssmtp.conf

# Set timezone
ln -sf /usr/share/zoneinfo/Brazil/East /etc/localtime
echo "Brazil/East" > /etc/timezone

# Configure SSH
mkdir -p /root/.ssh
touch /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

# Configure SSH to use port 2222
sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config  # Permite login como root (ajuste conforme necessário)

# Start services
/app/add_ssh_keys.sh
#/app/var.sh

service cron start
service ssh start  # Inicia o servidor SSH

exec docker-entrypoint.sh mysqld