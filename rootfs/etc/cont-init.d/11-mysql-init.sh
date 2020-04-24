#!/usr/bin/with-contenv sh
if [ ! -d /data/db/mysql/mysql ]; then
  # Check variables
  if [ -z "$MARIADB_ROOT_PASSWORD" ]; then
    # Set root password
    echo "[w] Root password is not set, we will randomize the same..."
    echo "[i] If you want to set it yourself, then set the ENV variable MARIADB_ROOT_PASSWORD"
    MARIADB_ROOT_PASSWORD=`pwgen 16 1`
    echo "[i] Root password set as: $MARIADB_ROOT_PASSWORD"
  fi
  if [ ! -z "$MARIADB_DATABASE" ]; then
    # Yes we have to create database, check if it meets norms
    MARIADB_CHARSET=${MARIADB_CHARSET:-"utf8"}
    MARIADB_COLLATION=${MARIADB_COLLATION:-"utf8_general_ci"}
  fi
  if [ ! -z "$MARIADB_USER" ]; then
    # Check if username meets norms
    # Check if password is set, if not throw error and quit
    if [ -z "$MARIADB_PASSWORD" ]; then
      echo "[w] Password for user $MARIADB_USER is not set. Will set random password"
      echo "[i] To set a password for $MARIADB_USER set the env variable MARIADB_PASSWORD"
      MARIADB_PASSWORD=`pwgen 16 1`
    fi
  fi
  # Run the configuration
  # initialize database if not found
  echo "[i] Initializing MariaDB..."
  /usr/bin/mysql_install_db --auth-root-authentication-method=normal --datadir=/data/db/mysql/ --user=mysql 2> /dev/null
  # start database for config
  echo "[i] Starting MariaDB..."
  /usr/bin/mysqld_safe --defaults-file=/etc/mysql/my.cnf --datadir=/data/db/mysql/  &
  # wait for it to start
  echo -n "[i] Checking if mariadb started..."     
  c=1
  while [[ $c -le 30 ]]
  do
    echo 'SELECT 1' | /usr/bin/mysql &> /dev/null
  #  echo "R=$?"
    if [ $? -eq 0 ]; then
      break 
    fi
    echo "."
    sleep 1
    let c=c+1
  done
  echo "C=$c"
  if [ $c -eq 31 ]; then
    echo "[e] Mariadb failed to start... Please check logs"
    exit 1
  fi
  # remove some stuff
  # /usr/bin/mysql -V
  # Set root password
  /usr/bin/mysqladmin -u root password "$MARIADB_ROOT_PASSWORD"
  # Check if password has been changed
  /usr/bin/mysql --user=root --password=$MARIADB_ROOT_PASSWORD -e "SELECT 1+1" &> /dev/null
  if [ $? -eq 0 ]; then
    echo '[i] Updated root password sucessfully'
    /usr/bin/mysql --user=root --password=$MARIADB_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '$MARIADB_ROOT_PASSWORD' WITH GRANT OPTION;" &> /dev/null
    /usr/bin/mysql --user=root --password=$MARIADB_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MARIADB_ROOT_PASSWORD' WITH GRANT OPTION;" &> /dev/null
    echo '[i] Granted root access from remote host'
    /usr/bin/mysql --user=root --password=$MARIADB_ROOT_PASSWORD -e "DROP DATABASE IF EXISTS test;" &> /dev/null
    echo '[i] Dropping test database.'
    /usr/bin/mysql --user=root --password=$MARIADB_ROOT_PASSWORD -e "DELETE FROM mysql.user WHERE user='';" &> /dev/null
    echo '[i] Dropping unwanted users.'
    /usr/bin/mysql --user=root --password=$MARIADB_ROOT_PASSWORD -e "FLUSH PRIVILEGES;" &> /dev/null
    echo '[i] Running Flush Privileges.'
    if [ ! -z "$MARIADB_DATABASE" ]; then  
      /usr/bin/mysql --user=root --password=$MARIADB_ROOT_PASSWORD -e "CREATE DATABASE IF NOT EXISTS \`$MARIADB_DATABASE\` CHARACTER SET $MARIADB_CHARSET COLLATE $MARIADB_COLLATION;" &> /dev/null
      echo "[i] Created database $MARIADB_DATABASE."
    fi
    if [ ! -z "$MARIADB_USER" ]; then
      /usr/bin/mysql --user=root --password=$MARIADB_ROOT_PASSWORD -e "CREATE USER '$MARIADB_USER'@'%' IDENTIFIED BY '$MARIADB_PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;" &> /dev/null
      /usr/bin/mysql --user=root --password=$MARIADB_ROOT_PASSWORD -e "CREATE USER '$MARIADB_USER'@'localhost' IDENTIFIED BY '$MARIADB_PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;" &> /dev/null
      echo "[i] Created user $MARIADB_USER with password $MARIADB_PASSWORD"
      if [ ! -z "$MARIADB_DATABASE" ]; then 
        /usr/bin/mysql --user=root --password=$MARIADB_ROOT_PASSWORD -e "GRANT ALL ON $MARIADB_DATABASE.* TO '$MARIADB_USER'@'%' ;FLUSH PRIVILEGES;" &> /dev/null
        /usr/bin/mysql --user=root --password=$MARIADB_ROOT_PASSWORD -e "GRANT ALL ON $MARIADB_DATABASE.* TO '$MARIADB_USER'@'localhost';FLUSH PRIVILEGES;" &> /dev/null
        echo "[i] Granted permission to user $MARIADB_USER on DB $MARIADB_DATABASE"
      fi
    fi
  fi
  
  # Run user set initialization scripts
  for initFile in /init.d/.*; do
    case "$initFile" in
      # *.sql) echo "Running $initFile"; /usr/bin/mysqld --user=mysql --bootstrap --verbose=0 --skip-name-resolve --skip-networking=0 < "$initFile"; echo ;;
      *.sql) echo "[i] Running $initFile"; /usr/bin/mysql  --user=root --password=$MARIADB_ROOT_PASSWORD < "$initFile"; echo ;;
      # *.sql.gz) echo "Running $initFile"; gunzip -c "$f" | /usr/bin/mysqld --user=mysql --bootstrap --verbose=0 --skip-name-resolve --skip-networking=0 < "$initFile"; echo ;;
      *.sql.gz) echo "[i] Running $initFile"; gunzip -c "$f" | /usr/bin/mysql  --user=root --password=$MARIADB_ROOT_PASSWORD < "$initFile"; echo ;;
      # Run Bash files
      *.sh) echo "[i] Running $initFile"; . "$initFile" ;;
    esac
  done
  # Shut it down, let the service kick in
  /usr/bin/mysqladmin shutdown --user=root --password="$MARIADB_ROOT_PASSWORD"
  echo "[i] mariadb shutdown sucessfully..."
fi
