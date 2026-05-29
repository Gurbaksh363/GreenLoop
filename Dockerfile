# 1. Use the official PHP image with Apache pre-installed (PHP version 8.3)
FROM php:8.3-apache

# 2. Install essential system tools and libraries required by PHP extensions
# - libpng-dev: Needed for image processing (GD)
# - libzip-dev, zip, unzip: Needed to handle ZIP compression
# - git: Needed by Composer to download dependencies
# - libsqlite3-dev: Needed for our SQLite database
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    libsqlite3-dev \
    nodejs \
    npm \
    && docker-php-ext-install pdo pdo_sqlite gd zip bcmath \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. Enable Apache's mod_rewrite module (critical for Laravel's beautiful URLs / routing)
RUN a2enmod rewrite

# 4. Point Apache's Document Root to Laravel's "public" directory
# Laravel entry point is always "public/index.php" for security and structure
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# 5. Copy the Composer package manager from its official image into ours
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 6. Set our working folder inside the container
WORKDIR /var/www/html

# 7. Copy all of our local project files into the container's working folder
COPY . .

# 7.5 Install PHP dependencies (This creates the vendor/ folder!)
RUN composer install --no-dev --optimize-autoloader

# 7.6 Install Node dependencies and build the frontend assets (Vite)
RUN npm install && npm run build

# 8. Set the correct file permissions so Apache (www-data) can read/write Laravel cache & storage
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# 9. Expose port 80 to the network (Apache's default port)
EXPOSE 80
