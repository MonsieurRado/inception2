# Developer Documentation

## Overview

This project deploys a WordPress infrastructure using Docker Compose.

It contains three services:

- NGINX
- WordPress with PHP-FPM
- MariaDB

Each service is built from its own Dockerfile based on Debian and runs in a dedicated container.

## Project Structure

```text
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── 50-server.cnf
        │   └── tools/
        │       └── mariadb.sh
        ├── nginx/
        │   ├── Dockerfile
        │   └── conf/
        │       └── nginx.conf
        └── wordpress/
            ├── Dockerfile
            ├── conf/
            │   └── www.conf
            └── tools/
                └── wordpress.sh
```

The `.env` file and the `secrets/` directory are local configuration files and must not be committed to Git.

## Docker Compose

The infrastructure is defined in:

`srcs/docker-compose.yml`

Docker Compose is responsible for:

- building the three images;
- creating and starting the containers;
- creating the Docker network;
- creating the persistent volumes;
- providing environment variables and secrets;
- defining service dependencies;
- applying the restart policy.

## NGINX

NGINX is the only entry point to the infrastructure.

It exposes port `443` and accepts HTTPS connections using TLS 1.2 and TLS 1.3.

Its configuration is located in:

`srcs/requirements/nginx/conf/nginx.conf`

PHP requests are forwarded to the WordPress container using FastCGI:

`wordpress:9000`

NGINX shares the WordPress volume in read-only mode so that it can access the website files.

## WordPress and PHP-FPM

The WordPress container contains WordPress, PHP and PHP-FPM.

Its startup script is:

`srcs/requirements/wordpress/tools/wordpress.sh`

During the first initialization, the script:

1. reads the database password from Docker secrets;
2. downloads WordPress if the WordPress core files are not already present;
3. waits until the MariaDB database is usable;
4. creates the WordPress configuration;
5. installs WordPress;
6. creates the administrator account;
7. creates the second WordPress user;
8. sets the appropriate ownership on the WordPress files;
9. starts PHP-FPM in foreground mode.

On subsequent starts, the existing WordPress installation is reused.

PHP-FPM listens on port `9000` inside the Docker network.

## MariaDB

The MariaDB startup script is:

`srcs/requirements/mariadb/tools/mariadb.sh`

During the first initialization, it:

1. initializes the MariaDB data directory;
2. temporarily starts MariaDB;
3. creates the WordPress database;
4. creates the database user;
5. grants the required privileges;
6. configures the root password;
7. removes anonymous users;
8. stops the temporary MariaDB server;
9. starts MariaDB as the main container process.

On subsequent starts, the existing database stored in the persistent volume is reused.

MariaDB listens inside the Docker network and is not exposed directly to the host.

## Docker Network

All three containers are connected to the dedicated `inception` bridge network.

Docker provides internal DNS resolution using service names.

This allows:

```text
NGINX -> wordpress:9000
WordPress -> mariadb:3306
```

No container IP address is hard-coded.

Only NGINX publishes a port to the host.

## Persistent Storage

Two named Docker volumes are defined:

- `wordpress_data`
- `mariadb_data`

They use the Docker local driver and store their data under:

```text
/home/sradosav/data/wordpress
/home/sradosav/data/mariadb
```

This separates persistent data from the lifecycle of the containers.

Removing and recreating a container therefore does not remove the website or database data.

## Environment Variables and Secrets

Non-sensitive configuration is stored in:

`srcs/.env`

Examples include:

- domain name;
- database name;
- database username;
- WordPress usernames and email addresses.

Passwords are stored in files under:

`secrets/`

Docker Compose exposes these secret files to the appropriate containers under:

`/run/secrets/`

Passwords must not be written directly in Dockerfiles or committed to Git.

## Building and Running

From the repository root:

```bash
make
```

The Makefile creates the persistent data directories and executes Docker Compose with the required build options.

Useful commands include:

```bash
make status
make logs
make stop
make start
make down
make up
make fclean
make re
```

`make re` removes the existing persistent project data and rebuilds the infrastructure from a clean state.

## Checking the Infrastructure

Container status can be checked with:

```bash
make status
```

The Docker network can be inspected with:

```bash
sudo docker network inspect srcs_inception
```

The volumes can be inspected with:

```bash
sudo docker volume inspect srcs_mariadb_data srcs_wordpress_data
```

The website can be tested with:

```bash
curl -k https://sradosav.42.fr
```

Only port 443 should be exposed by the infrastructure.

## Modifying the Project

When changing a Dockerfile or a file copied into an image, rebuild the affected image with:

```bash
make up
```

The Makefile uses Docker Compose with the `--build` option.

For a complete clean rebuild:

```bash
make re
```

Be careful: this deletes the persistent WordPress and MariaDB data.