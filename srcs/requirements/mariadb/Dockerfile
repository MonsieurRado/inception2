FROM debian:bookworm

RUN apt-get update && apt-get install -y mariadb-server

RUN rm -rf /var/lib/mysql/*

COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY tools/mariadb.sh /usr/local/bin/mariadb.sh

RUN chmod +x /usr/local/bin/mariadb.sh

CMD ["/usr/local/bin/mariadb.sh"]