NAME = inception

COMPOSE = sudo docker compose -f srcs/docker-compose.yml

DATA_DIR = /home/sradosav/data
MARIADB_DIR = $(DATA_DIR)/mariadb
WORDPRESS_DIR = $(DATA_DIR)/wordpress

all: up

up:
	mkdir -p $(MARIADB_DIR)
	mkdir -p $(WORDPRESS_DIR)
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

start:
	$(COMPOSE) start

stop:
	$(COMPOSE) stop

restart:
	$(COMPOSE) restart

clean:
	$(COMPOSE) down --remove-orphans

fclean:
	$(COMPOSE) down -v --remove-orphans
	sudo rm -rf $(MARIADB_DIR)
	sudo rm -rf $(WORDPRESS_DIR)

re: fclean all

status:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs

.PHONY: all up down start stop restart clean fclean re status logs