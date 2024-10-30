#!/bin/sh
WPM_DOWNLOAD_URL=https://softwareag-usa.s3.amazonaws.com/webMethods/Service+Designer/wpm.zip

# check if a license file is provided in the licence folder
if [ ! -f ./license/licenseKey.xml ]; then
  echo "License file not found. Please add a license file to the license folder."
  exit 1
fi

# check if wpm folder exists, if not download the wpm binary from the following url https://softwareag-usa.s3.amazonaws.com/webMethods/Service+Designer/wpm.zip using curl
if [ ! -d ./wpm ]; then
  echo "WPM folder not found. Do you want to download the WPM binary?"
  read -p "Do you want to download the WPM binary? (y/n): " DOWNLOAD_WPM
  if [ "$DOWNLOAD_WPM" != "y" ]; then
    echo "WPM binary not downloaded. Exiting..."
    exit 1
  fi
  echo "Downloading WPM binary from $WPM_DOWNLOAD_URL..."
  curl -L $WPM_DOWNLOAD_URL -o wpm.zip
  # unzip to tmp and move the wpm folder wpm to the current directory
  unzip wpm.zip -x "__MACOSX/*"
  mv wpm/wpm ./wpm
  rm /tmp/wpm.zip
fi

# Check if .env file exists
if [ -f .env ]; then
  echo ".env file found. Exporting variables..."
  set -a
  . ./.env
  set +a
else
  echo ".env file not found. Proceeding to prompt for input..."
fi

# Prompt for containers.webmethods.io user and token if not already set
if [ -z "$CONTAINER_USER" ]; then
  read -p "Enter containers.webmethods.io user: " CONTAINER_USER
fi

if [ -z "$CONTAINER_TOKEN" ]; then
  read -sp "Enter containers.webmethods.io token: " CONTAINER_TOKEN
  echo
fi

# Prompt for packages.webmethods token if not already set
if [ -z "$PACKAGES_TOKEN" ]; then
  read -sp "Enter packages.webmethods.io token: " PACKAGES_TOKEN
  echo
fi

# Store the information in a .env file
cat <<EOF > .env
CONTAINER_USER=$CONTAINER_USER
CONTAINER_TOKEN=$CONTAINER_TOKEN
PACKAGES_TOKEN=$PACKAGES_TOKEN
EOF

echo ".env file created/updated successfully."