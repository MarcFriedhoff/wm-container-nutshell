#!/bin/sh

# Function to display usage
usage() {
    echo "Usage: $0 {install|setup|setcontext|build|start|stop|logs} [arguments]"
    echo
    echo "Commands:"
    echo "  install <target_dir>               Install the project to the specified target directory."
    echo "  setup                              Set up the environment."
    echo "  setcontext <context>               Set the context to the specified value."
    echo "  build -i <image-name> -t <tag>     Build the project."
    echo "  start <profile>                    Start the services with the specified profile."
    echo "  stop <profile>                     Stop the services."
    echo "  logs <profile>                     View logs for the specified profile."
    exit 1
}

# Function to display help for a specific command
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
        setcontext)
            echo "Usage: $0 setcontext <context>"
            echo "Set the context to the specified value."
            ;;
        build)
            echo "Usage: $0 build -i <image-name> -t <image-version>"
            echo "Build the project."
            ;;
        start)
            echo "Usage: $0 start <profile>"
            echo "Start the services with the specified profile."
            ;;
        stop)
            echo "Usage: $0 stop <profile>"
            echo "Stop the services with the specified profile."
            ;;
        logs)
            echo "Usage: $0 logs <profile>"
            echo "View logs for the specified profile."
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
    cp -r ./* $TARGET_DIR

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
COMMAND_CLI=podman
EOF

    echo ".env file created/updated successfully."

}

# Function to set context
setcontext() {
    if [ "$1" = "--help" ]; then
        command_help setcontext
    fi

    CONTEXT=$1
    if [ -z "$CONTEXT" ]; then
        echo "Context not specified."
        command_help setcontext
    fi
    echo "Setting context to $CONTEXT..."

    # check if argument for profile is provided
    if [ -z "$1" ]; then
        command_help setcontext
    fi

    PROFILE=$1

    # Check if .env file exists
    if [ ! -f .env ]; then
        echo ".env file does not exist, please run setup.sh first."
        exit 1
    fi

    # Source the .env file to export variables
    set -a
    . ./.env
    set +a

    if [ -f env/$CONTEXT/.env ]; then
        set -a
        . env/$CONTEXT/.env
        set +a
    else
        echo ".env file not found for target profile (env/$CONTEXT/.env)."
        exit 1
    fi

    echo "Context set for profile $CONTEXT"
}

# Function to build the project
build() {
    if [ "$1" = "--help" ]; then
        command_help build
    fi

    # Add build logic here
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
        command_help build
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
}

# Function to start the services
start() {
    if [ "$1" = "--help" ]; then
        command_help start
    fi

    PROFILE=$1
    if [ -z "$PROFILE" ]; then
        echo "Profile not specified."
        usage
    fi
    echo "Starting services with profile $PROFILE..."
    # Add start logic here

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
    if [ -f env/$PROFILE/.env ]; then
        set -a
        . env/$PROFILE/.env
        set +a
    else
        echo ".env file not found for target profile (env/$PROFILE/.env )."
        exit 1
    fi

    # Run docker-compose up in detached mode with the specified profile
    PACKAGES_TOKEN=$PACKAGES_TOKEN $CLI_COMMAND compose --profile $PROFILE up -d
}

# Function to stop the services
stop() {
    if [ "$1" = "--help" ]; then
        command_help stop
    fi

    echo "Stopping services..."
    # Add stop logic here
    # check if argument for profile is provided
    if [ -z "$1" ]; then
        echo "No profile specified. Usage: ./stop.sh <profile>"
        exit 1
    fi

    PROFILE=$1

    # Check if .env file exists

    if [ ! -f .env ]; then
        echo ".env file does not exist, please run setup.sh first."
        exit 1
    fi

    # Source the .env file to export variables
    set -a
    . ./.env
    set +a

    if [ -f env/$PROFILE/.env ]; then
        set -a
        . env/$PROFILE/.env
        set +a
    else
        echo ".env file not found for target profile (env/$PROFILE/.env)."
        exit 1
    fi


    # stop container via docker-compose and PROFILE
    $CLI_COMMAND compose --profile $PROFILE down
}

# Function to view logs
logs() {
    if [ "$1" = "--help" ]; then
        command_help logs
    fi

    PROFILE=$1
    if [ -z "$PROFILE" ]; then
        echo "Profile not specified."
        usage
    fi
    echo "Viewing logs for profile $PROFILE..."

    . ./.env

    $CLI_COMMAND compose logs is-$1-server -f
}

# Main script logic
COMMAND=$1
shift

case "$COMMAND" in
    install)
        install "$@"
        ;;
    setup)
        setup "$@"
        ;;
    setcontext)
        setcontext "$@"
        ;;
    build)
        build "$@"
        ;;
    start)
        start "$@"
        ;;
    stop)
        stop "$@"
        ;;
    logs)
        logs "$@"
        ;;
    *)
        usage
        ;;
esac