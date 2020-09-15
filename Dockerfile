
FROM debian:buster

LABEL MAINTAINER="Mateo Tascon Gomez"

#Update some components

RUN apt-get update && \
	apt-get -y upgrade

#Install nginx && set it

RUN apt-get -y install nginx && \
	rm -f /etc/nginx/sites-available/default && \
	rm -f /etc/nginx/sites-enabled/default
COPY ./srcs/config_server /etc/nginx/sites-available/
RUN ln -s /etc/nginx/sites-available/config_server /etc/nginx/sites-enabled/

#Set localhost page

COPY ./srcs/index.html /var/www/html/
COPY ./srcs/content_index /var/www/html/content_index

#Install php && set it

RUN apt-get -y install php7.3 php7.3-fpm php7.3-cli php7.3-mysql php7.3-gd php7.3-imagick php7.3-recode php7.3-tidy php7.3-xmlrpc php7.3-mbstring
COPY ./srcs/php.ini /etc/php/7.3/fpm/

#Install mariadb(mysql)

RUN apt-get -y install mariadb-server mariadb-client

#Install phpmyadmin && set it

COPY ./srcs/phpmyadmin /var/www/html/phpmyadmin
COPY ./srcs/config.inc.php /var/www/html/phpmyadmin/

#Install wordpress && set it

COPY ./srcs/wordpress /var/www/html/wordpress
COPY ./srcs/wp-config.php /var/www/html/wordpress/

#Install openssl && generate the ssl key

RUN apt-get -y install openssl && \
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj "/C=SP/ST=Spain/L=Madrid/O=42/CN=127.0.0.1" -keyout /etc/ssl/private/matascon.key -out /etc/ssl/certs/matascon.crt && \
	chmod 700 /etc/ssl/private && \
	openssl dhparam -out /etc/nginx/dhparam.pem 1000

#Link site

RUN chown -R www-data:www-data /var/www/html && \
	chmod -R 755 /var/www/html

#Set mysql and wordpress database

RUN service mysql start && \
	echo "CREATE DATABASE wordpress;" | mysql -u root && \
	echo "GRANT ALL PRIVILEGES ON wordpress.* TO 'root'@'localhost';" | mysql -u root && \
	echo "FLUSH PRIVILEGES;" | mysql -u root && \
	echo "update mysql.user set plugin = 'mysql_native_password' where user='root';" | mysql -u root

#Run services

ENTRYPOINT service nginx start && service php7.3-fpm start && service mysql start && bash
