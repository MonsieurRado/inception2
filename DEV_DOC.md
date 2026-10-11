# Developer Documentation

## Overview

This project deploys a WordPress infrastructure using Docker Compose. It contains three services:

- **NGINX**, the HTTPS entry point;
- **WordPress with PHP-FPM**, which processes PHP requests;
- **MariaDB**, which stores WordPress data.

Each service is built from its own Dockerfile based on Debian Bookworm and runs in a separate container. The services communicate over a dedicated Docker bridge network.

## Project Structure

```text
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/                         # Local only; not committed
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env.example                 # Committed template
    ├── .env                         # Local only; not committed
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

The `srcs/.env` file and the `secrets/` directory contain local configuration and must not be committed to Git. The `srcs/.env.example` file is a tracked template and must not contain passwords.

## Prerequisites

- Docker Engine with Docker Compose available as `docker compose`;
- `make`;
- permission to run Docker commands;
- `sudo` privileges if using the `fclean` target;
- the hostname `sradosav.42.fr` resolving to the VM's IP address from the machine used to access the website.

The Makefile uses the fixed host data path `/home/sradosav/data`. If the VM username or home directory differs, update the Makefile's `DATA_DIR` and the corresponding bind-mount paths in `srcs/docker-compose.yml` consistently before starting the project.

## Initial Setup

After cloning the repository, create the local environment file and secret files before building the infrastructure.

### Environment file

Copy the tracked example file:

```bash
cp srcs/.env.example srcs/.env
```

The example should contain the following non-sensitive variables:

```dotenv
DOMAIN_NAME=sradosav.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser

WP_TITLE=Inception

WP_ADMIN_USER=sradosav
WP_ADMIN_EMAIL=sradosav@student.42.fr

