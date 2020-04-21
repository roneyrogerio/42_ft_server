FROM debian:buster

#Install packages
RUN apt update && apt install -y nginx mariadb-server php-fpm php-mysql openssl

#Avoid possible version and path error
RUN mkdir /etc/my_app
RUN nginx -V 2>&1 | grep -o '\-\-conf-path=\(.*conf\)' | cut -d '=' -f2 | rev | cut -d '/' -f2- | rev > /etc/my_app/nginx_path
RUN php -r "echo PHP_VERSION;" | cut -c -3 > /etc/my_app/php_version

#Copy files
COPY ./srcs/wordpress /var/www/html/wordpress
COPY ./srcs/phpmyadmin /var/www/html/phpmyadmin
COPY ./srcs/wordshitpress.sql /etc/my_app
COPY ./srcs/start /usr/local/bin
COPY ./srcs/autoindex /usr/local/bin
COPY ./srcs/autoindex.conf /etc/my_app
COPY ./srcs/nginx.conf /etc/my_app
RUN mv /etc/my_app/nginx.conf $(cat /etc/my_app/nginx_path)
RUN mv /etc/my_app/autoindex.conf $(cat /etc/my_app/nginx_path)

#Permissions
RUN chmod u+x /usr/local/bin/start
RUN chmod u+x /usr/local/bin/autoindex

#Create mysql wordpress user
RUN service mysql start && mysql -e "CREATE USER 'wordpress'@'localhost' IDENTIFIED BY '12345';"

#Create wordpress database
RUN service mysql start && mysql -e "CREATE DATABASE wordpress"

#Add permisions to wordpress user
RUN service mysql start && mysql -e "GRANT ALL ON wordpress.* TO 'wordpress'@'localhost';"

#Import wordpress database
RUN service mysql start && mysql wordpress < /etc/my_app/wordshitpress.sql && rm /etc/my_app/wordshitpress.sql
#Create sym link to use inside nginx.conf
RUN service php$(cat /etc/my_app/php_version)-fpm start && ln -s /run/php/php$(cat /etc/my_app/php_version)-fpm.sock /run/php/php-fpm.sock

#Create self-assigned ssl certificate
RUN mkdir /etc/ssl/nginx
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/nginx/private.key -out /etc/ssl/nginx/public.crt -subj "/C=42/ST=SP/L=SP/O=Global Security/OU=FT Server/CN=localhost"

ENTRYPOINT start
