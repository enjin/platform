#!/usr/bin/env bash
set -o allexport
source .env
set +o allexport

export WWWUSER=${WWWUSER:-$UID}
export WWWGROUP=${WWWGROUP:-$(id -g)}

if [ ! -z "$WWWUSER" ]; then
    usermod -u $WWWUSER www-data
    groupmod -g $WWWGROUP www-data
fi

if [ ! -d /.composer ]; then
    mkdir /.composer
fi

chmod -R ugo+rw /.composer

if [ ! "$CONTAINER_ROLE" = "app" ]; then
    wait-for-it -t 900 app:80
fi

if [ ! -d vendor ]; then
    composer install --prefer-dist --no-dev --no-interaction --ignore-platform-reqs
    chown -hR www-data:www-data composer.lock vendor/
fi

chown -hR www-data:www-data storage/ public/

if [ "$CONTAINER_ROLE" = "app" ]; then
    if [ ! -f config/log-viewer.php ]; then
        gosu www-data:www-data php artisan log-viewer:publish
    fi

    if [ ! -f vendor/gmajor/sr25519-bindings/src/Crypto/sr25519.so ]; then
        (cd vendor/gmajor/sr25519-bindings/go && GOFLAGS=-buildvcs=false go build -buildmode=c-shared -o sr25519.so . && mv sr25519.so ../src/Crypto/sr25519.so)
        chown -hR www-data:www-data vendor/gmajor/sr25519-bindings
    fi

    if [ ! -d node_modules ]; then
        npm install
        chown -hR www-data:www-data package-lock.json node_modules/
    fi

    if [ ! -d public/vendor/platform-ui/build ]; then
        # Platform-UI needs to check why we need to run this twice to make it work correctly.
        gosu www-data:www-data php artisan platform-ui:install --route="/" --tenant="no" --skip
        (cd vendor/enjin/platform-ui && npm install && npm run prod-laravel)
        chown -hR www-data:www-data public vendor/enjin/platform-ui
        gosu www-data:www-data php artisan platform-ui:install --route="/" --tenant="no" --skip
    fi

    echo "Running main application..."
    gosu www-data:www-data php artisan optimize
    gosu www-data:www-data php artisan view:cache
    exec apache2-foreground

elif [ "$CONTAINER_ROLE" = "ingest" ]; then
    echo "Running platform ingest..."
    wait-for-it -t 60 database:3306
    gosu www-data:www-data php artisan migrate
    # Remove the need of running two separate commands when possible
    gosu www-data:www-data php artisan platform:sync
    wait-for-it -t 900 decoder:8090
    gosu www-data:www-data php artisan platform:ingest

elif [ "$CONTAINER_ROLE" = "websocket" ]; then
    echo "Running queue and websocket..."
    supervisord -c /etc/supervisor/supervisord.conf
    supervisorctl start horizon
    gosu www-data:www-data php artisan websockets:serve

elif [ "$CONTAINER_ROLE" = "beam" ]; then
    echo "Running beams..."
    gosu www-data:www-data php artisan platform:process-beam-claims

else
    echo "Could not match the container role \"$CONTAINER_ROLE\""
    exit 1
fi
