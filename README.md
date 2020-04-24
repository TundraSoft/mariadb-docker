# TundraSoft - SAMBA Docker

MariaDB Server is one of the most popular open source relational databases. It’s made by the original developers of MySQL and guaranteed to stay open source. It is part of most cloud offerings and the default in most Linux distributions.

It is built upon the values of performance, stability, and openness, and MariaDB Foundation ensures contributions will be accepted on technical merit. Recent new functionality includes advanced clustering with Galera Cluster 4, compatibility features with Oracle Database and Temporal Data Tables, allowing one to query the data as it stood at any point in the past.

# Usage

You can run the docker image by

## docker run

```
docker run \
 --name=mariadb \
 -p 3306:3306 \
 -e TZ=Europe/London \
 -e MARIADB_ROOT_PASSWORD= \
 -e MARIADB_USER= \
 -e MARIADB_PASSWORD= \
 -e MARIADB_DATABASE= \
 -e MARIADB_CHARSET= \
 -e MARIADB_COLLATION= \
 -v <volume name>:/data \
 -v <volume name>:/init.d \
 --restart unless-stopped \
 tundrasoft/mariadb-docker:latest
```

## docker Create

```
docker run \
 --name=mariadb \
 -p 3306:3306 \
 -e TZ=Europe/London \
 -e MARIADB_ROOT_PASSWORD= \
 -e MARIADB_USER= \
 -e MARIADB_PASSWORD= \
 -e MARIADB_DATABASE= \
 -e MARIADB_CHARSET= \
 -e MARIADB_COLLATION= \
 -v <volume name>:/data \
 -v <volume name>:/init.d \
 --restart unless-stopped \
 tundrasoft/mariadb-docker:latest
```

## docker-compose

```
version: "3.2"
services:
  mariadb:
    image: tundrasoft/mariadb-docker:latest
    ports:
      - 3306:3306
    environment:
      - TZ=Asia/Kolkata # Specify a timezone to use EG Europe/London
      - MARIADB_USER=
      - MARIADB_PASSWORD=
      - MARIADB_DATABASE=
      - MARIADB_CHARSET=
      - MARIADB_COLLATION=
    volumes:
      - <volume name>:/data # Where mariaDB data resides
      - <volume name>:/init.d # Path where you can put the initialization files (supported are sql, sql.gz and bash files)
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
```

## Ports

3306 - The default mariadb port

## Variables

### TZ

The timezone to use.

### MARIADB_ROOT_PASSWORD

The password for "root" user in mariadb database. If the password is not set, then a random password will be generated

### MARIADB_USER

A custom username to use to login to mariadb. This is only created on the first execution

Default is blank

### MARIADB_PASSWORD

Password for the custom user created (MARIADB_USER). If a username is provided but no password, then a password is generated.

This is only created on the first execution

### MARIADB_DATABASE

The database to create by default during the first run

### MARIADB_CHARSET

Characterset encoding for the database - Defaults to utf8

### MARIADB_COLLATION

Collation for the database - defaults to utf8_general_ci

## Volumes

### Data - /data

The main data store volume for mariadb. This contains actual data, transaction logs, error logs etc.
Be very very careful editing these file

### init.d - /init.d

Place all files which needs to be executed during first deployment here. This will execute and files
with .sql, .sql.gz and .sh extensions
Useful if trying to migrate/load existing data to the database automagically
