#!/bin/bash

set -e

DB_PASSWORD=$(cat /run/secrets/db_password)

mkdir -p /run/php
mkdir -p /var/www/html

if [ ! -f "/var/www/html/wp-config.php" ]; then

    echo "Première initialisation de WordPress..."
    cd /var/www/html

    wp core download --allow-root

    echo "Attente de MariaDB..."

    until mariadb-admin ping \
        -h mariadb \
        -u "${MYSQL_USER}" \
        -p"${DB_PASSWORD}" \
        --silent; do
        sleep 2
    done

    echo "MariaDB est prête."

    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost="mariadb:3306" \
        --allow-root

    WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
    WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root
fi

chown -R www-data:www-data /var/www/html

echo "Démarrage de PHP-FPM..."

exec php-fpm8.2 -F
