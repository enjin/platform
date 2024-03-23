#!/usr/bin/env bash
set -e


echo $WWWUSER
echo $WWWGROUP
echo $PATH


export DB_HOST=database
export REDIS_HOST=redis
export DECODER_CONTAINER=decoder:8090


role=${CONTAINER_ROLE:-app}


if [ ! -z "$WWWUSER" ]; then
    usermod -u $WWWUSER www-data
    groupmod -g $WWWGROUP www-data
fi

if [ ! -d /.composer ]; then
    mkdir /.composer
fi

chmod -R ugo+rw /.composer

ls -la

echo "Who am i"
whoami

npm install
composer update --prefer-dist --no-dev --no-interaction --ignore-platform-reqs
(cd vendor/gmajor/sr25519-bindings/go && GOFLAGS=-buildvcs=false go build -buildmode=c-shared -o sr25519.so . && mv sr25519.so ../src/Crypto/sr25519.so)


chown -hR www-data:www-data composer.lock
chown -hR www-data:www-data vendor
chown -hR www-data:www-data storage
chown -hR www-data:www-data public

#else
#    exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
#fi


#
#echo "Caching configuration..."
#php artisan cache:clear && php artisan config:cache

#if [ "$role" = "ingest" ]; then
#    echo "Running ingest..."
#    php artisan migrate && php artisan platform:sync && php artisan platform:ingest
#elif [ "$role" = "app" ]; then
    gosu www-data:www-data php artisan log-viewer:publish
    gosu www-data:www-data php artisan platform-ui:install --route="/" --tenant="no" --skip
    gosu www-data:www-data php artisan route:cache
    gosu www-data:www-data php artisan view:cache
    echo "Running apache..."
    exec apache2-foreground
#elif [ "$role" = "websocket" ]; then
#    echo "Running queue and websocket..."
#    supervisord && supervisorctl start horizon
#    php artisan websockets:serve
#elif [ "$role" = "beam" ]; then
#    echo "Running beam..."
#    php artisan platform:process-beam-claims
#else
#    echo "Could not match the container role \"$role\""
#    exit 1
#fi


#
## Source the ".env" file so Laravel's environment variables are available...
## shellcheck source=/dev/null
#if [ -n "$APP_ENV" ] && [ -f ./.env."$APP_ENV" ]; then
#  source ./.env."$APP_ENV";
#elif [ -f ./.env ]; then
#  source ./.env;
#fi
#
## Define environment variables...
#export APP_PORT=${APP_PORT:-80}
#export APP_SERVICE=${APP_SERVICE:-"laravel.test"}
#export DB_PORT=${DB_PORT:-3306}
#export WWWUSER=${WWWUSER:-$UID}
#export WWWGROUP=${WWWGROUP:-$(id -g)}
