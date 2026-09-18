FROM debian:bookworm

RUN apt-get update && apt-get install -y mariadb-server

COPY tools/mariadb.sh /usr/local/bin/mariadb.sh

RUN chmod +x /usr/local/bin/mariadb.sh

CMD ["/usr/local/bin/mariadb.sh"]