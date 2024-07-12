#!/usr/bin/env bash
set -e

role=${CONTAINER_ROLE:-app}

echo "Caching configuration..."
php artisan cache:clear && php artisan config:cache

if [ "$role" = "ingest" ]; then
    echo "Running ingest..."
    php artisan migrate && php artisan platform:sync && php artisan platform:ingest
elif [ "$role" = "app" ]; then
    php artisan platform-ui:install --route="/" --tenant="no" --skip && php artisan route:cache && php artisan view:cache
    echo "Running apache..."
    exec apache2-foreground
elif [ "$role" = "relay" ]; then
    echo "Running relay watcher..."
    php artisan platform:relay-watcher
elif [ "$role" = "websocket" ]; then
    echo "Running queue and websocket..."
    supervisord && supervisorctl start horizon
    php artisan websockets:serve
elif [ "$role" = "beam" ]; then
    echo "Running beam..."
    php artisan platform:process-beam-claims
else
    echo "Could not match the container role \"$role\""
    exit 1
fi
