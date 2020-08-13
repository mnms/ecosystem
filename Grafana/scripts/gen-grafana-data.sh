#!/bin/bash

DB=$1
shift
ID=$1
shift
PW=$1
shift
KEEPDAYS=$1
shift
HOST=$1
shift

CURR=`date`
echo "run gen-daily-report.sh on $CURR"
RES_DIR="$HOME/utils/grafana"

# CPU
$HOME/sbin/distcmd.sh top -b -n1 | grep "id\|Server"| awk '{if($1 == "Server:") print $2;else print 100-$8}' | xargs -n2 > $RES_DIR/server-stat-cpu.dat
mysql -e "LOAD DATA LOCAL INFILE '$HOME/utils/grafana/server-stat-cpu.dat' INTO TABLE ${DB}.server_cpu fields terminated by ' ' lines terminated by '\n'" -u$ID -p$PW -h$HOST

# Memory
$HOME/sbin/distcmd.sh free | awk '{if($1 == "Mem:") print "," $2 "," $3 ","  $7;else if($1 == "Server:") print $2}' | xargs -n2 > $RES_DIR/server-stat-memory.dat
mysql -e "LOAD DATA LOCAL INFILE '$HOME/utils/grafana/server-stat-memory.dat' INTO TABLE ${DB}.server_memory fields terminated by ',' lines terminated by '\n'" -u$ID -p$PW -h$HOST

# Disk
$HOME/sbin/distcmd.sh df | grep "Server:\|\/sata_ssd" | awk '{if($1 == "Server:") node=$2; else  print node ","  $3 "," $4 "," $5 "," $6}' > $RES_DIR/server-stat-disk.dat
mysql -e "load data local infile '$HOME/utils/grafana/server-stat-disk.dat' into table ${DB}.server_disk fields terminated by ',' lines terminated by '\n'" -u$ID -p$PW -h$HOST


mysql -e "truncate ${DB}.distribution" -u$ID -p$PW -h$HOST
for cluster_no in $@; do
echo "Checking cluster $cluster_no ..."

# set cluster-#{NUM} path
unset SR2_HOME
unset SR2_CONF
unset SR2_LIB

export SR2_HOME=${HOME}/tsr2/cluster_${cluster_no}/tsr2-assembly-1.0.0-SNAPSHOT
export SR2_CONF=${SR2_HOME}/conf
export SR2_LIB=${SR2_HOME}/lib
export PATH=$(echo $PATH | tr ':' '\n' | sed '/^$/d' | grep -v cluster | awk '!x[$0]++' | tr '\n' ':')

echo $PATH | grep ${SR2_HOME} > /dev/null
RET=$?
if [[ $RET -eq 1 ]]; then
    PATH=$SR2_HOME/bin:$SR2_HOME/sbin:$PATH
fi

# Distribution
flashbase check-distribution | grep -v SERVER | grep -v Total | grep -v check | grep -v "-" | sed 's/\t//' | awk '{print '"$cluster_no"'  "|" $0}' > $RES_DIR/c${cluster_no}-distribution.dat
mysql -e "load data local infile '$HOME/utils/grafana/c${cluster_no}-distribution.dat' into table ${DB}.distribution fields terminated by '|' lines terminated by '\n'" -u$ID -p$PW -h$HOST

# Used memory
flashbase cli-all info memory 2>&1 | awk -F' |:' '{ if ($1 == "redis") print $4 ":" $5; else if ($1 == "used_memory") print $2;else if($1 == "Could") print "0"}' | xargs -n2 |  awk '{print '"${cluster_no}"'  " " $0}' > $RES_DIR/c${cluster_no}-used-memory.dat
mysql -e "load data local infile '$HOME/utils/grafana/c${cluster_no}-used-memory.dat' into table ${DB}.used_memory fields terminated by ' '  lines terminated by '\n'" -u$ID -p$PW -h$HOST

# In-memory data keys
flashbase cli-all info keyspace 2>&1 | awk -F',| |=' '{ if ($1 == "redis") print $4F; else if ($1 ~ /:/) print $8;else if($1 == "Could") print "0"}' | xargs -n2 | sort | awk '{print '"$cluster_no"'  " " $0}' > $RES_DIR/c${cluster_no}-in-memory-data-keys.dat
mysql -e "load data local infile '$HOME/utils/grafana/c${cluster_no}-in-memory-data-keys.dat' into table ${DB}.datakeys fields terminated by ' '  lines terminated by '\n'" -u$ID -p$PW -h$HOST