WP_USER=wpuser
WP_USER_EMAIL=wpuser@student.42.fr
```

Edit `srcs/.env` as necessary for your local installation. The WordPress administrator username must not contain `admin` or `administrator`, as required by the project rules.

**Do not place passwords in `.env.example` or commit your actual `.env` file.** Passwords are provided through separate secret files.

### Secrets

Create the secrets directory:

```bash
mkdir -p secrets
```

Create the following files, each containing the corresponding password:

```text
secrets/db_root_password.txt
secrets/db_password.txt
secrets/wp_admin_password.txt
secrets/wp_user_password.txt
```

For example, create or edit them with a text editor:

```bash
vim secrets/db_root_password.txt
vim secrets/db_password.txt
vim secrets/wp_admin_password.txt
vim secrets/wp_user_password.txt
```

Use non-empty, suitably strong passwords. Restrict local access to these files where appropriate. They must not be committed to Git.

A suitable `.gitignore` at the repository root includes:

```gitignore
/srcs/.env
/secrets/
```

The example file `srcs/.env.example` **must remain tracked**. Check the ignored files with:

```bash
git status --short --ignored
```

The local `.env` and secret files should appear as ignored (`!!`), not as files staged for commit. If a secret was already tracked, adding it to `.gitignore` alone does not remove it from Git history.

### Host data directories

The Makefile automatically creates the persistent directories:

```text
/home/sradosav/data/mariadb
/home/sradosav/data/wordpress
```

No manual directory creation is required when using the supplied Makefile and matching Compose paths.

### Build and start

From the repository root, run:

```bash
make
```

This creates the host data directories and runs Docker Compose with `up -d --build`. Docker builds the images, creates the project network and named volumes, and starts the three services.

## Docker Compose

The infrastructure is defined in `srcs/docker-compose.yml`. Docker Compose is responsible for:

- building the three service images;
- creating and starting the containers;
- creating the dedicated bridge network;
- creating the named volumes and mounting their host directories;
- passing environment variables and mounting secret files;
- configuring service startup dependencies and restart policies.

Only NGINX publishes a port on the VM. WordPress and MariaDB communicate over the internal Docker network without publishing their service ports to the host.

## NGINX

NGINX is the HTTPS entry point. It listens on port `443` and is configured to use TLS 1.2 and TLS 1.3.

Configuration file:

```text
srcs/requirements/nginx/conf/nginx.conf
```

The NGINX Dockerfile generates a self-signed certificate for the local domain. HTTPS traffic is encrypted, but browsers may warn that the certificate is not trusted by a recognized certificate authority.

NGINX serves static files from `/var/www/html` and forwards PHP requests to PHP-FPM using FastCGI:

```text
wordpress:9000
```

The WordPress files are mounted into NGINX in read-only mode. NGINX does not connect directly to MariaDB.

The container starts NGINX in the foreground with `daemon off;` so the server remains the container's main process.

## WordPress and PHP-FPM

The WordPress image installs PHP-FPM, the PHP MySQL extension, the MariaDB command-line client, and WP-CLI.

Startup script:

```text
srcs/requirements/wordpress/tools/wordpress.sh
```

On the first initialization, the script:

1. Reads the database password from `/run/secrets/db_password`.
2. Creates the required runtime and website directories.
3. Downloads WordPress core files if they are not already present.
4. Waits until MariaDB accepts a successful SQL query.
5. Creates `wp-config.php` with the database connection settings.
6. Installs WordPress with `wp core install`, which also creates the administrator account.
7. Creates a second WordPress user with the `author` role.
8. Assigns ownership of the WordPress files to `www-data`.
9. Starts PHP-FPM in the foreground.

The script checks for `wp-config.php` to decide whether to skip the initial installation on later starts. This is a simple initialization guard, not a complete recovery mechanism if an earlier installation stopped after writing `wp-config.php` but before completing setup.

PHP-FPM listens on port `9000` inside the Docker network. Its workers run as `www-data` according to the PHP-FPM pool configuration.

## MariaDB

Startup script:

```text
srcs/requirements/mariadb/tools/mariadb.sh
```

On the first initialization, the script:

1. Reads the database passwords from Docker secrets.
2. Initializes the MariaDB data directory if its system tables do not exist.
3. Starts a temporary MariaDB server.
4. Waits for the database server to respond.
5. Creates the WordPress database and database user.
6. Grants that user privileges on the WordPress database.
7. Configures the MariaDB root password and removes anonymous users.
8. Stops the temporary database server.
9. Starts MariaDB as the main container process, running under the Linux `mysql` user.

On subsequent starts, the existing database in the persistent volume is reused.

MariaDB listens on port `3306` inside the Docker network and does not publish that port on the VM.

## Docker Network

All three services are connected to the dedicated `inception` bridge network. Docker's embedded DNS resolves service names, allowing containers to communicate without hard-coded IP addresses:

```text
Browser -> NGINX:443
NGINX  -> wordpress:9000
WordPress -> mariadb:3306
```

The published port is `443:443` for NGINX. Ports `9000` and `3306` remain unpublished and are used for container-to-container communication.

## Persistent Storage

Two named Docker volumes are configured:

- `wordpress_data`, bound to `/home/sradosav/data/wordpress`;
- `mariadb_data`, bound to `/home/sradosav/data/mariadb`.

These use Docker's `local` volume driver with bind-mount options. Data persists independently of the containers, so ordinary container removal or recreation does not erase the website or database.

**Important:** `docker compose down -v` removes the named Docker volumes but does not, by itself, guarantee deletion of the data stored in the host bind-mount directories. The Makefile's `fclean` target explicitly removes those directories.

## Environment Variables and Secrets

Non-sensitive configuration is stored locally in `srcs/.env`, using `srcs/.env.example` as the template. Examples include the domain, database name, database username, WordPress usernames, and email addresses.

Passwords are stored in local files under `secrets/`. Docker Compose mounts these files into the appropriate containers under `/run/secrets/`.

Do not hard-code passwords in Dockerfiles, Compose files, scripts, or committed documentation. Protect the local secret files with suitable filesystem permissions. Updating a secret file does not automatically change a password already stored inside an initialized MariaDB or WordPress database.

## Makefile Commands

Run the commands from the repository root:

| Command | Purpose |
|---|---|
| `make` or `make up` | Create data directories, build images as needed, and start services in detached mode |
| `make down` | Stop and remove Compose containers and the project network |
| `make stop` | Stop existing containers without removing them |
| `make start` | Start previously created containers |
| `make restart` | Restart existing containers; does not rebuild images |
| `make clean` | Stop and remove Compose containers and orphans; preserve volumes and host data |
| `make fclean` | Remove Compose containers, named volumes, and the project's persistent host data directories |
| `make re` | Run `fclean`, then rebuild and start from a clean data state |
| `make status` | Show Compose service status |
| `make logs` | Show Compose logs |

**Destructive operations:** `make fclean` and `make re` delete the WordPress and MariaDB data in the configured host directories. Back up any data you want to retain before running them.

In the supplied Makefile, `fclean` does **not** explicitly remove Docker images. The `up` target uses `--build`, so images are rebuilt as needed, with Docker's build cache where applicable.

## Checking the Infrastructure

Check the Compose services:

```bash
make status
```

Check running containers and published ports:

```bash
docker ps
```

Inspect the Docker network:

```bash
docker network inspect srcs_inception
```

Inspect the named volumes:

```bash
docker volume inspect srcs_mariadb_data srcs_wordpress_data
```

The resource names above assume the default Compose project name is `srcs`, derived from the directory containing `docker-compose.yml`. If a different project name is configured, inspect the actual names shown by Docker.

Test HTTPS from a machine where `sradosav.42.fr` resolves to the VM:

```bash
curl -k https://sradosav.42.fr
```

The `-k` option allows the test to proceed despite the self-signed certificate. It should not be used as a substitute for proper certificate validation in production.

Inspect logs when troubleshooting:

```bash
docker logs mariadb
docker logs wordpress
docker logs nginx
```

Or view all Compose service logs:

```bash
make logs
```

Only NGINX should publish a port on the VM.

## Modifying and Rebuilding

After changing a Dockerfile or a file copied into an image, rebuild and recreate the services as needed:

```bash
make up
```

The Makefile runs Docker Compose with `--build`.

For a clean installation that also deletes persistent project data:

```bash
make re
```

**Warning:** `make re` permanently removes the configured WordPress and MariaDB host data directories before rebuilding.

## Reproducibility Test Before Evaluation

To simulate an evaluator cloning the project into a fresh directory:

1. Confirm all required source files and `srcs/.env.example` are committed and pushed to the 42 submission repository.
2. Confirm that the real `.env` and secrets are not committed.
3. Back up any local configuration or data you need to keep.
4. If you intend to test a fully fresh installation, run `make fclean` in the original checkout, understanding that this deletes the persistent project data.
5. Clone the submission repository into a new directory.
6. Run `cp srcs/.env.example srcs/.env` and adjust the configuration if needed.
7. Recreate the four local secret files under `secrets/`.
8. Run `make` from the repository root.
9. Verify the containers, HTTPS access, WordPress installation, and persistence across an ordinary stop/start or `make down` followed by `make up`.

The project is reproducible when a clean clone can be configured and started using only the tracked source files, documented local configuration, and required Docker tools.
