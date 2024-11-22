#!/bin/sh

usage() {
    echo -e "             _    __  __     _   _            _                            "
    echo -e " __ __ _____| |__|  \\/  |___| |_| |_  ___  __| |___                        "
    echo -e " \\ V  V / -_) '_ \\ |\\/| / -_)  _| ' \\/ _ \\/ _\` (_-<                        "
    echo -e "  \\_/\\_/\\___|_.__/_|  |_\\___|\\__|_||_\\___/\\__,_/__/_         _        _ _  "
    echo -e "  / __|___ _ _| |_ __ _(_)_ _  ___ _ _  | \\| |_  _| |_ _____| |_  ___| | | "
    echo -e " | (__/ _ \\ ' \\  _/ _\` | | ' \\/ -_) '_| | .\` | || |  _|_ (_-< ' \\/ -_) | | "
    echo -e "  \\___\\___/_||_\\__\\__,_|_|_||_\\___|_|   |_|\\_\\_,_|\\__/__/__/_||_\\___|_|_| "                                                                       
    echo
    echo "A simple script to install and manage webMethods containerized solutions."
    echo 
    echo "Usage: $0 {install|setup|<compose command>} [arguments]"
    echo 
    echo "Commands:"
    echo "  install <target_dir>               Install the project to the specified target directory."
    echo "  setup                              Set up the environment."
    echo
    echo "Compose Commands:"
    docker-compose --help | sed -n '/Commands:/,$p' | sed '1d;$d' | sed 's/^[ \t]*//' | while read -r line; do
        first_word=${line%% *}
        rest_of_line=${line#* }
        rest_of_line=$(echo "$rest_of_line" | sed 's/^[ \t]*//')
        printf "  %-8s %-10s %s\n" "$first_word" "<environment>" "$rest_of_line"
    done
    exit 1
}

command_help() {
    case "$1" in
        install)
            echo "Usage: $0 install <target_dir>"
            echo "Install the project to the specified target directory."
            ;;
        setup)
            echo "Usage: $0 setup"
            echo "Set up the environment."
            ;;
        *)
            usage
            ;;
    esac
    exit 0
}

# Function to install the project
install() {
    if [ "$1" = "--help" ]; then
        command_help install
    fi

    TARGET_DIR=$1
    if [ -z "$TARGET_DIR" ]; then
        echo "Target directory not specified."
        usage
    fi

    # Check if the target directory exists, if not create it
    if [ ! -d "$TARGET_DIR" ]; then
        mkdir -p $TARGET_DIR
    fi

    # Check if the target directory exists and is empty
    if [ -d "$TARGET_DIR" ] && [ "$(ls -A $TARGET_DIR)" ]; then
        echo "Target directory $TARGET_DIR is not empty."
        exit 1
    fi

    echo "Installing project to $TARGET_DIR..."
    # Add installation logic here
    # Enable dotglob to include hidden files
    shopt -s dotglob
    cp -r ./* $TARGET_DIR
    # Disable dotglob
    shopt -u dotglob

    echo "Solution installed successfully to $TARGET_DIR. You should now make all changes in the target folder and ideally commit the changes to a version control system."
    echo "For git users, you can run the following commands to initialize a git repository and commit the changes:"
    echo "cd $TARGET_DIR"
    echo "git init"
    echo "git add ."
    echo "git commit -m 'Initial commit'"
    echo "You can now push the changes to a remote repository using 'git push'."
    echo "Happy coding!"
}

# Function to setup the environment
setup() {
    if [ "$1" = "--help" ]; then
        command_help setup
    fi

    echo "Setting up the environment..."
    # Add setup logic here

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
    if [ -z "$CONTAINERS_USER" ]; then
        read -p "Enter containers.webmethods.io user: " CONTAINERS_USER
    fi

    if [ -z "$CONTAINERS_TOKEN" ]; then
        read -sp "Enter containers.webmethods.io token: " CONTAINERS_TOKEN
        echo
    fi

    # Prompt for packages.webmethods token if not already set
    if [ -z "$PACKAGES_TOKEN" ]; then
        read -sp "Enter packages.webmethods.io token: " PACKAGES_TOKEN
        echo
    fi

    # Store the information in a .env file
    cat <<EOF > .env
CONTAINERS_USER=$CONTAINERS_USER
CONTAINERS_TOKEN=$CONTAINERS_TOKEN
PACKAGES_TOKEN=$PACKAGES_TOKEN
EOF

    echo ".env file created/updated successfully."

}

init() {

    # read .defaults env variables
    if [ -f .defaults ]; then
        . ./.defaults
    else
        echo ".defaults file not found."
    fi

    # Check if the .env file exists
    if [ -f .env ]; then
        echo ".env file found. Exporting variables..."
        set -a
        . ./.env
        set +a
    else
        echo ".env file not found. Please run the setup command to set up the environment."
        exit 1
    fi

    ENVIRONMENT=$1

    # read image name and version from image file in env folder
    if [ -f env/$ENVIRONMENT/.env ]; then
        set -a
        . env/$ENVIRONMENT/.env
        set +a
    else
        echo ".env file not found for target environment (env/$ENVIRONMENT/.env )."
        exit 1
    fi

}



dockercompose() {


    # Check if the command is provided
    if [ -z "$1" ]; then
        usage
    fi

    # Check if the environment is provided
    if [ -z "$2" ]; then
        usage
    fi

    init $2

    # if command is "build" make a docker login
    if [ "$1" = "build" ]; then
        $DOCKER login $CONTAINER_REGISTRY -u "$CONTAINERS_USER" -p "$CONTAINERS_TOKEN"
    fi

    COMMAND=$1
    ENVIRONMENT=$2

    echo "Running docker-compose command: $COMMAND for environment: $ENVIRONMENT"

    # Source the .defaults file to get default arguments
    if [ -f .defaults ]; then
        . ./.defaults
    fi

    # Convert COMMAND to uppercase
    COMMAND_UPPER=$(echo "$COMMAND" | tr '[:lower:]' '[:upper:]')

    # Determine the default arguments for the command
    DEFAULT_ARGS_VAR="${COMMAND_UPPER}_ARGS"
    DEFAULT_ARGS=${!DEFAULT_ARGS_VAR}

    echo "Environment: $ENVIRONMENT"

    # Shift the first 2 arguments (environment and command) and pass the rest to docker-compose
    shift 2
    ENVIRONMENT=$ENVIRONMENT $DOCKER_COMPOSE --project-name $ENVIRONMENT -f compose.yaml $COMMAND $DEFAULT_ARGS "$@"
}

# check if "install" command is provided
if [ "$1" = "install" ]; then
    install $2
    exit 0
fi

# check if "setup" command is provided
if [ "$1" = "setup" ]; then
    setup
    exit 0
fi

# check if a environment is provided and a compose-$2.yaml file exists
if [ -n "$2" ]; then
    
    dockercompose "$@"
    exit 0

else
    usage
fi