#!/bin/sh

# Check if .env file exists
if [ ! -f .env ]; then
  echo ".env file does not exist, please run setup.sh first."
  exit 1
fi

# Source the .env file to export variables
set -a
. ./.env
set +a

# Authenticate with Docker using CONTAINERS_USER and CONTAINERS_TOKEN
$CLI_COMMAND login sagcr.azurecr.io -u "$CONTAINERS_USER" -p "$CONTAINERS_TOKEN"
if [ $? -ne 0 ]; then
  echo "Docker login failed. Please check your credentials."
  exit 1
fi

# Check if a profile is provided as the first argument
if [ -z "$1" ]; then
  echo "No profile specified. Usage: ./start.sh <profile>"
  exit 1
fi

PROFILE=$1

# read image name and version from image file in env folder
if [ -f $PROFILE/env/image ]; then
  IMAGE_NAME=$(cat  $PROFILE/env/image | cut -d: -f1)
  IMAGE_VERSION=$(cat  $PROFILE/env/image | cut -d: -f2)
else
  echo "Image file not found. Please run build.sh first."
  exit 1
fi

# Run docker-compose up in detached mode with the specified profile
PACKAGES_TOKEN=$PACKAGES_TOKEN $CLI_COMMAND compose --profile $PROFILE up -d