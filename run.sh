#!/bin/bash

set -e  # Exit the script on any error

# Specify the path to the var.env file
env_file="app/var.env"

# Check if the file exists
if [ ! -f "$env_file" ]; then
    echo "File $env_file not found!"
    exit 1
fi

# Read the file line by line and set the environment variables
while IFS='=' read -r key value; do
    if [[ ! -z "$key" ]]; then
        export "$key=$value"
        echo "Setting $key=$value"
    fi
done < "$env_file"

export PROJECT_PATH=$(pwd)
echo "Setting PROJECT_PATH=$PROJECT_PATH"

# Create the directories if they don't exist
[ ! -d "app" ] && mkdir "app"
[ ! -d "data" ] && mkdir "data"
[ ! -d "log" ] && mkdir "log"

# Docker Compose: bring down, build, and bring up the containers
docker-compose down
docker-compose build
docker-compose up -d

# Ask the user if they want to enter the container shell
read -p "Do you want to enter the container shell? (y/n): " confirm

if [[ "$confirm" =~ ^[Yy]$ ]]; then
    docker exec -it "$COMICRACK_CONTAINER" /bin/bash
else
    echo "Command canceled."
fi
