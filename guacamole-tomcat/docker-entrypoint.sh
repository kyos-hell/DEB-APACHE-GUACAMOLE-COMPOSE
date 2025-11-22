#!/bin/bash
set -e

# Generated guacamole.properties from environment variables 
cat <<EOF > ${GUACAMOLE_HOME}/guacamole.properties
guacd-hostname: ${GUACD_HOST:-guacd}
guacd-port: ${GUACD_PORT:-4822}

mysql-hostname: ${MYSQL_HOST:-mariadb-guacamole}
mysql-port: ${MYSQL_PORT:-3306}
mysql-database: ${MYSQL_DATABASE:-guacamole_db}
mysql-username: ${MYSQL_USER:-guacamole_user}
mysql-password: ${MYSQL_PASSWORD:-password}
mysql-driver: ${MYSQL_DRIVER:-mariadb}
mysql-ssl-mode: ${MYSQL_SSL_MODE:-disabled}

lib-directory: /opt/guacamole/lib
authentication-provider: net.sourceforge.guacamole.net.auth.mysql.MySQLAuthenticationProvider
EOF

# launched tomcat or debug on /bin/bash 
if [ "$1" = "bash" ]; then
    exec /bin/bash
else
    # Sinon on lance Tomcat normalement
    exec /opt/tomcat9/bin/catalina.sh run
fi