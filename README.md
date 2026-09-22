*This project has been created as part of the 42 curriculum by sradosav.*

# Inception

## Description

Inception is a system administration project whose goal is to build a small web infrastructure using Docker.

The infrastructure is composed of three separate services:

- **NGINX**: the only entry point to the infrastructure. It serves the website over HTTPS using TLS 1.2 or TLS 1.3.
- **WordPress + PHP-FPM**: hosts the WordPress application and executes PHP code.
- **MariaDB**: stores the WordPress database.

Each service runs in its own Docker container and is built from a custom Dockerfile based on Debian.

The containers communicate through a dedicated Docker bridge network.

Two persistent Docker volumes are used:
- one for the WordPress files;
- one for the MariaDB database.

The persistent data is stored on the virtual machine under:

`/home/sradosav/data`

The website is accessible at:

`https://sradosav.42.fr`

## Architecture

The infrastructure follows this architecture:

```text
Client
  |
  | HTTPS - port 443
  v
NGINX
  |
  | FastCGI - port 9000
  v
WordPress + PHP-FPM
  |
  | MariaDB protocol - port 3306
  v
MariaDB
```

Only NGINX exposes a port outside the Docker network.
WordPress and MariaDB communicate exclusively through the internal Docker network.

## Instructions

### Requirements

The project requires:

- a Linux virtual machine;
- Docker;
- Docker Compose;
- Make.

The domain name `sradosav.42.fr` must resolve to the IP address of the virtual machine.

### Configuration

The environment variables used by Docker Compose are stored in:

`srcs/.env`

Sensitive information such as passwords is stored separately in Docker secret files under:

`secrets/`

These files are not committed to the Git repository.

Before starting the project, the following directories are created automatically by the Makefile:

- `/home/sradosav/data/mariadb`
- `/home/sradosav/data/wordpress`

They contain the persistent data of the infrastructure.

### Build and start

From the root of the repository, run:

```bash
make
```

This creates the required data directories, builds the Docker images and starts the infrastructure.

To check the status of the containers:

```bash
make status
```

To stop and remove the containers while keeping persistent data:

```bash
make down
```

To start the infrastructure again:

```bash
make up
```

To completely remove the containers, Docker volumes and persistent project data:

```bash
make fclean
```

To completely rebuild the project from a clean state:

```bash
make re
```

Once the containers are running, the website is available at:

`https://sradosav.42.fr`

## Technical Choices

### Virtual Machines vs Docker

A virtual machine emulates a complete computer with its own operating system and kernel. It provides strong isolation but requires more resources.

Docker containers share the kernel of the host operating system. They package an application and its dependencies in isolated environments, making them lighter and faster to create than virtual machines.

In this project, the virtual machine provides the Linux environment in which Docker runs, while Docker separates the different services of the infrastructure.

### Docker Secrets vs Environment Variables

Environment variables are convenient for non-sensitive configuration such as the domain name, database name or WordPress username.

Docker secrets are more appropriate for sensitive information such as passwords. In this project, passwords are stored in separate files and made available inside the containers under `/run/secrets/`.

Therefore:

- `.env` contains non-sensitive configuration;
- `secrets/` contains passwords;
- neither is committed to the Git repository.

### Docker Network vs Host Network

A Docker bridge network creates an isolated network in which containers can communicate using their service names.

In this project:

- NGINX communicates with WordPress using `wordpress:9000`;
- WordPress communicates with MariaDB using `mariadb:3306`.

Using the host network would remove this network isolation and make containers directly use the network stack of the virtual machine.

The project therefore uses a dedicated Docker bridge network named `inception`.

### Docker Volumes vs Bind Mounts

Docker volumes are storage resources managed through Docker and can persist independently from the lifecycle of a container.

Bind mounts directly map a specific directory from the host filesystem into a container.

In this project, Docker named volumes are declared in Docker Compose using the local driver. They are configured to store their data in specific directories on the virtual machine:

- `/home/sradosav/data/wordpress`
- `/home/sradosav/data/mariadb`

This allows the WordPress files and database to survive the deletion and recreation of the containers.

## Resources

The following resources were used during the development of this project:

- Docker documentation
- Docker Compose documentation
- NGINX documentation
- MariaDB documentation
- WordPress and WP-CLI documentation
- Debian documentation
- OpenSSL documentation

### Use of AI

AI tools were used as a learning and debugging aid during the project.

They were used to:

- explain Docker concepts such as images, containers, volumes and networks;
- explain Dockerfile and Docker Compose configuration;
- help understand NGINX, PHP-FPM and MariaDB configuration;
- analyse error messages and container logs during debugging;
- help identify and fix a race condition during the initialization of WordPress and MariaDB;
- review the project against the subject and evaluation requirements;
- assist with the structure and wording of the documentation.

The generated suggestions were reviewed, tested and adapted to the project before being used.