# Partitions
flashbase cli-all info keyspace 2>&1 | awk -F' |:|,|=|_' '{ if ($1 == "redis") print $4 ":" $5; else if ($8 == "expires") print $9;else if($1 == "Could") print "0"}' | xargs -n2 | sort | awk '{print '"$cluster_no"'  " " $0}' > $RES_DIR/c${cluster_no}-partitions.dat
mysql -e "load data local infile '$HOME/utils/grafana/c${cluster_no}-partitions.dat' into table ${DB}.partitions fields terminated by ' ' lines terminated by '\n'" -u$ID -p$PW -h$HOST

# Eviction
flashbase cli-all info eviction 2>&1 | awk -F' |:' '{ if ($1 == "redis") print $4 ":" $5; else if ($5 == "avg") print ( $8 + 0 );else if($1 == "Could") print "0"}' | xargs -n2 | sort | awk '{print '"$cluster_no"'  " " $0}' > $RES_DIR/c${cluster_no}-evictions.dat
mysql -e "load data local infile '$HOME/utils/grafana/c${cluster_no}-evictions.dat' into table ${DB}.evictions fields terminated by ' ' lines terminated by '\n'" -u$ID -p$PW -h$HOST

# Storage
flashbase cli-all info storage 2>&1 | awk -F' |:' '{ if ($1 == "redis") print $4 ":" $5; else if ($1 == "DB0_size(KByte)") print ( $2 + 0 );else if($1 == "Could") print "0"}' | xargs -n2 | sort | awk '{print '"$cluster_no"'  " " $0}' > $RES_DIR/c${cluster_no}-storages.dat
mysql -e "load data local infile '$HOME/utils/grafana/c${cluster_no}-storages.dat' into table ${DB}.storages fields terminated by ' '  lines terminated by '\n'" -u$ID -p$PW -h$HOST

# Configures
key="maxmemory"
desc="Max memory of each redis-server."
value=`flashbase cli config get ${key} | xargs -n2 | awk '{print $2}'`
mysql -e "insert into ${DB}.configs (cluster, feature, value, description)  values ('${cluster_no}', '${key}', '${value}', '${desc}')" -u$ID -p$PW -h$HOST

key="flash-db-ttl"
desc="Time(sec) to keep data."
value=`flashbase cli config get ${key} | xargs -n2 | awk '{print $2}'`
mysql -e "insert into ${DB}.configs (cluster, feature, value, description)  values ('${cluster_no}', '${key}', '${value}', '${desc}')" -u$ID -p$PW -h$HOST

key="flash-db-size-limit"
desc="Used DB(disk) size of each redis-server."
value=`flashbase cli config get ${key} | xargs -n2 | awk '{print $2}'`
mysql -e "insert into ${DB}.configs (cluster, feature, value, description)  values ('${cluster_no}', '${key}', '${value}', '${desc}')" -u$ID -p$PW -h$HOST

key="row-store-enabled"
desc="If yes, this cluster uses row-store. If no, this cluster uses column-store."
value=`flashbase cli config get ${key} | xargs -n2 | awk '{print $2}'`
mysql -e "insert into ${DB}.configs (cluster, feature, value, description)  values ('${cluster_no}', '${key}', '${value}', '${desc}')" -u$ID -p$PW -h$HOST

done

# Remove old data
mysql -e "DELETE FROM ${DB}.server_cpu WHERE event_time < DATE_SUB(NOW(), INTERVAL $KEEPDAYS DAY)" -u$ID -p$PW -h$HOST
mysql -e "DELETE FROM ${DB}.server_memory WHERE event_time < DATE_SUB(NOW(), INTERVAL $KEEPDAYS DAY)" -u$ID -p$PW -h$HOST
mysql -e "DELETE FROM ${DB}.server_disk WHERE event_time < DATE_SUB(NOW(), INTERVAL $KEEPDAYS DAY)" -u$ID -p$PW -h$HOST
mysql -e "DELETE FROM ${DB}.used_memory WHERE event_time < DATE_SUB(NOW(), INTERVAL $KEEPDAYS DAY)" -u$ID -p$PW -h$HOST
mysql -e "DELETE FROM ${DB}.datakeys WHERE event_time < DATE_SUB(NOW(), INTERVAL $KEEPDAYS DAY)" -u$ID -p$PW -h$HOST
mysql -e "DELETE FROM ${DB}.partitions WHERE event_time < DATE_SUB(NOW(), INTERVAL $KEEPDAYS DAY)" -u$ID -p$PW -h$HOST
mysql -e "DELETE FROM ${DB}.evictions WHERE event_time < DATE_SUB(NOW(), INTERVAL $KEEPDAYS DAY)" -u$ID -p$PW -h$HOST
mysql -e "DELETE FROM ${DB}.storages WHERE event_time < DATE_SUB(NOW(), INTERVAL $KEEPDAYS DAY)" -u$ID -p$PW -h$HOST
