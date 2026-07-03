FROM cr.kylinos.cn/kylin/kylin-server-init:v11-2503

RUN dnf install -y gcc make pcre-devel zlib-devel tar zlib wget

RUN wget https://nginx.org/download/nginx-1.31.2.tar.gz -O nginx.tar.gz
RUN tar -zxvf nginx.tar.gz -C /usr/src/

RUN mkdir -p /usr/local/nginx
RUN cd /usr/src/nginx-1.31.2 && ./configure --prefix=/usr/local/nginx && make && make install
RUN ln -s /usr/local/nginx/sbin/nginx /usr/local/sbin

CMD ["nginx", "-g", "daemon off;"]