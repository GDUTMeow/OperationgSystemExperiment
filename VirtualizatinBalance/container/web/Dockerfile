FROM cr.kylinos.cn/kylin/kylin-server-init:v11-2503

ENV JAVA_HOME=/usr/lib/jvm/jre
ENV CATALINA_HOME=/usr/local/apache-tomcat-9.0.119
ENV PATH=$PATH:JAVA_HOME/bin:$CATALINA_HOME/bin

RUN dnf install -y zip unzip java-1.8.0-openjdk wget
RUN wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.119/bin/apache-tomcat-9.0.119.zip -O tomcat.zip
RUN unzip -d /usr/local tomcat.zip
RUN chmod +x /usr/local/apache-tomcat-9.0.119/bin/catalina.sh
CMD ["/usr/local/apache-tomcat-9.0.119/bin/catalina.sh", "run"]
