#!/usr/bin/env bash
set -o allexport
source .env set
+o allexport

export WWWUSER=${WWWUSER:-$UID}
export WWWGROUP=${WWWGROUP:-$(id -g)}
export ROLE=${CONTAINER_ROLE:-app}
export DB_HOST=${DOCKER_DB_HOST:-database}
export REDIS_HOST=${DOCKER_REDIS_HOST:-redis}
export DECODER_CONTAINER=${DECODER_CONTAINER:-"decoder:8090"}

echo $WWWUSER
echo $WWWGROUP
echo $ROLE
echo $DB_HOST
echo $REDIS_HOST
echo $DECODER_CONTAINER

if [ ! -z "$WWWUSER" ]; then
    usermod -u $WWWUSER www-data
    groupmod -g $WWWGROUP www-data
fi

if [ ! -d /.composer ]; then
    mkdir /.composer
fi

chmod -R ugo+rw /.composer

npm install
composer install --prefer-dist --no-dev --no-interaction --ignore-platform-reqs

if [ ! -f vendor/gmajor/sr25519-bindings/src/Crypto/sr25519.so ]; then
    (cd vendor/gmajor/sr25519-bindings/go && GOFLAGS=-buildvcs=false go build -buildmode=c-shared -o sr25519.so . && mv sr25519.so ../src/Crypto/sr25519.so)
fi

chown -hR www-data:www-data composer.lock package-lock.json vendor/ storage/ public/ node_modules/ vendor/gmajor/sr25519-bindings/

if ! [ -f config/log-viewer.php ]; then
    gosu www-data:www-data php artisan log-viewer:publish
fi

if ! [ -d public/vendor/platform-ui/build ]; then
    # Platform-UI needs to check why we need to run this twice to make it work correctly.
    gosu www-data:www-data php artisan platform-ui:install --route="/" --tenant="no" --skip
    (cd vendor/enjin/platform-ui && npm install && npm run prod-laravel)
    chown -hR www-data:www-data public vendor/enjin/platform-ui
    gosu www-data:www-data php artisan platform-ui:install --route="/" --tenant="no" --skip
fi

if [ "$ROLE" = "app" ]; then
    echo "Running main application..."
    gosu www-data:www-data php artisan optimize
    gosu www-data:www-data php artisan view:cache
    exec apache2-foreground
elif [ "$ROLE" = "ingest" ]; then
    echo "Running platform ingest..."
    gosu www-data:www-data php artisan migrate
    gosu www-data:www-data php artisan platform:sync
    gosu www-data:www-data php artisan platform:ingest
elif [ "$ROLE" = "websocket" ]; then
    echo "Running queue and websocket..."
    supervisord -c /etc/supervisor/supervisord.conf
    supervisorctl start horizon
    gosu www-data:www-data php artisan websockets:serve
elif [ "$ROLE" = "beam" ]; then
    echo "Running beams..."
    gosu www-data:www-data php artisan platform:process-beam-claims
else
    echo "Could not match the container role \"$ROLE\""
    exit 1
fi
