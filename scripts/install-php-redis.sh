#!/usr/bin/env bash
set -e

git clone https://github.com/phpredis/phpredis.git

cd phpredis

phpize

./configure

make && make install
