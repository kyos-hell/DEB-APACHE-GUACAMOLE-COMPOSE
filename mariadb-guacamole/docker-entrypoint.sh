#!/bin/bash
set -e

# Ensure data directory exists (created in Dockerfile with proper permissions)
mkdir -p /var/lib/mysql
echo "MariaDB data directory ready at /var/lib/mysql"


# Initialize database files if needed
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    if command -v mariadb-install-db >/dev/null 2>&1; then
        mariadb-install-db --user=mysql --datadir=/var/lib/mysql
    elif command -v mysql_install_db >/dev/null 2>&1; then
        mysql_install_db --user=mysql --datadir=/var/lib/mysql
    elif mysqld --help >/dev/null 2>&1; then
        echo "Falling back to 'mysqld --initialize-insecure' to create system tables..."
        mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql
        echo "Initialization via mysqld --initialize-insecure done (if supported)."
    else
        echo "No mariadb-install-db/mysql_install_db/mysqld --initialize available; continuing (may fail on empty datadir)"
    fi
    echo "Listing /var/lib/mysql after init:"
    ls -la /var/lib/mysql || true
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

# --- Executing initialization scripts (run once unless forced) --- 
# Set MYSQL_FORCE_REINIT=1 to force re-running init scripts on every start
if [ -d "/docker-entrypoint-initdb.d" ]; then
    if [ -z "$MYSQL_FORCE_REINIT" ] && [ -f "/var/lib/mysql/.initialized" ]; then
        echo "Initialization scripts already run; skipping (set MYSQL_FORCE_REINIT=1 to force)"
    else
        # If a target database is set and already has tables, skip init unless forced
        if [ -n "$MYSQL_DATABASE" ] && [ -z "$MYSQL_FORCE_REINIT" ]; then
            echo "Checking if database '$MYSQL_DATABASE' already contains tables..."
            TABLES_COUNT=$(mysql -uroot ${MYSQL_ROOT_PASSWORD:+-p"$MYSQL_ROOT_PASSWORD"} -N -B -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$MYSQL_DATABASE';" 2>/dev/null || echo "0")
            if [ "$TABLES_COUNT" -gt 0 ]; then
                echo "Database '$MYSQL_DATABASE' already contains $TABLES_COUNT tables; skipping init scripts (set MYSQL_FORCE_REINIT=1 to force)"
                # create marker to avoid future checks
                if touch /var/lib/mysql/.initialized 2>/dev/null; then
                    echo "Initialization marker created: /var/lib/mysql/.initialized"
                else
                    echo "Warning: could not create initialization marker /var/lib/mysql/.initialized (permissions?)"
                fi
            else
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
                # mark initialization as completed so scripts are not re-run
                if touch /var/lib/mysql/.initialized 2>/dev/null; then
                    echo "Initialization marker created: /var/lib/mysql/.initialized"
                else
                    echo "Warning: could not create initialization marker /var/lib/mysql/.initialized (permissions?)"
                fi
            fi
        else
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
            # mark initialization as completed so scripts are not re-run
            if touch /var/lib/mysql/.initialized 2>/dev/null; then
                echo "Initialization marker created: /var/lib/mysql/.initialized"
            else
                echo "Warning: could not create initialization marker /var/lib/mysql/.initialized (permissions?)"
            fi
        fi
    fi
fi

# Shutdown temporary server before start in foreground --- 
echo "Stopping temporary MariaDB server..."
mysqladmin -uroot ${MYSQL_ROOT_PASSWORD:+-p"$MYSQL_ROOT_PASSWORD"} shutdown

# --- define the bind-address via an environment variable (fallback à 0.0.0.0) --- 
BIND_ADDR="${MYSQL_BIND_ADDRESS:-0.0.0.0}"
echo "Setting bind-address = $BIND_ADDR (config will be applied at startup)"

# --- Final start in foreground --- 
if [ "$1" = "bash" ]; then
    exec /bin/bash
else
    # Start with custom bind address if needed
    if [ -n "$MYSQL_BIND_ADDRESS" ]; then
        exec mysqld --user=999 --bind-address="$MYSQL_BIND_ADDRESS"
    else
        exec mysqld --user=999
    fi
fi
#testy