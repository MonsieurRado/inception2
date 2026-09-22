# User Documentation

## Overview

This project provides a WordPress website running inside a Docker infrastructure composed of NGINX, WordPress with PHP-FPM, and MariaDB.

The website is accessible through HTTPS at:

`https://sradosav.42.fr`

## Starting the Project

From the root of the repository, run:

```bash
make
```

This builds the required Docker images and starts all services.

To verify that the services are running:

```bash
make status
```

The following three containers should be running:

- `nginx`
- `wordpress`
- `mariadb`

The WordPress container should also report a `healthy` status.

## Accessing the Website

Open a web browser and navigate to:

`https://sradosav.42.fr`

The website uses a self-signed SSL certificate. The browser may therefore display a security warning. This is expected for this project.

The domain name must resolve to the IP address of the virtual machine.

## WordPress Administration

The WordPress administration interface is available at:

`https://sradosav.42.fr/wp-admin`

The administrator username is defined by the `WP_ADMIN_USER` variable in:

`srcs/.env`

The administrator password is stored locally in:

`secrets/wp_admin_password.txt`

A second WordPress user is also automatically created. Its username is defined by `WP_USER` in `srcs/.env` and its password is stored in:

`secrets/wp_user_password.txt`

Passwords must never be committed to the Git repository.

## Managing the Infrastructure

To stop and remove the containers while preserving the website and database data:

```bash
make down
```

To start the infrastructure again:

```bash
make up
```

To stop the containers without removing them:

```bash
make stop
```

To restart stopped containers:

```bash
make start
```

To display container logs:

```bash
make logs
```

To completely remove the infrastructure and its persistent data:

```bash
make fclean
```

Warning: `make fclean` deletes the WordPress and MariaDB persistent data.

To rebuild the complete infrastructure from a clean state:

```bash
make re
```

## Persistent Data

Persistent data is stored on the virtual machine in:

- `/home/sradosav/data/wordpress`
- `/home/sradosav/data/mariadb`

The data remains available when containers are stopped or recreated with `make down` followed by `make up`.

It is deleted when `make fclean` or `make re` is used.

## Credentials

Non-sensitive configuration is stored in:

`srcs/.env`

Passwords are stored separately in:

`secrets/`

The secret files are provided to the containers through Docker secrets and are available inside the relevant containers under `/run/secrets/`.

The `.env` file and the `secrets/` directory must remain excluded from Git.