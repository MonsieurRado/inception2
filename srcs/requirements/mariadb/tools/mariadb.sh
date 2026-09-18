#!/bin/bash

echo "Initialisation de MariaDB..."

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

exec mariadbd --user=mysql