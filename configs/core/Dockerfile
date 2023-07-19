# Stage: setup-web-server
FROM php:apache-buster as setup-web-server

# Install dependencies.
RUN apt-get update -y && \
    apt-get install -y gnupg gosu curl ca-certificates zip unzip git supervisor sqlite3 libcap2-bin libpng-dev python2 && \
    apt-get install -y libpq-dev libgmp-dev libsodium-dev libmemcached-dev zlib1g-dev wait-for-it libffi-dev golang-go && \
    apt-get install -y inotify-tools libcurl4-openssl-dev libpq-dev libssl-dev supervisor

# Install node and npm
RUN curl -sL https://deb.nodesource.com/setup_16.x -o /tmp/nodesource_setup.sh
RUN bash /tmp/nodesource_setup.sh
RUN apt-get install -y nodejs

COPY scripts/ /usr/scripts/

RUN docker-php-ext-install ffi pdo pdo_mysql gmp bcmath sodium mysqli sockets pcntl

RUN /usr/scripts/install-php-redis.sh

RUN docker-php-ext-enable redis

# Stage: create-application
FROM setup-web-server as create-application

WORKDIR /app/
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

RUN composer create-project laravel/laravel:^10.0 laravel-application

COPY configs/core/composer.json /app/laravel-application
COPY configs/core/config/ /app/laravel-application/config/

# Stage: composer-update
FROM create-application as composer-update

RUN cd laravel-application && \
    composer update --prefer-dist --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs

# Builds sr25519 go library
RUN cd /app/laravel-application/vendor/gmajor/sr25519-bindings/go && go build -buildmode=c-shared -o sr25519.so . && mv sr25519.so ../src/Crypto/sr25519.so

# Stage: http setup

FROM create-application as http-setup

# Set apache to listen on port 8000.
RUN sed -i "s/Listen 80/Listen 8000/" /etc/apache2/ports.conf

# Set ServerName to be localhost.
RUN echo 'ServerName localhost' >> /etc/apache2/apache2.conf

# Copy application to /var/www/html.
COPY --from=composer-update /app/laravel-application /var/www/html

# Copy envs.
COPY configs/core/.env /var/www/html/.env

# Set permissions and ownership.
RUN chmod 777 -R /var/www/html/storage/
RUN chown -R www-data:www-data /var/www/

# Enable mod rewrite.
RUN update-rc.d supervisor defaults
RUN a2enmod rewrite

# Copy virtualhost configuration.
COPY configs/core/apache/000-default.conf /etc/apache2/sites-available/000-default.conf

# Copy php configs.
COPY configs/core/php /usr/local/etc/php/conf.d
COPY configs/core/supervisor /etc/supervisor/conf.d

# Stage: platform-core
FROM http-setup as enjin-platform

LABEL org.opencontainers.image.source=https://github.com/enjin/platform
LABEL org.opencontainers.image.description="Enjin Platform - The most powerful and advanced open-source framework for building NFT platforms."
LABEL org.opencontainers.image.licenses=LGPL-3.0-only

WORKDIR /var/www/html
COPY configs/core/start.sh /usr/local/bin/start

CMD ["/usr/local/bin/start"]
