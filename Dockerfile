# -------- Stage 1: Build Composer Dependencies --------
FROM php:7.4-fpm AS build

RUN apt-get update && apt-get install -y \
    zip unzip git curl libzip-dev libpng-dev libonig-dev

# Install PHP extensions needed for Laravel + MySQL
RUN docker-php-ext-install pdo pdo_mysql mbstring zip

WORKDIR /app

COPY composer.json composer.lock ./

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer --version=2.2.0

COPY . .
# Install dependencies
RUN composer install --no-dev --optimize-autoloader



# -------- Stage 2: Production Image --------
FROM php:7.4-fpm

RUN apt-get update && apt-get install -y \
    nginx git curl zip unzip supervisor libzip-dev libpng-dev libonig-dev

# Install required PHP extensions again (NO PostgreSQL)
RUN docker-php-ext-install pdo pdo_mysql mbstring zip

WORKDIR /var/www/html

COPY --from=build /app ./

# Copy Nginx configuration
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# Supervisor config (runs PHP-FPM + Nginx)
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 10000

# Fix permissions for Laravel
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
