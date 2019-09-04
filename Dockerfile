FROM php:7.1.30-fpm-alpine3.10 as builder

LABEL version="0.0.1"
LABEL repository="https://github.com/robjmills/github-actions-php"
LABEL homepage="https://github.com/robjmills/github-actions-php"
LABEL maintainer="Rob Mills <robjmills@gmail.com>"

LABEL com.github.actions.name="PHP container"
LABEL com.github.actions.description="PHP container with the things I need."
LABEL com.github.actions.icon="globe"
LABEL com.github.actions.color="purple"

RUN apk add --no-cache \
    zlib-dev \
    libpng-dev \
    jpeg-dev \
    libjpeg-turbo \
    imagemagick-dev \
    libtool \
    tidyhtml-dev \
    icu-dev \
    libxml2-dev \
    pcre-dev \
	libmcrypt-dev \
    g++ \
    git \
    make \
    autoconf

RUN docker-php-ext-configure gd --with-jpeg-dir=/usr/lib \
    && docker-php-ext-install \
    pdo_mysql \
    mbstring \
    pcntl \
    exif \
    opcache \
    mcrypt \
	gd \
    zip \
    tidy \
    intl \
    soap \
    bcmath

RUN pecl install \
    redis-3.1.6 \
    imagick-3.4.3 \
    apcu-5.1.11 \
    xdebug-2.6.0 \
    && docker-php-ext-enable redis imagick apcu

RUN git clone git://github.com/absalomedia/sassphp /usr/src/php/ext/sass \
    && cd /usr/src/php/ext/sass \
    && git submodule init \
    && git submodule update \
    && cd lib/libsass \
    && make \
    && cd ../../ \
    && phpize \
    && ./configure \
    && make \
    && make install \
    && docker-php-ext-enable sass

RUN git clone --recursive --depth=1 https://github.com/kjdev/php-ext-zstd.git /usr/src/php/ext/zstd \
    && cd /usr/src/php/ext/zstd \
    && phpize \
    && ./configure \
    && make \
    && make install \
    && docker-php-ext-enable zstd

FROM php:7.1.30-fpm-alpine3.10

# Change www-data uid and gid from 82 to 33
RUN sed -i 's/33/32/g' /etc/passwd /etc/group \
    && sed -i 's/82/33/g' /etc/passwd /etc/group

ENV PHP_INI_SCAN_DIR=:/usr/local/etc/php-fpm/ini
RUN mkdir -p /usr/local/etc/php-fpm/conf /usr/local/etc/php-fpm/ini \
    && echo -e "include=etc/php-fpm/conf/*.conf" >> /usr/local/etc/php-fpm.conf \
	&& touch /usr/local/etc/php-fpm/conf/peaceholder.conf

RUN apk add --no-cache \
    zlib \
    libpng \
    libjpeg \
    libjpeg-turbo \
    tidyhtml-libs \
    icu-libs \
    libxml2 \
    imagemagick \
	libmcrypt \
    git \
    openssl

RUN apk add gnu-libiconv --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ --allow-untrusted
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

RUN mkdir /var/log/php-fpm

COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/

COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

RUN echo -e "expose_php=Off\ndisplay_errors=Off\npost_max_size=20M\nupload_max_filesize=20M\nerror_reporting=22527\nmemory_limit=256M" > /usr/local/etc/php/conf.d/0-default.ini
