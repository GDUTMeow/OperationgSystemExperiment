FROM cr.kylinos.cn/kylin/kylin-server-init:v11-2503

# Nginx
RUN groupadd nginx && useradd -M -s /sbin/nologin nginx -g nginx
RUN dnf install -y gcc make pcre-devel zlib-devel tar zlib wget
RUN wget https://nginx.org/download/nginx-1.31.2.tar.gz -O nginx.tar.gz
RUN tar -zxvf nginx.tar.gz -C /usr/src/
RUN mkdir -p /usr/local/nginx
RUN cd /usr/src/nginx-1.31.2 && \
    ./configure --prefix=/usr/local/nginx \
    --user=nginx --group=nginx \
    --with-http_stub_status_module && \
    make && make install
COPY nginx.conf /usr/local/nginx/conf/nginx.conf
RUN ln -s /usr/local/nginx/sbin/nginx /usr/local/sbin

# Database
RUN dnf install -y mariadb mariadb-server net-tools
RUN chmod -R 777 /var/lib/mysql
RUN chown mysql:mysql -R /var/lib/mysql

# PHP
RUN dnf install -y libxml2-devel sqlite-devel libcurl-devel oniguruma-devel openssl-devel
RUN groupadd php && useradd -M -s /sbin/nologin php -g php
RUN wget https://www.php.net/distributions/php-8.5.8.tar.gz -O php.tar.gz
RUN tar -zxvf php.tar.gz -C /usr/src/

# 手册里说的 bug
RUN sed -i 's/# define ZEND_USE_ASM_ARITHMETIC 1/# define ZEND_USE_ASM_ARITHMETIC 0/g' /usr/src/php-8.5.8/Zend/zend_operators.h

RUN cd /usr/src/php-8.5.8 && ./configure --prefix=/usr/local/php8.5.8 \
    --with-mysql-sock=/var/lib/mysql/mysql.sock \
    --with-curl --with-zlib --with-zlib-dir --with-mysqli \
    --with-config-file-path=/usr/local/php8.5.8 \
    --enable-mysqlnd --enable-mbstring --enable-fpm \
    --enable-bcmath --enable-sockets --enable-shared \
    --with-gettext --with-openssl --with-pdo-mysql && \
    make && make install
RUN cp /usr/src/php-8.5.8/php.ini-production /usr/local/php8.5.8/php.ini
RUN cp /usr/local/php8.5.8/etc/php-fpm.conf.default /usr/local/php8.5.8/etc/php-fpm.conf
RUN cp /usr/local/php8.5.8/etc/php-fpm.d/www.conf.default /usr/local/php8.5.8/etc/php-fpm.d/www.conf

# 替换 php-fpm.conf 中的配置
RUN sed -i 's/;pid = run\/php-fpm.pid/pid = run\/php-fpm.pid/g' /usr/local/php8.5.8/etc/php-fpm.conf
RUN sed -i 's/;error_log = log\/php-fpm.log/error_log = log\/php-fpm_error.log/g' /usr/local/php8.5.8/etc/php-fpm.conf
RUN sed -i "s|;include=/usr/local/php8.5.8/etc/php-fpm.d/\*.conf|include=/usr/local/php8.5.8/etc/php-fpm.d/\*.conf|g" /usr/local/php8.5.8/etc/php-fpm.conf

# 替换 www.conf 中的配置
RUN sed -i 's/user = nobody/user = php/g' /usr/local/php8.5.8/etc/php-fpm.d/www.conf
RUN sed -i 's/group = nobody/group = php/g' /usr/local/php8.5.8/etc/php-fpm.d/www.conf
RUN sed -i 's/pm.max_children = .*/pm.max_children = 5/g' /usr/local/php8.5.8/etc/php-fpm.d/www.conf
RUN sed -i 's/pm.start_servers = .*/pm.start_servers = 2/g' /usr/local/php8.5.8/etc/php-fpm.d/www.conf
RUN sed -i 's/pm.min_spare_servers = .*/pm.min_spare_servers = 1/g' /usr/local/php8.5.8/etc/php-fpm.d/www.conf
RUN sed -i 's/pm.max_spare_servers = .*/pm.max_spare_servers = 3/g' /usr/local/php8.5.8/etc/php-fpm.d/www.conf
RUN sed -i 's|^listen = 127.0.0.1:9000|listen = /var/run/php-fpm/php-fpm.sock|' /usr/local/php8.5.8/etc/php-fpm.d/www.conf
RUN echo 'listen.owner = nginx' >> /usr/local/php8.5.8/etc/php-fpm.d/www.conf
RUN echo 'listen.group = nginx' >> /usr/local/php8.5.8/etc/php-fpm.d/www.conf
RUN echo 'listen.mode = 0660' >> /usr/local/php8.5.8/etc/php-fpm.d/www.conf

RUN rm -rf /usr/src/php-8.5.8 /usr/src/nginx-1.31.2 /nginx.tar.gz /php.tar.gz
RUN mkdir -p /var/run/php-fpm && chown php:nginx /var/run/php-fpm
RUN dnf clean all
EXPOSE 80 3306
COPY index.php /usr/local/nginx/html/index.php
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]