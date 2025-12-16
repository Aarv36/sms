# -------- Stage 1: Build Composer Dependencies --------
FROM php:7.4-fpm AS build

RUN apt-get update && apt-get install -y \
    zip unzip git curl libpq-dev libonig-dev libzip-dev \
    nodejs npm

# Install required PHP extensions
RUN docker-php-ext-install pdo pdo_mysql mbstring zip

WORKDIR /app

COPY composer.json composer.lock ./
COPY package.json package-lock.json* ./

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

COPY . .

RUN composer install --no-dev --optimize-autoloader

RUN npm install

RUN npm run prod
# -------- Stage 2: Production Image --------
FROM php:7.4-fpm

RUN apt-get update && apt-get install -y \
    nginx supervisor zip unzip curl libzip-dev libpng-dev libonig-dev

# Install extensions again
RUN docker-php-ext-install pdo pdo_mysql mbstring zip

WORKDIR /var/www/html
COPY --from=build /app ./

# Copy Nginx configuration
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# Supervisor to run Nginx + PHP-FPM
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 10000

RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
