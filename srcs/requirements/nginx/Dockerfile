FROM debian:bookworm

RUN apt-get update && apt-get install -y nginx openssl

RUN mkdir -p /etc/nginx/ssl && openssl req -x509 -nodes -days 365 -out /etc/nginx/ssl/inception.crt -keyout /etc/nginx/ssl/inception.key -subj "/CN=sradosav.42.fr"

COPY conf/nginx.conf /etc/nginx/conf.d/default.conf

#lance nginx et le force au premier plan (daemon off) si nginx meurt, le container est arrete
CMD ["nginx", "-g", "daemon off;"]