#!/bin/sh

echo "Build a solution image"

# get arguments for -image and -tag
while getopts i:t: flag
do
    case "${flag}" in
        i) SOLUTION_IMAGE_NAME=${OPTARG};;
        t) SOLUTION_IMAGE_VERSION=${OPTARG};;
    esac
done

# Check if SOLUTION_IMAGE_NAME and SOLUTION_IMAGE_VERSION are set
if [ -z "$SOLUTION_IMAGE_NAME" ] || [ -z "$SOLUTION_IMAGE_VERSION" ]; then
  echo "Usage: ./build.sh -i <image-name> -t <image-version>"
  exit 1
fi

# Check if .env file exists
if [ ! -f .env ]; then
  echo ".env file does not exist, please run setup.sh first."
  exit 1
fi

# Source the .env file to export variables
set -a
. ./.env
set +a

$CLI_COMMAND build . --build-arg WPM_ACCESS_TOKEN=${PACKAGES_TOKEN} -t $SOLUTION_IMAGE_NAME:$SOLUTION_IMAGE_VERSION