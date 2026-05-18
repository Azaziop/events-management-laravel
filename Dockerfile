FROM node:20-alpine AS frontend-builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
FROM composer:2 AS vendor-builder
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --ignore-platform-reqs --no-interaction --no-plugins --no-scripts --prefer-dist
FROM php:8.2-fpm-alpine AS runner
RUN apk add --no-cache libpq-dev && docker-php-ext-install pdo pdo_pgsql bcmath
WORKDIR /var/www/html
RUN addgroup -g 1000 laravel && adduser -G laravel -u 1000 -s /bin/sh -D laravel
COPY --chown=laravel:laravel . .
COPY --from=vendor-builder --chown=laravel:laravel /app/vendor ./vendor
COPY --from=frontend-builder --chown=laravel:laravel /app/public/build ./public/build
RUN rm -f public/hot \
    && chown -R laravel:laravel storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache \
    && chmod -R 755 public \
    && find public -type f -exec chmod 644 {} \;
USER laravel
EXPOSE 9000
CMD ["php-fpm"]