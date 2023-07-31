#!/usr/bin/env bash
set -e

role=${CONTAINER_ROLE:-app}

if [ "$role" = "ingest" ]; then
    echo "Running ingest..."
    (php artisan cache:clear && php artisan config:cache && php artisan migrate && php artisan platform:sync && php artisan platform:ingest)
elif [ "$role" = "app" ]; then
    echo "Caching configuration..."
    php artisan platform-ui:install --host="http://localhost:8000" --route="/" --tenant="no" --skip && php artisan cache:clear && php artisan config:cache && php artisan route:cache && php artisan view:cache
    echo "Running apache..."
    exec apache2-foreground
elif [ "$role" = "websocket" ]; then
    echo "Running queue and websocket..."
    php artisan cache:clear && php artisan config:cache
    supervisord -n --configuration /etc/supervisor/supervisord.conf
elif [ "$role" = "beam" ]; then
    echo "Running beam..."
    (php artisan cache:clear && php artisan config:cache && php artisan platform:process-beam-claims)
else
    echo "Could not match the container role \"$role\""
    exit 1
fi
