# grafana 설치

https://grafana.com/docs/grafana/latest/installation/rpm/ 참고

```
sudo nano /etc/yum.repos.d/grafana.repo

...

[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt

...

sudo yum install grafana
```

# grafana web ui 접속

http://{server name}:3000 로 접속

```
id: xxxx  
pw: xxxx 
```

# DB 설정
MariaDB 사용

```
ssh nvkvs@fbg02
Last login: Fri Jul 31 09:59:49 2020 from 192.168.200.253
[nvkvs@fbg02 ~]$ mysql -u root -p
Enter password: // 'xxxx' 입력
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 94
Server version: 10.4.13-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| NVACCEL_ONM        |
| information_schema |
| ltdb               |
| ltdb2              |
| metastore          |
| mysql              |
| performance_schema |
+--------------------+
6 rows in set (0.000 sec)

MariaDB [(none)]> use ltdb2;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
MariaDB [ltdb2]> show tables;
+-----------------+
| Tables_in_ltdb2 |
+-----------------+
| datakeys        |
| distribution    |
| evictions       |
| partitions      |
| server_cpu      |
| server_disk     |
| server_memory   |
| storages        |
| used_memory     |
+-----------------+
9 rows in set (0.000 sec)

MariaDB [ltdb2]>

```

# 권한 설정

```
MariaDB [ltdb]> GRANT USAGE ON *.* TO 'root'@'fbg05' IDENTIFIED BY 'xxxx';
MariaDB [ltdb]> grant all privileges on *.* to root@'fbg05' identified by 'xxxx' with grant option;
MariaDB [ltdb]> flush privileges;

```


# table 생성
'create-info-table.sh {db name} {MariaDB id} {MariaDB pw}' 로 생성함(예, 'create-info-table.sh ltdb3 root xxxxx')

```
$ cat create-info-table.sh
#!/bin/bash
DB=$1
ID=$2
PW=$3

mysql -e "create table IF NOT EXISTS ${DB}.configs(cluster INT DEFAULT NULL, feature char(100) NOT NULL, value char(100) NOT NULL, description char(255) DEFAULT NULL, event_time timestamp DEFAULT CURRENT_TIMESTAMP ) ENGINE= InnoDB" -u$ID -p$PW
mysql -e "create table IF NOT EXISTS ${DB}.server_cpu( node char(100) NOT NULL, Used FLOAT DEFAULT NULL, event_time timestamp DEFAULT CURRENT_TIMESTAMP ) ENGINE= InnoDB" -u$ID -p$PW
mysql -e "create table IF NOT EXISTS ${DB}.server_memory(cluster INT DEFAULT NULL,  node char(100) NOT NULL, Total FLOAT DEFAULT NULL, Used FLOAT DEFAULT NULL, Available FLOAT DEFAULT NULL , event_time timestamp DEFAULT CURRENT_TIMESTAMP ) ENGINE= InnoDB" -u$ID -p$PW
mysql -e "create table IF NOT EXISTS ${DB}.server_disk(cluster INT DEFAULT NULL,  node char(100) NOT NULL, Used FLOAT DEFAULT NULL, Available FLOAT DEFAULT NULL, used_percent FLOAT DEFAULT NULL , disk char(100) NOT NULL, event_time timestamp DEFAULT CURRENT_TIMESTAMP ) ENGINE= InnoDB" -u$ID -p$PW
mysql -e "create table IF NOT EXISTS ${DB}.distribution(cluster INT DEFAULT NULL, node char(100) NOT NULL, masters INT DEFAULT NULL, slaves INT DEFAULT NULL  ) ENGINE= InnoDB" -u$ID -p$PW
mysql -e "create table IF NOT EXISTS ${DB}.used_memory (cluster INT DEFAULT NULL,  node char(100) NOT NULL, value FLOAT DEFAULT NULL, event_time timestamp DEFAULT CURRENT_TIMESTAMP  ) ENGINE= InnoDB" -u$ID -p$PW
mysql -e "create table IF NOT EXISTS ${DB}.datakeys ( cluster INT DEFAULT NULL, node char(100) NOT NULL, value FLOAT DEFAULT NULL, event_time timestamp DEFAULT CURRENT_TIMESTAMP  ) ENGINE= InnoDB" -u$ID -p$PW
mysql -e "create table IF NOT EXISTS ${DB}.partitions ( cluster INT DEFAULT NULL, node char(100) NOT NULL, value FLOAT DEFAULT NULL, event_time timestamp DEFAULT CURRENT_TIMESTAMP ) ENGINE= InnoDB" -u$ID -p$PW
mysql -e "create table IF NOT EXISTS ${DB}.evictions ( cluster INT DEFAULT NULL, node char(100) NOT NULL, value FLOAT DEFAULT NULL, event_time timestamp DEFAULT CURRENT_TIMESTAMP ) ENGINE= InnoDB" -u$ID -p$PW
mysql -e "create table IF NOT EXISTS ${DB}.storages (cluster INT DEFAULT NULL,  node char(100) NOT NULL, value FLOAT DEFAULT NULL, event_time timestamp DEFAULT CURRENT_TIMESTAMP ) ENGINE= InnoDB" -u$ID -p$PW

```


