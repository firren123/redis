#!/bin/sh
echo "slave-announce-ip $REALIP
slave-announce-port $REALPORT
      ">>/usr/src/redis/conf/redis.conf
/usr/local/bin/redis-server /usr/src/redis/conf/redis.conf
