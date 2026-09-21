#!/bin/bash

set -e

DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_PASSWORD=$(cat /run/secrets/db_password)

echo "Initialisation de MariaDB..."

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

if [ ! -d "/var/lib/mysql/mysql" ]; then

    echo "Première initialisation de MariaDB..."

    mariadb-install-db --user=mysql --datadir=/var/lib/mysql

    mariadbd --user=mysql &

    until mariadb-admin ping --silent; do
        sleep 1
    done

    mariadb <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%'
IDENTIFIED BY '${DB_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

ALTER USER 'root'@'localhost'
IDENTIFIED BY '${DB_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User = '';

FLUSH PRIVILEGES;
EOF
    mariadb-admin -u root -p"${DB_ROOT_PASSWORD}" shutdown


fi

echo "Démarrage de MariaDB..."

exec mariadbd --user=mysql