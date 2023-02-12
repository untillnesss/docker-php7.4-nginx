ARG ALPINE_VERSION=3.17
FROM alpine:${ALPINE_VERSION}

# Setup document root
WORKDIR /var/www

# Install packages and remove default server definition
RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.13/community" >> /etc/apk/repositories
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
RUN apk add -U php7-dev --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing
RUN apk update && apk upgrade
RUN apk add --no-cache \
  curl \
  nginx \
  php7 \
  php7-ctype \
  php7-curl \
  php7-dom \
  php7-fpm \
  php7-gd \
  php7-intl \
  php7-mbstring \
  php7-mysqli \
  php7-opcache \
  php7-openssl \
  php7-phar \
  php7-session \
  php7-xml \
  php7-xmlreader \
  php7-json \
  php7-exif \
  php7-pcntl \
  php7-fileinfo \
  php7-tokenizer \
  php7-iconv \
  php7-xmlwriter \
  php7-simplexml \
  php7-zip \
  php7-pdo \
  supervisor

# Configure nginx - http
COPY config/nginx.conf /etc/nginx/nginx.conf
# Configure nginx - default server
COPY config/conf.d /etc/nginx/conf.d/

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY config/php.ini /etc/php7/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www /run /var/lib/nginx /var/log/nginx

# Install composer
RUN curl -sS https://getcomposer.org/installer | php7 -- --install-dir=/usr/local/bin --filename=composer

# Switch to use a non-root user from here on
USER nobody

# Add application
COPY --chown=nobody src/ /var/www

RUN php7 /usr/local/bin/composer install

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
