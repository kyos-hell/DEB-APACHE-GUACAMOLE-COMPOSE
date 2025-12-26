FROM debian:bookworm 

LABEL maintainer="Louis.bahiana@hotmail.com" \ 
    version="1.0" \
    description="This is a Dockerfile for my educational projects for learning purposes."

RUN apt-get update && apt-get install -y \
    wget curl openjdk-17-jdk ca-certificates libmariadb-java \
    && rm -rf /var/lib/apt/lists/*

#Preparation for tomcat
RUN useradd -r -d /opt/tomcat9 -s /bin/false tomcat
RUN mkdir /opt/tomcat9 

#Download tomcat
WORKDIR /opt/tomcat9
RUN wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.111/bin/apache-tomcat-9.0.111.tar.gz
RUN tar -xzf apache-tomcat-9.0.111.tar.gz --strip-components=1
RUN rm apache-tomcat-9.0.111.tar.gz

#Download guacamole-client
WORKDIR /tmp/
RUN wget -O guacamole-1.6.0.war "https://apache.org/dyn/closer.lua/guacamole/1.6.0/binary/guacamole-1.6.0.war?action=download"
RUN cp guacamole-1.6.0.war /opt/tomcat9/webapps/guacamole.war

#Preparation for guacamole configuration
RUN mkdir /etc/guacamole
RUN mkdir /etc/guacamole/extensions
RUN mkdir /etc/guacamole/lib

#Download guacamole-auth-jdbc mysql extension
WORKDIR /tmp/
RUN wget -O guacamole-auth-jdbc-1.6.0.tar.gz "https://apache.org/dyn/closer.lua/guacamole/1.6.0/binary/guacamole-auth-jdbc-1.6.0.tar.gz?action=download"
RUN tar xzf guacamole-auth-jdbc-1.6.0.tar.gz
RUN cp guacamole-auth-jdbc-1.6.0/mysql/guacamole-auth-jdbc-mysql-1.6.0.jar /etc/guacamole/extensions/
RUN cp /usr/share/java/mariadb-java-client.jar /etc/guacamole/lib/
RUN touch /etc/guacamole/guacamole.properties

#copy of scripts entrypoint and set execute permission
COPY docker-entrypoint.sh /opt/tomcat9/docker-entrypoint.sh
RUN chmod +x /opt/tomcat9/docker-entrypoint.sh

#Define permissions - ensure UID 1000 can write to guacamole config
RUN chown -R 1000:1000 /opt/tomcat9 /etc/guacamole && chmod 755 /etc/guacamole && chmod 755 /opt/tomcat9

#Define USER
USER 1000

#Define ENV
ENV CATALINA_HOME=/opt/tomcat9
ENV GUACAMOLE_HOME=/etc/guacamole

#Expose port
EXPOSE 8080

#Entry point
ENTRYPOINT ["/opt/tomcat9/docker-entrypoint.sh"]

#test
#testv"testv32
