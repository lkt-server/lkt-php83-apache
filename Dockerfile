FROM php:8.3-apache-bullseye

# Configure document root
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Enable mod rewrite
RUN a2enmod rewrite ssl headers

# Enable mod deflate
RUN a2enmod deflate
RUN sed -ri -e 's|</VirtualHost>|<Directory ${APACHE_DOCUMENT_ROOT}>\n SetOutputFilter Deflate\n</Directory>\n</VirtualHost>|g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's|</VirtualHost>|<Directory ${APACHE_DOCUMENT_ROOT}>\n SetOutputFilter Deflate\n</Directory>\n</VirtualHost>|g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# PDO and MySQL installation
RUN docker-php-ext-install pdo pdo_mysql mysqli

# LDAP Installation
RUN apt-get update \
 && apt-get install libldap2-dev -y \
 && rm -rf /var/lib/apt/lists/* \
 && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
 && docker-php-ext-install ldap

# Setup user group
RUN usermod -u 431 www-data

# Add zip support
RUN set -eux; apt-get update; apt-get install -y libzip-dev zlib1g-dev; apt-get install -y unzip; docker-php-ext-install zip

# Add MariaDB client
RUN apt-get install -y mariadb-client

# Add IMAP support
RUN apt-get update && apt-get install -y libc-client-dev libkrb5-dev && rm -r /var/lib/apt/lists/*
RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install imap

# Add intl support
RUN apt-get -y update; apt-get install -y libicu-dev; docker-php-ext-configure intl; docker-php-ext-install intl

# Add gd support
RUN apt-get install -y libpng16-16 libpng-tools
RUN apt-get update && apt-get install -y libpng-dev libjpeg62-turbo-dev libfreetype6-dev jpegoptim optipng pngquant gifsicle
RUN apt-get update && apt-get install -y --no-install-recommends libmagickwand-dev
RUN pecl install imagick && docker-php-ext-enable imagick
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* || true
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
RUN docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ && docker-php-ext-install gd

# Add XML support
RUN apt install -y libxml2-dev && docker-php-ext-install xml

# Add composer support
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php
RUN php -r "unlink('composer-setup.php');"
RUN mv composer.phar /usr/local/bin/composer

# Generates server info files
RUN echo "<?php phpinfo(); ?>" > /var/www/html/info.php && php -m > /var/www/html/php1.html