# table 정보
시계열 정보가 추가되어야 함.

```
MariaDB [ltdb2]> desc server_cpu;
+------------+-----------+------+-----+---------------------+-------+
| Field      | Type      | Null | Key | Default             | Extra |
+------------+-----------+------+-----+---------------------+-------+
| node       | char(100) | NO   |     | NULL                |       |
| Used       | float     | YES  |     | NULL                |       |
| event_time | timestamp | NO   |     | current_timestamp() |       |
+------------+-----------+------+-----+---------------------+-------+
3 rows in set (0.001 sec)

MariaDB [ltdb2]> desc datakeys;
+------------+-----------+------+-----+---------------------+-------+
| Field      | Type      | Null | Key | Default             | Extra |
+------------+-----------+------+-----+---------------------+-------+
| cluster    | int(11)   | YES  |     | NULL                |       |
| node       | char(100) | YES  |     | NULL                |       |
| value      | float     | YES  |     | NULL                |       |
| event_time | timestamp | NO   |     | current_timestamp() |       |
+------------+-----------+------+-----+---------------------+-------+
4 rows in set (0.001 sec)

MariaDB [ltdb2]> desc distribution;
+---------+-----------+------+-----+---------+-------+
| Field   | Type      | Null | Key | Default | Extra |
+---------+-----------+------+-----+---------+-------+
| cluster | int(11)   | YES  |     | NULL    |       |
| node    | char(100) | NO   |     | NULL    |       |
| masters | int(11)   | YES  |     | NULL    |       |
| slaves  | int(11)   | YES  |     | NULL    |       |
+---------+-----------+------+-----+---------+-------+
4 rows in set (0.001 sec)

MariaDB [ltdb2]> desc evictions;
+------------+-----------+------+-----+---------------------+-------+
| Field      | Type      | Null | Key | Default             | Extra |
+------------+-----------+------+-----+---------------------+-------+
| cluster    | int(11)   | YES  |     | NULL                |       |
| node       | char(100) | YES  |     | NULL                |       |
| value      | float     | YES  |     | NULL                |       |
| event_time | timestamp | NO   |     | current_timestamp() |       |
+------------+-----------+------+-----+---------------------+-------+
4 rows in set (0.001 sec)

MariaDB [ltdb2]> desc partitions;
+------------+-----------+------+-----+---------------------+-------+
| Field      | Type      | Null | Key | Default             | Extra |
+------------+-----------+------+-----+---------------------+-------+
| cluster    | int(11)   | YES  |     | NULL                |       |
| node       | char(100) | YES  |     | NULL                |       |
| value      | float     | YES  |     | NULL                |       |
| event_time | timestamp | NO   |     | current_timestamp() |       |
+------------+-----------+------+-----+---------------------+-------+
4 rows in set (0.001 sec)

MariaDB [ltdb2]> desc server_disk;
+--------------+-----------+------+-----+---------------------+-------+
| Field        | Type      | Null | Key | Default             | Extra |
+--------------+-----------+------+-----+---------------------+-------+
| node         | char(100) | NO   |     | NULL                |       |
| Used         | float     | YES  |     | NULL                |       |
| Available    | float     | YES  |     | NULL                |       |
| used_percent | float     | YES  |     | NULL                |       |
| disk         | char(100) | NO   |     | NULL                |       |
| event_time   | timestamp | NO   |     | current_timestamp() |       |
+--------------+-----------+------+-----+---------------------+-------+
6 rows in set (0.001 sec)

MariaDB [ltdb2]> desc server_memory;
+------------+-----------+------+-----+---------------------+-------+
| Field      | Type      | Null | Key | Default             | Extra |
+------------+-----------+------+-----+---------------------+-------+
| node       | char(100) | NO   |     | NULL                |       |
| Total      | float     | YES  |     | NULL                |       |
| Used       | float     | YES  |     | NULL                |       |
| Available  | float     | YES  |     | NULL                |       |
| event_time | timestamp | NO   |     | current_timestamp() |       |
+------------+-----------+------+-----+---------------------+-------+
5 rows in set (0.001 sec)

MariaDB [ltdb2]> desc storages;
+------------+-----------+------+-----+---------------------+-------+
| Field      | Type      | Null | Key | Default             | Extra |
+------------+-----------+------+-----+---------------------+-------+
| cluster    | int(11)   | YES  |     | NULL                |       |
| node       | char(100) | YES  |     | NULL                |       |
| value      | float     | YES  |     | NULL                |       |
| event_time | timestamp | NO   |     | current_timestamp() |       |
+------------+-----------+------+-----+---------------------+-------+
4 rows in set (0.001 sec)

MariaDB [ltdb2]> desc used_memory;
+------------+-----------+------+-----+---------------------+-------+
| Field      | Type      | Null | Key | Default             | Extra |
+------------+-----------+------+-----+---------------------+-------+
| cluster    | int(11)   | YES  |     | NULL                |       |
| node       | char(100) | YES  |     | NULL                |       |
| value      | float     | YES  |     | NULL                |       |
| event_time | timestamp | NO   |     | current_timestamp() |       |
+------------+-----------+------+-----+---------------------+-------+
4 rows in set (0.001 sec)

MariaDB [ltdb2]> desc configs;
+-------------+-----------+------+-----+---------------------+-------+
| Field       | Type      | Null | Key | Default             | Extra |
+-------------+-----------+------+-----+---------------------+-------+
| cluster     | int(11)   | YES  |     | NULL                |       |
| feature     | char(100) | NO   |     | NULL                |       |
| value       | char(100) | NO   |     | NULL                |       |
| description | char(255) | YES  |     | NULL                |       |
| event_time  | timestamp | NO   |     | current_timestamp() |       |
+-------------+-----------+------+-----+---------------------+-------+
5 rows in set (0.001 sec)

```


