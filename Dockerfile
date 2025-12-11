# -------- Stage 1: Build Composer Dependencies --------
FROM php:7.4-fpm AS build

RUN apt-get update && apt-get install -y \
    zip unzip git curl libpq-dev libonig-dev libzip-dev

# Install required PHP extensions
RUN docker-php-ext-install pdo pdo_mysql pdo_pgsql mbstring zip

WORKDIR /app

COPY composer.json composer.lock ./

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

RUN composer install --no-dev --optimize-autoloader

COPY . .

# -------- Stage 2: Production Image --------
FROM php:7.4-fpm

RUN apt-get update && apt-get install -y \
    nginx git curl zip unzip supervisor

# Install extensions again
RUN docker-php-ext-install pdo pdo_mysql pdo_pgsql mbstring zip

WORKDIR /var/www/html
COPY --from=build /app ./

# Copy Nginx configuration
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# Supervisor to run Nginx + PHP-FPM
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 10000

CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
