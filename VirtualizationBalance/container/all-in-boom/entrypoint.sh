#!/bin/bash
set -e

init_db() {
    if [ ! -d "/var/lib/mysql/mysql" ]; then
        echo "Initializing database..."
        mysql_install_db --user=mysql --datadir=/var/lib/mysql
        mkdir -p /run/mariadb && chown mysql:mysql /run/mariadb
        mysqld --user=mysql --skip-networking --socket=/run/mariadb/mysqld.sock &
        local pid=$!
        for i in {1..30}; do
            if mysqladmin ping --socket=/run/mariadb/mysqld.sock --silent; then break; fi
            sleep 1
        done
        mysql --socket=/run/mariadb/mysqld.sock -u root <<-EOSQL
            SET PASSWORD FOR 'root'@'localhost' = PASSWORD('kylin@123!');
            GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'kylin@123!' WITH GRANT OPTION;
            FLUSH PRIVILEGES;
EOSQL
        kill -15 $pid && wait $pid
    fi
}

init_db

mkdir -p /usr/local/nginx/logs
chown nginx:nginx /usr/local/nginx/logs

mkdir -p /usr/local/php8.5.8/log

mkdir -p /var/run/php-fpm
chown php:nginx /var/run/php-fpm

mkdir -p /usr/local/php8.5.8/var/run
chown php:php /usr/local/php8.5.8/var/run

mysqld_safe --user=mysql &
/usr/local/php8.5.8/sbin/php-fpm -y /usr/local/php8.5.8/etc/php-fpm.conf -D
nginx -g "daemon off;"