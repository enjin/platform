# State: setup-web-server
FROM php:8.3-apache AS setup-container-dependencies
LABEL maintainer="Enjin"

WORKDIR /var/www/html

# Install dependencies
RUN apt-get update -y && \
    apt-get install -y gnupg gosu curl ca-certificates zip unzip git supervisor sqlite3 libcap2-bin libpng-dev dh-python && \
    apt-get install -y libpq-dev libgmp-dev libsodium-dev libmemcached-dev zlib1g-dev wait-for-it libffi-dev golang-go && \
    apt-get install -y inotify-tools libcurl4-openssl-dev libpq-dev libssl-dev supervisor dos2unix

# Install imagick and redis
RUN apt-get install -y libmagickwand-dev --no-install-recommends && \
    pecl install imagick redis

# Install node and npm
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

# Install and enable additional php modules
RUN docker-php-ext-install ffi pdo pdo_mysql gmp bcmath sodium mysqli sockets pcntl gd
RUN docker-php-ext-enable redis imagick

# Clean up not needed dependencies
run apt-get -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Stage: composer-update
FROM setup-container-dependencies AS setup-application-dependencies
WORKDIR /var/www/html

COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer
COPY composer.json composer.json

RUN composer update --prefer-dist --no-dev --no-interaction --ignore-platform-reqs --no-scripts
RUN cd vendor/gmajor/sr25519-bindings/go && go build -buildmode=c-shared -o sr25519.so . && mv sr25519.so ../src/Crypto/sr25519.so

# Stage: http setup
FROM setup-application-dependencies AS setup-http-server

RUN echo 'ServerName localhost' >> /etc/apache2/apache2.conf
RUN update-rc.d supervisor defaults
RUN a2enmod rewrite

COPY docker/apache/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY docker/php /usr/local/etc/php/conf.d
COPY docker/supervisor /etc/supervisor

# Stage: platform-core
FROM setup-http-server AS enjin-platform

LABEL org.opencontainers.image.source=https://github.com/enjin/platform
LABEL org.opencontainers.image.description="Enjin Platform - The most powerful and advanced open-source framework for building NFT platforms."
LABEL org.opencontainers.image.licenses=LGPL-3.0-only

WORKDIR /var/www/html

COPY docker/start.sh /usr/local/bin/start.sh
RUN dos2unix /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

#RUN dos2unix /var/www/html/.env

EXPOSE 8000

#USER www-data

CMD ["/usr/local/bin/start.sh"]