# table별 log data 적재

```
load data local infile '/home/nvkvs/utils/grafana/server-stat-disk.dat' into table ltdb.server_disk fields terminated by ',' enclosed by '"' lines terminated by '\n';

load data local infile '/home/nvkvs/utils/grafana/server-stat-memory.dat' into table ltdb.server_memory fields terminated by ',' enclosed by '"' lines terminated by '\n';

load data local infile '/home/nvkvs/utils/grafana/c1-distribution.dat' into table ltdb.distribution fields terminated by '|' enclosed by '"' lines terminated by '\n';

load data local infile '/home/nvkvs/utils/grafana/c1-used-memory.dat' into table ltdb.used_memory fields terminated by ' ' enclosed by '"' lines terminated by '\n';

load data local infile '/home/nvkvs/utils/grafana/c1-evictions.dat' into table ltdb.evictions fields terminated by ' ' enclosed by '"' lines terminated by '\n';

load data local infile '/home/nvkvs/utils/grafana/c1-in-memory-data-keys.dat' into table ltdb.datakeys fields terminated by ' ' enclosed by '"' lines terminated by '\n';

load data local infile '/home/nvkvs/utils/grafana/c1-partitions.dat' into table ltdb.partitions fields terminated by ' ' enclosed by '"' lines terminated by '\n';

load data local infile '/home/nvkvs/utils/grafana/c1-storages.dat' into table ltdb.storages fields terminated by ' ' enclosed by '"' lines terminated by '\n';

```

# Tips

기본적으로 grafana는 time-series 데이터를 표현한다. 따라서 time 정보가 없는 경우는 아래와 같은 방법으로 차트를 추가한다.

https://medium.com/grafana-tutorials/graphing-non-time-series-sql-data-in-grafana-8a0ea8c55ee3

# crontab 으로 정기적으로 로그 수집 및 MariaDB에 적재

'gen-grafana-data.sh' 사용

