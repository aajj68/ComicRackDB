# Specify the path to the var.env file
env_file="/app/var.env"

# Check if the file exists
if [ ! -f "$env_file" ]; then
    echo "File $env_file not found!"
    exit 1
fi

# Read the file line by line and set the environment variables
while IFS='=' read -r key value; do
    if [[ ! -z "$key" ]]; then
        export "$key=$value"
        #echo "Setting $key=$value"
    fi
done < "$env_file"
