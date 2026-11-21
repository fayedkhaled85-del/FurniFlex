FROM php:8.5.12-apache-bookworm
RUN docker-php-ext-install pdo_mysql && php -r 'foreach (["pdo_mysql","fileinfo","mbstring"] as $extension) if (!extension_loaded($extension)) exit(1);'
COPY deploy/site.conf /etc/apache2/conf-enabled/furniflex.conf
RUN sed -i 's#DocumentRoot /var/www/html#DocumentRoot /var/www/html/FurniFlex#' /etc/apache2/sites-available/000-default.conf
COPY index.php /var/www/html/FurniFlex/
COPY includes /var/www/html/FurniFlex/includes
COPY assets /var/www/html/FurniFlex/assets
COPY uploads /var/www/html/FurniFlex/uploads
COPY storage /var/www/html/FurniFlex/storage
COPY deploy/health.php /opt/furniflex/health.php
RUN chown -R www-data:www-data /var/www/html/FurniFlex/uploads /var/www/html/FurniFlex/storage