```
#!/bin/bash

DB=$1
shift
ID=$1
shift
PW=$1
shift
KEEPDAYS=$1
shift

CURR=`date`
echo "run gen-daily-report.sh on $CURR"
RES_DIR="$HOME/utils/grafana"

# CPU
$HOME/sbin/distcmd.sh top -b -n1 | grep "id\|Server"| awk '{if($1 == "Server:") print $2;else print 100-$8}' | xargs -n2 > $RES_DIR/server-stat-cpu.dat
mysql -e "LOAD DATA LOCAL INFILE '/home/nvkvs/utils/grafana/server-stat-cpu.dat' INTO TABLE ${DB}.server_cpu fields terminated by ' ' lines terminated by '\n'" -u$ID -p$PW

# Memory
$HOME/sbin/distcmd.sh free | awk '{if($1 == "Mem:") print "," $2 "," $3 ","  $7;else if($1 == "Server:") print $2}' | xargs -n2 > $RES_DIR/server-stat-memory.dat
mysql -e "LOAD DATA LOCAL INFILE '/home/nvkvs/utils/grafana/server-stat-memory.dat' INTO TABLE ${DB}.server_memory fields terminated by ',' lines terminated by '\n'" -u$ID -p$PW

# Disk
$HOME/sbin/distcmd.sh df | grep "Server:\|\/sata_ssd" | awk '{if($1 == "Server:") node=$2; else  print node ","  $3 "," $4 "," $5 "," $6}' > $RES_DIR/server-stat-disk.dat
mysql -e "load data local infile '/home/nvkvs/utils/grafana/server-stat-disk.dat' into table ${DB}.server_disk fields terminated by ',' lines terminated by '\n'" -u$ID -p$PW

mysql -e "truncate ${DB}.distribution" -u$ID -p$PW
for cluster_no in $@; do
echo "Checking cluster $cluster_no ..."
# Distribution
source ~/.use_cluster $cluster_no;flashbase check-distribution | grep -v SERVER | grep -v Total | grep -v check | grep -v "-" | sed 's/\t//' | awk '{print '"$cluster_no"'  "|" $0}' > $RES_DIR/c${cluster_no}-distribution.dat
mysql -e "load data local infile '/home/nvkvs/utils/grafana/c${cluster_no}-distribution.dat' into table ${DB}.distribution fields terminated by '|' lines terminated by '\n'" -u$ID -p$PW

# Used memory
source ~/.use_cluster $cluster_no; flashbase cli-all info memory 2>&1 | awk -F' |:' '{ if ($1 == "redis") print $4 ":" $5; else if ($1 == "used_memory") print $2;else if($1 == "Could") print "0"}' | xargs -n2 |  awk '{print '"${cluster_no}"'  " " $0}' > $RES_DIR/c${cluster_no}-used-memory.dat
mysql -e "load data local infile '/home/nvkvs/utils/grafana/c${cluster_no}-used-memory.dat' into table ${DB}.used_memory fields terminated by ' '  lines terminated by '\n'" -u$ID -p$PW

# In-memory data keys
source ~/.use_cluster $cluster_no; flashbase cli-all info keyspace 2>&1 | awk -F',| |=' '{ if ($1 == "redis") print $4F; else if ($1 ~ /:/) print $8;else if($1 == "Could") print "0"}' | xargs -n2 | sort | awk '{print '"$cluster_no"'  " " $0}' > $RES_DIR/c${cluster_no}-in-memory-data-keys.dat
mysql -e "load data local infile '/home/nvkvs/utils/grafana/c${cluster_no}-in-memory-data-keys.dat' into table ${DB}.datakeys fields terminated by ' '  lines terminated by '\n'" -u$ID -p$PW

# Partitions
source ~/.use_cluster $cluster_no; flashbase cli-all info keyspace 2>&1 | awk -F' |:|,|=|_' '{ if ($1 == "redis") print $4 ":" $5; else if ($8 == "expires") print $9;else if($1 == "Could") print "0"}' | xargs -n2 | sort | awk '{print '"$cluster_no"'  " " $0}' > $RES_DIR/c${cluster_no}-partitions.dat
mysql -e "load data local infile '/home/nvkvs/utils/grafana/c${cluster_no}-partitions.dat' into table ${DB}.partitions fields terminated by ' ' lines terminated by '\n'" -u$ID -p$PW

# Eviction
source ~/.use_cluster $cluster_no; flashbase cli-all info eviction 2>&1 | awk -F' |:' '{ if ($1 == "redis") print $4 ":" $5; else if ($5 == "avg") print ( $8 + 0 );else if($1 == "Could") print "0"}' | xargs -n2 | sort | awk '{print '"$cluster_no"'  " " $0}' > $RES_DIR/c${cluster_no}-evictions.dat
mysql -e "load data local infile '/home/nvkvs/utils/grafana/c${cluster_no}-evictions.dat' into table ${DB}.evictions fields terminated by ' ' lines terminated by '\n'" -u$ID -p$PW

# Storage
source ~/.use_cluster $cluster_no; flashbase cli-all info storage 2>&1 | awk -F' |:' '{ if ($1 == "redis") print $4 ":" $5; else if ($1 == "DB0_size(KByte)") print ( $2 + 0 );else if($1 == "Could") print "0"}' | xargs -n2 | sort | awk '{print '"$cluster_no"'  " " $0}' > $RES_DIR/c${cluster_no}-storages.dat
mysql -e "load data local infile '/home/nvkvs/utils/grafana/c${cluster_no}-storages.dat' into table ${DB}.storages fields terminated by ' '  lines terminated by '\n'" -u$ID -p$PW

# Configures
key="maxmemory"
desc="Max memory of each redis-server."
value=`source ~/.use_cluster $cluster_no; flashbase cli config get ${key} | xargs -n2 | awk '{print $2}'`
mysql -e "insert into ${DB}.configs (cluster, feature, value, description)  values ('${cluster_no}', '${key}', '${value}', '${desc}')" -u$ID -p$PW

key="flash-db-ttl"
desc="Time(sec) to keep data."
value=`source ~/.use_cluster $cluster_no; flashbase cli config get ${key} | xargs -n2 | awk '{print $2}'`
mysql -e "insert into ${DB}.configs (cluster, feature, value, description)  values ('${cluster_no}', '${key}', '${value}', '${desc}')" -u$ID -p$PW

key="flash-db-size-limit"
desc="Used DB(disk) size of each redis-server."
value=`source ~/.use_cluster $cluster_no; flashbase cli config get ${key} | xargs -n2 | awk '{print $2}'`
mysql -e "insert into ${DB}.configs (cluster, feature, value, description)  values ('${cluster_no}', '${key}', '${value}', '${desc}')" -u$ID -p$PW

key="row-store-enabled"
desc="If yes, this cluster uses row-store. If no, this cluster uses column-store."
value=`source ~/.use_cluster $cluster_no; flashbase cli config get ${key} | xargs -n2 | awk '{print $2}'`
mysql -e "insert into ${DB}.configs (cluster, feature, value, description)  values ('${cluster_no}', '${key}', '${value}', '${desc}')" -u$ID -p$PW

done

# Remove old data
mysql -e "DELETE FROM ${DB}.server_cpu WHERE event_time < DATE_SUB(NOW(), INTERVAL $KEEPDAYS DAY)" -u$ID -p$PW
mysql -e "DELETE FROM ${DB}.server_memory WHERE event_time < DATE_SUB(NOW(), INTERVAL $KEEPDAYS DAY)" -u$ID -p$PW
mysql -e "DELETE FROM ${DB}.server_disk WHERE event_time < DATE_SUB(NOW(), INTERVAL $KEEPDAYS DAY)" -u$ID -p$PW
mysql -e "DELETE FROM ${DB}.used_memory WHERE event_time < DATE_SUB(NOW(), INTERVAL $KEEPDAYS DAY)" -u$ID -p$PW
mysql -e "DELETE FROM ${DB}.datakeys WHERE event_time < DATE_SUB(NOW(), INTERVAL $KEEPDAYS DAY)" -u$ID -p$PW
mysql -e "DELETE FROM ${DB}.partitions WHERE event_time < DATE_SUB(NOW(), INTERVAL $KEEPDAYS DAY)" -u$ID -p$PW
mysql -e "DELETE FROM ${DB}.evictions WHERE event_time < DATE_SUB(NOW(), INTERVAL $KEEPDAYS DAY)" -u$ID -p$PW
mysql -e "DELETE FROM ${DB}.storages WHERE event_time < DATE_SUB(NOW(), INTERVAL $KEEPDAYS DAY)" -u$ID -p$PW
[nvkvs@fbg02 utils]$

```

# make_grafana_report.sh
```
#!/bin/bash
source $HOME/.bashrc
gen-grafana-data.sh {db name} {mysql id} {mysql pw} {보관일자} {cluster no...} 
```

# Crontab 설정

```
*/10 * * * * /home/nvkvs/utils/make_grafana_report.sh >> /home/nvkvs/utils/grafana/log/result.log 2>&1
```
