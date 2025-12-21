#!/bin/bash
set -e

# Ensure data directory exists and is owned by mysql (runtime chown for PVC mounts)
mkdir -p /var/lib/mysql
chown -R mysql:mysql /var/lib/mysql

# Initialize database files if needed
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    if command -v mariadb-install-db >/dev/null 2>&1; then
        mariadb-install-db --user=mysql --datadir=/var/lib/mysql
    elif command -v mysql_install_db >/dev/null 2>&1; then
        mysql_install_db --user=mysql --datadir=/var/lib/mysql
    else
        echo "No mariadb-install-db or mysql_install_db found; skipping automatic initialization"
    fi
fi

# --- Start MariaDB in the background for initialization --- 
echo "Starting temporary MariaDB server..."
mysqld --user=mysql --skip-networking &
pid="$!"

# --- Waiting for MariaDB to be ready --- 
echo "Waiting for MariaDB to be ready..."
if [ -n "$MYSQL_ROOT_PASSWORD" ]; then
    until mysqladmin ping -uroot -p"$MYSQL_ROOT_PASSWORD" --silent; do
        sleep 1
    done
else
    until mysqladmin ping -uroot --silent; do
        sleep 1
    done
fi
echo "MariaDB is ready."

# --- Check and create database if needed --- 
if [ -n "$MYSQL_DATABASE" ]; then
    DB_EXISTS=$(mysql -uroot ${MYSQL_ROOT_PASSWORD:+-p"$MYSQL_ROOT_PASSWORD"} -e "SHOW DATABASES LIKE '$MYSQL_DATABASE';" 2>/dev/null | grep "$MYSQL_DATABASE" || true)
    if [ -z "$DB_EXISTS" ]; then
        echo "Database $MYSQL_DATABASE not found. Creating..."
        mysql -uroot ${MYSQL_ROOT_PASSWORD:+-p"$MYSQL_ROOT_PASSWORD"} -e "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;"
    fi
fi

# --- Check and create user if needed --- 
if [ -n "$MYSQL_USER" ] && [ -n "$MYSQL_PASSWORD" ]; then
    USER_EXISTS=$(mysql -uroot ${MYSQL_ROOT_PASSWORD:+-p"$MYSQL_ROOT_PASSWORD"} -e "SELECT User, Host FROM mysql.user WHERE User='$MYSQL_USER';" 2>/dev/null | grep "$MYSQL_USER" || true)
    if [ -z "$USER_EXISTS" ]; then
        echo "User $MYSQL_USER not found. Creating..."
        mysql -uroot ${MYSQL_ROOT_PASSWORD:+-p"$MYSQL_ROOT_PASSWORD"} <<EOF
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE:-*}\`.* TO '$MYSQL_USER'@'%';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE:-*}\`.* TO '$MYSQL_USER'@'localhost';
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
                if [ -n "$MYSQL_DATABASE" ]; then
                    mysql -uroot ${MYSQL_ROOT_PASSWORD:+-p"$MYSQL_ROOT_PASSWORD"} "$MYSQL_DATABASE" < "$full"
                else
                    mysql -uroot ${MYSQL_ROOT_PASSWORD:+-p"$MYSQL_ROOT_PASSWORD"} < "$full"
                fi
                ;;
            *.sql.gz)
                echo "Executing compressed SQL script: $f"
                if [ -n "$MYSQL_DATABASE" ]; then
                    gunzip -c "$full" | mysql -uroot ${MYSQL_ROOT_PASSWORD:+-p"$MYSQL_ROOT_PASSWORD"} "$MYSQL_DATABASE"
                else
                    gunzip -c "$full" | mysql -uroot ${MYSQL_ROOT_PASSWORD:+-p"$MYSQL_ROOT_PASSWORD"}
                fi
                ;;
            *)
                echo "Ignoring file: $f"
                ;;
        esac
    done
fi

# Shutdown temporary server before start in foreground --- 
echo "Stopping temporary MariaDB server..."
mysqladmin -uroot ${MYSQL_ROOT_PASSWORD:+-p"$MYSQL_ROOT_PASSWORD"} shutdown

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
