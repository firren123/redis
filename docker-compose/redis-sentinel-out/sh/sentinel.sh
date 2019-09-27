#!/bin/sh
echo "sentinel announce-ip $REALIP
sentinel announce-port $REALPORT
sentinel monitor mymaster $REDIS_MASTER_IP $REDIS_MASTER_PORT 2
sentinel auth-pass mymaster 123456
">>/usr/src/redis/conf/sentinel.conf
/usr/local/bin/redis-sentinel /usr/src/redis/conf/sentinel.conf
