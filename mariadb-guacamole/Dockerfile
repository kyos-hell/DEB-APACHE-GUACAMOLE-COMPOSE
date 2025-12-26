FROM debian:bookworm 

LABEL maintainer="Louis.bahiana@hotmail.com" \ 
    version="1.0" \
    description="This is a Dockerfile for my educational projects for learning purposes."

# Install MariaDB server and client
RUN apt-get update && apt-get install -y \
    mariadb-server mariadb-client \
    && rm -rf /var/lib/apt/lists/*  

# Create mysql user with explicit UID 999 and setup directories
RUN useradd -u 999 -r -s /bin/false mysql || true
RUN mkdir -p /run/mysqld /var/lib/mysql \
    && chown -R 999:999 /run/mysqld /var/lib/mysql \
    && chmod 755 /run/mysqld /var/lib/mysql

# Copy initialization scripts and fix permissions
COPY init/ /docker-entrypoint-initdb.d/
RUN chown -R 999:999 /docker-entrypoint-initdb.d/

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose MariaDB port
EXPOSE 3306

# Set user to mysql (UID 999)
USER 999

#Entry point
ENTRYPOINT ["docker-entrypoint.sh"]

#test3
