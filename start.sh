#!/usr/bin/env sh

detect_user_os() {
  case "$OSTYPE" in
    darwin*)  PLATFORM_OS="macOS"  ;;
    linux*)   PLATFORM_OS="linux"  ;;
    *)        echo "Our start script only supports macOS and Linux at this moment" | exit 1 ;;
  esac
}

generate_app_key() {
  # Generate a new app key and set to .env file
  RANDOM_KEY=base64:$(openssl rand -base64 32)
  LARAVEL_KEY=$(printf '%s\n' "$RANDOM_KEY" | sed -e 's/[\/&]/\\&/g')

  if [ "$PLATFORM_OS" = "macOS" ]; then
    sed -i '' -e "s/^APP_KEY=/APP_KEY=$LARAVEL_KEY/g" configs/core/.env
  else
    sed -i "s/^APP_KEY=/APP_KEY=$LARAVEL_KEY/g" configs/core/.env
  fi

  echo "Done, your key is: $LARAVEL_KEY"
}

check_has_app_key() {
  # Check if user already has APP_KEY set
  APP_KEY=$(awk '$1 ~ /^APP_KEY/' configs/core/.env | cut -d "=" -f 2)
  if [ -z "$APP_KEY" ]; then
      echo "Laravel uses an app key to protect your data with encryption"
      echo "Your APP_KEY is not set, do you want to generate one? (y/n)"
      read generate_app_key

      if [ "$generate_app_key" = "${generate_app_key#[Yy]}" ] ;then
          echo "Please set APP_KEY in configs/core/.env and run this script again"
          exit 1
      else
          generate_app_key
      fi
  fi
}

generate_basic_token() {
    # Generate a new basic auth token and set to .env file
    BASIC_TOKEN=$(openssl rand -hex 32)
    echo "Done, your basic static token is: $BASIC_TOKEN"

    if [ "$PLATFORM_OS" = "macOS" ]; then
      sed -i '' -e "s/^BASIC_AUTH_TOKEN=/BASIC_AUTH_TOKEN=$BASIC_TOKEN/g" configs/core/.env
      sed -i '' -e "s/^PLATFORM_KEY=/PLATFORM_KEY=$BASIC_TOKEN/g" configs/daemon/.env
    else
      sed -i "s/^BASIC_AUTH_TOKEN=/BASIC_AUTH_TOKEN=$BASIC_TOKEN/g" configs/core/.env
      sed -i "s/^PLATFORM_KEY=/PLATFORM_KEY=$BASIC_TOKEN/g" configs/daemon/.env
    fi
}

check_has_basic_token() {
  # Check if user already has BASIC_AUTH_TOKEN set
  AUTH_TOKEN=$(awk '$1 ~ /^BASIC_AUTH_TOKEN/' configs/core/.env | cut -d "=" -f 2)
  if [ -z "$AUTH_TOKEN" ]; then
      echo "We also use a static token to protect your platform from unauthorized access"
      echo "Your BASIC_AUTH_TOKEN is not set, do you want to generate one? (y/n)"
      read generate_token

      if [ "$generate_token" = "${generate_token#[Yy]}" ] ;then
          echo "Please set BASIC_AUTH_TOKEN in configs/core/.env and run this script again"
          exit 1
      else
          generate_basic_token
      fi
  fi
}

generate_daemon_password() {
  # Generate a new key pass for the daemon and set to .env file
  WALLET_PASSWORD=$(openssl rand -hex 32)
  echo "Done, your daemon password is: $WALLET_PASSWORD"
  sed -i '' -e "s/^KEY_PASS=/KEY_PASS=$WALLET_PASSWORD/g" configs/daemon/.env

  if [ "$PLATFORM_OS" = "macOS" ]; then
    sed -i '' -e "s/^KEY_PASS=/KEY_PASS=$WALLET_PASSWORD/g" configs/daemon/.env
  else
    sed -i "s/^KEY_PASS=/KEY_PASS=$WALLET_PASSWORD/g" configs/daemon/.env
  fi
}

check_has_daemon_password() {
    # Check if user already has KEY_PASS set
    KEY_PASS=$(awk '$1 ~ /^KEY_PASS/' configs/daemon/.env | cut -d "=" -f 2)
    if [ -z "$KEY_PASS" ]; then
        echo "Finally, we also use a password to protect your wallet daemon"
        echo "Your KEY_PASS is not set, do you want to generate one? (y/n)"
        read generate_daemon

        if [ "$generate_daemon" = "${generate_daemon#[Yy]}" ] ;then
            echo "Please set KEY_PASS in configs/daemon/.env and run this script again"
            exit 1
        else
            generate_daemon_password
        fi
    fi
}

get_daemon_address() {
    # Check if user already has DAEMON_ACCOUNT set
    DAEMON_ACCOUNT=$(awk '$1 ~ /^DAEMON_ACCOUNT/' configs/core/.env | cut -d "=" -f 2)
    if [ -z "$DAEMON_ACCOUNT" ]; then
        echo "Let's get your wallet daemon address, please wait..."
        (docker compose up -d daemon)
        WALLET_ADDRESS=$(docker compose logs daemon 2>&1 | grep "Rocfinity address:" | awk '{print $NF}' | tail -n 1)
        echo "Your wallet daemon address is: $WALLET_ADDRESS"

        if [ "$PLATFORM_OS" = "macOS" ]; then
          sed -i '' -e "s/^DAEMON_ACCOUNT=/DAEMON_ACCOUNT=$WALLET_ADDRESS/g" configs/core/.env
        else
          sed -i "s/^DAEMON_ACCOUNT=/DAEMON_ACCOUNT=$WALLET_ADDRESS/g" configs/core/.env
        fi

    else
        echo "Your wallet daemon address is: $DAEMON_ACCOUNT"
    fi
}

check_docker_is_installed() {
  if ! [ -x "$(command -v docker)" ]; then
      echo "Please install docker and run this script again"
      exit 1
  fi
}

check_compose_is_installed() {
  if ! [ "$(docker compose --version)" ]; then
      echo "Please install docker compose and run this script again"
  fi
}

check_docker_is_running() {
  if ! [ "$(docker ps)" ]; then
      echo "Please start docker and run this script again"
      exit 1
  fi
}

check_openssl_is_installed() {
  if ! [ "$(openssl version)" ]; then
      echo "Please install OpenSSL and run this script again"
      exit 1
  fi
}

check_git_is_installed() {
  if ! [ "$(git --version)" ]; then
      echo "Please install git and run this script again"
      exit 1
  fi
}

# This might be removed if Polkadart removes the lfs dependency
check_lfs_is_installed() {
  if ! [ "$(git lfs --version)" ]; then
      echo "Please install git lfs and run this script again"
      exit 1
  fi
}

echo "Welcome to Enjin Platform, this script will help you start it up"
detect_user_os
check_git_is_installed
check_lfs_is_installed
check_openssl_is_installed
check_docker_is_installed
check_compose_is_installed
check_docker_is_running

git submodule update --init

check_has_app_key
check_has_basic_token
check_has_daemon_password

docker compose build daemon
get_daemon_address

echo "Do you want to start all platform services? (y/n)"
read start_services

if [ "$start_services" != "${start_services#[Yy]}" ] ;then
    docker compose build
    docker compose up -d
    echo "Your Enjin Platform is now running, please visit: http://localhost:8000/graphiql"
else
    docker compose down
    echo "Please run this script again when you are ready"
    exit 1
fi
