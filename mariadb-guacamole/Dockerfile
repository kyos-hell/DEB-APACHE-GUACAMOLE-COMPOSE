FROM debian:bookworm 

LABEL maintainer="Louis.bahiana@hotmail.com" \ 
    version="1.0" \
    description="This is a Dockerfile for my educational projects for learning purposes."

# Install MariaDB server and client
RUN apt-get update && apt-get install -y \
    mariadb-server mariadb-client \
    && rm -rf /var/lib/apt/lists/*  

# Create mysql user and directories
RUN mkdir -p /run/mysqld \
    && chown -R mysql:mysql /run/mysqld /var/lib/mysql

# Copy initialization scripts
COPY init/ /docker-entrypoint-initdb.d/

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose MariaDB port
EXPOSE 3306

#Entry point
ENTRYPOINT ["docker-entrypoint.sh"]

#test3