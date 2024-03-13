# Stage: setup-web-server
FROM php:apache-buster AS setup-web-server

# Install dependencies
RUN apt-get update -y && \
    apt-get install -y gnupg gosu curl ca-certificates zip unzip git supervisor sqlite3 libcap2-bin libpng-dev python2 && \
    apt-get install -y libpq-dev libgmp-dev libsodium-dev libmemcached-dev zlib1g-dev wait-for-it libffi-dev golang-go && \
    apt-get install -y inotify-tools libcurl4-openssl-dev libpq-dev libssl-dev supervisor dos2unix

# Install imagick and redis
RUN apt-get install -y libmagickwand-dev --no-install-recommends && \
    pecl install imagick redis

# Install node and npm
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - &&\
    apt-get install -y nodejs

# Install and enable additional php modules
RUN docker-php-ext-install ffi pdo pdo_mysql gmp bcmath sodium mysqli sockets pcntl gd
RUN docker-php-ext-enable redis imagick

# Stage: create-application
FROM setup-web-server AS create-application

WORKDIR /app/
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

RUN composer create-project laravel/laravel:^10.0 laravel-application

COPY configs/core/composer.json /app/laravel-application
COPY configs/core/config/ /app/laravel-application/config/
COPY configs/core/routes/ /app/laravel-application/routes/

# Stage: composer-update
FROM create-application AS composer-update

RUN cd laravel-application && \
    composer update --prefer-dist --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs

# Builds sr25519 go library
RUN cd /app/laravel-application/vendor/gmajor/sr25519-bindings/go && go build -buildmode=c-shared -o sr25519.so . && mv sr25519.so ../src/Crypto/sr25519.so

# Stage: http setup
FROM create-application AS http-setup

# Set ServerName to be localhost.
RUN echo 'ServerName localhost' >> /etc/apache2/apache2.conf

# Copy application to /var/www/html.
COPY --from=composer-update /app/laravel-application /var/www/html

# Copy envs.
COPY configs/core/.env /var/www/html/.env
RUN dos2unix /var/www/html/.env

# Set permissions and ownership.
RUN chmod 777 -R /var/www/html/storage/
RUN chown -R www-data:www-data /var/www/ /var/log/supervisor

# Enable mod rewrite.
RUN update-rc.d supervisor defaults
RUN a2enmod rewrite

# Copy virtualhost configuration.
COPY configs/core/apache/000-default.conf /etc/apache2/sites-available/000-default.conf

# Copy php configs.
COPY configs/core/php /usr/local/etc/php/conf.d
COPY configs/core/supervisor /etc/supervisor

# Stage: platform-core
FROM http-setup AS enjin-platform

LABEL org.opencontainers.image.source=https://github.com/enjin/platform
LABEL org.opencontainers.image.description="Enjin Platform - The most powerful and advanced open-source framework for building NFT platforms."
LABEL org.opencontainers.image.licenses=LGPL-3.0-only

WORKDIR /var/www/html

COPY configs/core/start.sh /usr/local/bin/start.sh
RUN dos2unix /usr/local/bin/start.sh

USER www-data
CMD ["/usr/local/bin/start.sh"]
