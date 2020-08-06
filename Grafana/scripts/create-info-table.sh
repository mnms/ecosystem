#!/bin/bash
DB=$1
ID=$2
PW=$3
HOST=$4

mysql -e "create table IF NOT EXISTS ${DB}.configs(cluster INT DEFAULT NULL, feature char(100) NOT NULL, value char(100) NOT NULL, description char(255) DEFAULT NULL, event_time timestamp DEFAULT CURRENT_TIMESTAMP ) ENGINE= InnoDB" -u$ID -p$PW -h$HOST
mysql -e "create table IF NOT EXISTS ${DB}.server_cpu( node char(100) NOT NULL, Used FLOAT DEFAULT NULL, event_time timestamp DEFAULT CURRENT_TIMESTAMP ) ENGINE= InnoDB" -u$ID -p$PW -h$HOST
mysql -e "create table IF NOT EXISTS ${DB}.server_memory( node char(100) NOT NULL, Total FLOAT DEFAULT NULL, Used FLOAT DEFAULT NULL, Available FLOAT DEFAULT NULL , event_time timestamp DEFAULT CURRENT_TIMESTAMP ) ENGINE= InnoDB" -u$ID -p$PW -h$HOST
mysql -e "create table IF NOT EXISTS ${DB}.server_disk(node char(100) NOT NULL, Used FLOAT DEFAULT NULL, Available FLOAT DEFAULT NULL, used_percent FLOAT DEFAULT NULL , disk char(100) NOT NULL, event_time timestamp DEFAULT CURRENT_TIMESTAMP ) ENGINE= InnoDB" -u$ID -p$PW -h$HOST
mysql -e "create table IF NOT EXISTS ${DB}.distribution(cluster INT DEFAULT NULL, node char(100) NOT NULL, masters INT DEFAULT NULL, slaves INT DEFAULT NULL  ) ENGINE= InnoDB" -u$ID -p$PW -h$HOST
mysql -e "create table IF NOT EXISTS ${DB}.used_memory (cluster INT DEFAULT NULL,  node char(100) NOT NULL, value FLOAT DEFAULT NULL, event_time timestamp DEFAULT CURRENT_TIMESTAMP  ) ENGINE= InnoDB" -u$ID -p$PW -h$HOST
mysql -e "create table IF NOT EXISTS ${DB}.datakeys ( cluster INT DEFAULT NULL, node char(100) NOT NULL, value FLOAT DEFAULT NULL, event_time timestamp DEFAULT CURRENT_TIMESTAMP  ) ENGINE= InnoDB" -u$ID -p$PW -h$HOST
mysql -e "create table IF NOT EXISTS ${DB}.partitions ( cluster INT DEFAULT NULL, node char(100) NOT NULL, value FLOAT DEFAULT NULL, event_time timestamp DEFAULT CURRENT_TIMESTAMP ) ENGINE= InnoDB" -u$ID -p$PW -h$HOST
mysql -e "create table IF NOT EXISTS ${DB}.evictions ( cluster INT DEFAULT NULL, node char(100) NOT NULL, value FLOAT DEFAULT NULL, event_time timestamp DEFAULT CURRENT_TIMESTAMP ) ENGINE= InnoDB" -u$ID -p$PW -h$HOST
mysql -e "create table IF NOT EXISTS ${DB}.storages (cluster INT DEFAULT NULL,  node char(100) NOT NULL, value FLOAT DEFAULT NULL, event_time timestamp DEFAULT CURRENT_TIMESTAMP ) ENGINE= InnoDB" -u$ID -p$PW -h$HOST
