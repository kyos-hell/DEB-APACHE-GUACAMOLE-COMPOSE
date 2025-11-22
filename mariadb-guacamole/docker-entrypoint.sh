#!/bin/bash
set -e

# --- Start MariaDB in the background for initialization --- 
echo "Starting temporary MariaDB server..."
mysqld_safe --user=mysql --skip-networking=0 & 
pid="$!"

# --- Waiting for MariaDB to be ready --- 
echo "Waiting for MariaDB to be ready..."
until mysqladmin ping -uroot --silent; do
    sleep 1
done
echo "MariaDB is ready."

# --- Check and create database if needed --- 
if [ -n "$MYSQL_DATABASE" ]; then
    DB_EXISTS=$(mysql -uroot -e "SHOW DATABASES LIKE '$MYSQL_DATABASE';" 2>/dev/null | grep "$MYSQL_DATABASE" || true)
    if [ -z "$DB_EXISTS" ]; then
        echo "Database $MYSQL_DATABASE not found. Creating..."
        mysql -uroot <<EOF
CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;
EOF
    fi
fi

# --- Check and create user if needed --- 
if [ -n "$MYSQL_USER" ] && [ -n "$MYSQL_PASSWORD" ]; then
    USER_EXISTS=$(mysql -uroot -e "SELECT User, Host FROM mysql.user WHERE User='$MYSQL_USER';" 2>/dev/null | grep "$MYSQL_USER" || true)
    if [ -z "$USER_EXISTS" ]; then
        echo "User $MYSQL_USER not found. Creating..."
        mysql -uroot <<EOF
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%';
GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'localhost';
FLUSH PRIVILEGES;
EOF
    fi
fi

# --- Executing initialization scripts --- 
if [ -d "/docker-entrypoint-initdb.d" ]; then
    echo "Running initialization scripts from /docker-entrypoint-initdb.d..."
    for f in $(ls -1 /docker-entrypoint-initdb.d/ | sort); do
        full="/docker-entrypoint-initdb.d/$f"
        case "$f" in
            *.sh)
                echo "Executing shell script: $f"
                bash "$full"
                ;;
            *.sql)
                echo "Executing SQL script: $f"
                mysql -uroot "$MYSQL_DATABASE" < "$full"
                ;;
            *.sql.gz)
                echo "Executing compressed SQL script: $f"
                gunzip -c "$full" | mysql -uroot "$MYSQL_DATABASE"
                ;;
            *)
                echo "Ignoring file: $f"
                ;;
        esac
    done
fi

# Shutdown temporary server before start in forground --- 
echo "Stopping temporary MariaDB server..."
mysqladmin -uroot shutdown

# --- define the bind-address via an environment variable (fallback à 0.0.0.0) --- 
BIND_ADDR="${MYSQL_BIND_ADDRESS:-0.0.0.0}"
echo "Setting bind-address = $BIND_ADDR"
echo "[mysqld]" > /etc/mysql/mariadb.conf.d/99-bind-address.cnf
echo "bind-address = $BIND_ADDR" >> /etc/mysql/mariadb.conf.d/99-bind-address.cnf

# --- Final start in foreground --- 
if [ "$1" = "bash" ]; then
    exec /bin/bash
else
    exec mysqld --user=mysql
fi
