# User Documentation

## Overview

This project provides a WordPress website running inside a Docker infrastructure composed of three services:

- NGINX
- WordPress with PHP-FPM
- MariaDB

The website is accessible through HTTPS at:

https://sradosav.42.fr

## Initial Setup

Before starting the project for the first time, the local configuration files must be created.

### Environment Configuration

The repository contains an example environment file:

`srcs/.env.example`

From the root of the repository, create the local environment file:

```bash
cp srcs/.env.example srcs/.env
```

Edit `srcs/.env` if necessary to configure the domain name, database name, WordPress usernames and email addresses.

The `.env` file must not be committed to Git.

### Password Configuration

Create the secrets directory:

```bash
mkdir -p secrets
```

Create the following files, each containing its corresponding password:

- `secrets/db_root_password.txt`
- `secrets/db_password.txt`
- `secrets/wp_admin_password.txt`
- `secrets/wp_user_password.txt`

These files are used by Docker Compose to provide passwords securely to the containers.

They must never be committed to the Git repository.

### Domain Configuration

The domain name `sradosav.42.fr` must resolve to the IP address of the virtual machine.

If necessary, configure the hosts file on the machine accessing the website.

For detailed installation instructions, refer to `DEV_DOC.md`.

## Starting the Project

Once the environment file and secrets have been configured, run the following command from the repository root:

```bash
make
```

This creates the required persistent directories, builds the Docker images and starts the infrastructure.

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

https://sradosav.42.fr

The website uses a self-signed TLS certificate. The browser may therefore display a security warning.

This is expected for this project because the certificate is not signed by a publicly trusted certificate authority.

## WordPress Administration

The WordPress administration interface is available at:

https://sradosav.42.fr/wp-admin

The administrator username is defined by the `WP_ADMIN_USER` variable in:

`srcs/.env`

The administrator password is stored locally in:

`secrets/wp_admin_password.txt`

A second WordPress user is automatically created with the `author` role.

Its username is defined by the `WP_USER` variable in `srcs/.env`, and its password is stored in:

`secrets/wp_user_password.txt`

Passwords must never be committed to the Git repository.

## Managing the Infrastructure

To stop and remove the containers while preserving the website and database data:

```bash
make down
```

To build and start the infrastructure:

```bash
make up
```

To stop containers without removing them:

```bash
make stop
```

To start existing stopped containers:

```bash
make start
```

To restart the containers:

```bash
make restart
```

To display container logs:

```bash
make logs
```

To display container status:

```bash
make status
```

To stop and remove containers and orphaned containers while preserving persistent data:

```bash
make clean
```

To remove the infrastructure and its persistent WordPress and MariaDB data:

```bash
make fclean
```

**Warning:** `make fclean` permanently deletes the WordPress and MariaDB persistent data directories. It does not delete the local environment file or secret files.

To rebuild the complete infrastructure from a clean state:

```bash
make re
```

**Warning:** `make re` also deletes the existing persistent data before rebuilding the infrastructure.

## Persistent Data

Persistent data is stored on the virtual machine in:

- `/home/sradosav/data/wordpress`
- `/home/sradosav/data/mariadb`

The data remains available when containers are stopped, removed or recreated using `make down` followed by `make up`.

The data is deleted when `make fclean` or `make re` is executed.

## Credentials and Security

Non-sensitive configuration is stored in:

`srcs/.env`

An example configuration is provided in:

`srcs/.env.example`

Passwords are stored separately in:

`secrets/`

Docker Compose makes the appropriate secret files available inside the relevant containers under:

`/run/secrets/`

The `srcs/.env` file and the `secrets/` directory must remain excluded from Git.

Only `srcs/.env.example`, containing non-sensitive example values, should be committed.

## Troubleshooting

If the website is not accessible, first check that all containers are running:

```bash
make status
```

Inspect the container logs:

```bash
make logs
```

Check that the domain name resolves to the correct virtual machine IP address.

Verify that the environment file and all required secret files exist.

If WordPress cannot connect to MariaDB, check the MariaDB container logs:

```bash
docker logs mariadb
```

For more detailed technical information, refer to `DEV_DOC.md`.