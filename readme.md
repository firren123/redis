# Docker 笔记

## 1.创建nginx镜像
### 1.注意事项
1.镜像名称必须是小写
2.查看容器的日志
```yml
docker logs 容器id
```
3.对一个文件的操作，最好放一条RUN里面，分开就容易导致路径错误



### 2.创建网卡

docker network create redisnetwork  --subnet 192.168.2.1/24 


### 3.创建容器

docker run -itd --name redis-master --network redisnetwork --ip 192.168.2.2 redis:v1

docker run -itd --name redis-slave --network redisnetwork --ip 192.168.2.3 redis:v1

docker run -itd  --privileged --name redis-slave3 --network redisnetwork --ip 192.168.2.6 redis:v1

docker run -itd --name php72 --network redisnetwork --ip 192.168.2.100 php:7.2

docker run -itd --name nginx_php -v /Users/lichenjun/www/liuxin/redis1909/dockerfile/www:/www --network redisnetwork --ip 192.168.2.101 -p 82:80 nginx2
 模拟网络延迟
 ///Users/lichenjun/www/liuxin/redis1909/dockerfile/redis/teacher/redis
docker run --privileged -itd -v /Users/lichenjun/www/liuxin/redis1909/dockerfile/redis/teacher/redis/master/conf:/usr/src/redis/conf --name redis-master2 --network redisnetwork -p 6381:6379 --ip 192.168.2.4 teacher_redis

docker run --privileged -itd -v /Users/lichenjun/www/liuxin/redis1909/dockerfile/redis/teacher/redis/slave/conf:/usr/src/redis/conf --name redis-slave2 --network redisnetwork -p 6382:6379 --ip 192.168.2.5 teacher_redis

### 4.主从连接
docker exec -it redis-slave bash
root@9f0816d5716e:/data# redis-cli
127.0.0.1:6379> slaveof 192.168.2.2 6379

1.配置文件
	在从服务器的配置文件中加入：slaveof <masterip> <masterport>
2.启动命令
	redis-server启动命令后加入：--slaveof <masterip> <masterport>
3.客户端命令
	redis服务器启动后，直接通过客户端执行命令：slaveof <masterip> <masterport>,则该redis实例成为从节点。
通过 info reeplication 命令可以看到复制的一些参数信息
4.主节点有密码
	masterauth <master-password>
	设置密码：config set requirepass test123
	查看密码：config get requirepass
	密码验证：auth test123
修改配置， 把redis保护模式关闭掉了
配置文件
protected-mode no 
### 5 复制
全量复制
用于初次复制或其它无法进行部分复制的情况，将主节点中的所有数据都发送给从节点，是一个非常重型的操作，当数据量较大时，会对主从节点和网络造成很大的开销
	1、Redis 内部会发出一个同步命令，刚开始是 Psync 命令，Psync ? -1表示要求 master 主机同步数据
	2、主机会向从机发送 runid 和 offset，因为 slave 并没有对应的 offset，所以是全量复制
	3、从机 slave 会保存 主机master 的基本信息 save masterInfo
	4、主节点收到全量复制的命令后，执行bgsave（异步执行），在后台生成RDB文件（快照），并使用一个缓冲区（称为复制缓冲区）记录从现在开始执行
	的所有写命令
	5、主机send RDB 发送 RDB 文件给从机
	6、发送缓冲区数据
	7、刷新旧的数据，从节点在载入主节点的数据之前要先将老数据清除
	8、加载 RDB 文件将数据库状态更新至主节点执行bgsave时的数据库状态和缓冲区数据的加载。

部分复制
用于处理在主从复制中因网络闪断等原因造成的数据丢失场景，当从节点再次连上主节点后，如果（条件允许)，主节点会补发丢失数据给从节点。
因为补发的数据远远小于全量数据，可以有效避免全量复制的过高开销，需要注意的是，如果网络中断时间过长，造成主节点没有能够完整地保存中断期间执行
的写命令，则无法进行部分复制，仍使用全量复制
复制偏移量
参与复制的主从节点都会维护自身复制偏移量。主节点（master）在处理完写入命令后，会把命令的字节长度做累加记录，统计信息在 info relication 中的
master_repl_offset 指标中：

	1、如果网络抖动（连接断开 connection lost）
    2、主机master 还是会写 replbackbuffer（复制缓冲区）
    3、从机slave 会继续尝试连接主机
    4、从机slave 会把自己当前 runid 和偏移量传输给主机 master，并且执行 pysnc 命令同步
    5、如果 master 发现你的偏移量是在缓冲区的范围内，就会返回 continue 命令
    6、同步了 offset 的部分数据，所以部分复制的基础就是偏移量 offset。



### 6.备份redis 
0.创建shell脚本执行
1.备份命令 redis-cli -a 123456 bgsave
2.检查备份是否完成
3.拷贝文件到备份目录
4.删除过期的备份文件
```yml
查看持久化状态
127.0.0.1:6379> info persistence
# Persistence
loading:0    #1正在持久化
rdb_changes_since_last_save:0
rdb_bgsave_in_progress:0 #1正在rdb复制 0 没有在复制 （备份rdb要看这个参数）
rdb_last_save_time:1568716403 #最后一次成功持久化时间
rdb_last_bgsave_status:ok  #是否持久化成功
rdb_last_bgsave_time_sec:0 #持久化用了多久 单位（秒）
rdb_current_bgsave_time_sec:-1
rdb_last_cow_size:188416
aof_enabled:0
aof_rewrite_in_progress:0
aof_rewrite_scheduled:0
aof_last_rewrite_time_sec:-1
aof_current_rewrite_time_sec:-1
aof_last_bgrewrite_status:ok
aof_last_write_status:ok
aof_last_cow_size:0
```

rdb数据备份
```yml
#获取持久化是否正在执行
#!/bin/sh
# rdb数据备份
redis-cli -a 123456 bgsave
info=`redis-cli -a 123456 info persistence|grep rdb_bgsave_in_progress|awk -F":" '{print $2}'`
while [ $info -eq 1 ]
do
        sleep 1
        info=`redis-cli -a 123456 info persistence|grep rdb_bgsave_in_progress|awk -F":" '{print $2}'`
done
dateDir=/usr/src/redis/data/rdb/`date +%y%m%d%H`
if [ ! -d $dateDir ];then
        mkdir $dateDir
fi
dateFile=`date +%M`
Dir=${dateDir}/${dateFile}.rdb
cp  /usr/src/redis/data/dump.rdb $Dir
#删除60分钟之前的备份
find /usr/src/redis/data/rdb -name "*.rdb" -mmin +60 -exec rm -rf {} \;

```
aof数据备份
```yml
#/bin/sh
# aof backup

redis-cli -a 123456 BGREWRITEAOF
info=`redis-cli -a 123456 info persistence|grep aof_rewrite_in_progress|awk -F":" '{print $2}'`
while [ $info -eq 1]
do
        sleep 1
        info=`redis-cli -a 123456 info persistence|grep aof_rewrite_in_progress|awk -F":" '{print $2}'`

done
dateDir=/usr/src/redis/data/aof/`date +%y%m%d%H`
if [ ! -d $dateDir ];then
        mkdir -p $dateDir
fi
dateFile=`date +%M`
Dir=${dateDir}/${dateFile}.aof
cp /usr/src/redis/data/appendonly.aof $Dir
find /usr/src/redis/data/aof -name "*.aof" -mmin +60 -exec rm -rf {} \;

```



###########################################
## 附加  查看所有容器ip
docker inspect -f='{{.Name}} {{.NetworkSettings.IPAddress}} {{.HostConfig.PortBindings}}' $(docker ps -aq)


密码登录
127.0.0.1:6379> auth 123456


# 安装docker-compose
```sh
sudo curl -L https://github.com/docker/compose/releases/download/1.24.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
```

# 手动创建redis集群


```sh
CLUSTER info : 打印集信息
CLUSTER nodes : 列出集群当前已知的所有节点（node）的相关信息
CLUSTER meet <ip> <port> : 将IP和port锁指定的节点添加到集群当中
CLUSTER addslots <slot> [slot ...]: 将一个或多个槽（slot）指派（assign）给当前节点
CLUSTER delslots <slot> [slot ...]: 移除一个或多个槽对当前节点的指派
CLUSTER slots ：列出槽位，节点信息
CLUSTER slaves <node_id>: 列出指定节点小米的从节点信息
CLUSTER replicate <node_id> : 将当前节点设置为指定节点的从节点

 
#提示篇
CLUSTER saveconfig : 手动执行命令报错集群的配置文件，集群默认在配置修改的时候会自动保存配置文件
CLUSTER keyslot <key> :列出key存放在哪个槽上
CLUSTER flushslots : 移除指派给当前节点的所有槽，让当前节点变成一个没有指派任何槽的节点
CLUSTER countkeysinslot <slot> : 返回槽目前包含的键值对数量
CLUSTER getkeysinslot <slot> <count> : 返回count个槽中的键
CLUSTER setslot <slot> node <node_id> : 将槽指派给指定的节点，如果槽已经指派给另一个节点，那么闲让另一个节点删除该槽，然后再进行指派
CLUSTER setslot <slot> migrating <node_id> 将本节点的槽迁移到指定的节点中
CLUSTER setslot <slot> importing <node_id> 从node_id指定的节点中导入槽到本节点
CLUSTER setslot <slot> stable : 取消对槽的导入或迁移


CLUSTER failover : 手动进行故障转移
CLUSTER forget <node_id> :从集群中移除指定的节点，这样就无法完成握手，过期时为60s,60s后两节点又会继续完成握手
CLUSTER reset [HARD|SOFT]: 重置集群信息，soft是清空其他节点的信息，但不修改自己的ID，hard还会修改自己的ID，hard还会修改自己的ID，不传该参数则使用soft方式。

CLUSTER count-failure-reports <node_id> : 列出某个节点的故障报告的长度
CLUSTER SET-CONFIG-EPOCH : 设置节点epoch，只有在节点加入集群前才能设置 

```

## 1 先握手
```sh
# 先进6391里面
># redis-cli -a sixstar
127.0.0.1:6379> cluster nodes
aa57cf068ec165a6342f41219fc9e9d74143aec4 39.96.196.246:6397@16397 master - 0 1569738821000 5 connected
02d10e92d78de2e7d1f3e0ae0478ac1db10027b9 39.96.196.246:6392@16392 master - 0 1569738821394 1 connected
3d0dc656bf3a25b5b3bf53003df48e81f496c855 39.96.196.246:6391@16391 myself,master - 0 1569738819000 3 connected
63da978af6a1d3a62e827b13661242e6f745e833 39.96.196.246:6399@16399 master - 0 1569738819389 6 connected
bcaa11483ee4d1875a879f897e734652006a18df 39.96.196.246:6396@16396 master - 0 1569738817000 0 connected
6303191227d6c41d81c03b5c707a2302ce29ced8 39.96.196.246:6398@16398 master - 0 1569738820000 7 connected
1363d3366593f7bf24a8f13e4139c82b27f66919 39.96.196.246:6393@16393 master - 0 1569738819000 2 connected
787a3c161416af97161a2f83e226aa7330eca7f4 39.96.196.246:6394@16394 master - 0 1569738819000 4 connected
127.0.0.1:6379> 
#数据保存在nodes-6379.conf 文件中  这个是配置文件中设计的
```
## 2 设置主从关系

```sh
# 6392当6391的从节点
redis-cli -a sixstar -h 39.96.196.246 -p 6392 CLUSTER replicate 3d0dc656bf3a25b5b3bf53003df48e81f496c855
# 6394当6393的从节点
redis-cli -a sixstar -h 39.96.196.246 -p 6394 CLUSTER replicate 1363d3366593f7bf24a8f13e4139c82b27f66919
# 6396当6397的从节点
redis-cli -a sixstar -h 39.96.196.246 -p 6396 CLUSTER replicate aa57cf068ec165a6342f41219fc9e9d74143aec4
# 6398当6399的从节点
redis-cli -a sixstar -h 39.96.196.246 -p 6398 CLUSTER replicate 63da978af6a1d3a62e827b13661242e6f745e833

127.0.0.1:6379> CLUSTER nodes
bcaa11483ee4d1875a879f897e734652006a18df 39.96.196.246:6396@16396 slave aa57cf068ec165a6342f41219fc9e9d74143aec4 0 1569739676243 5 connected
3d0dc656bf3a25b5b3bf53003df48e81f496c855 39.96.196.246:6391@16391 master - 0 1569739675000 3 connected
1363d3366593f7bf24a8f13e4139c82b27f66919 39.96.196.246:6393@16393 master - 0 1569739673000 2 connected
02d10e92d78de2e7d1f3e0ae0478ac1db10027b9 39.96.196.246:6392@16392 myself,slave 3d0dc656bf3a25b5b3bf53003df48e81f496c855 0 1569739672000 1 connected
63da978af6a1d3a62e827b13661242e6f745e833 39.96.196.246:6399@16399 master - 0 1569739672000 6 connected
787a3c161416af97161a2f83e226aa7330eca7f4 39.96.196.246:6394@16394 slave 1363d3366593f7bf24a8f13e4139c82b27f66919 0 1569739674238 4 connected
aa57cf068ec165a6342f41219fc9e9d74143aec4 39.96.196.246:6397@16397 master - 0 1569739673236 5 connected
6303191227d6c41d81c03b5c707a2302ce29ced8 39.96.196.246:6398@16398 slave 63da978af6a1d3a62e827b13661242e6f745e833 0 1569739675240 7 connected
127.0.0.1:6379> 

```
## 3 分配虚拟槽  绑定槽（slot）位置
> Redis集群把所有的数据映射到16384个槽中，每个key会映射为一个固定的槽，只有当节点分配了槽，才能响应和这些槽关联的键命令，通过CLUSTER addslots命令为节点分配槽
> 只能一个一个添加
> sh只能一个一个添加 bash可以批量添加
>利用bash特性批量设置槽（slots），命令如下：

```sh
redis-cli -h 39.96.196.246 -p 6391 -a sixstar cluster addslots {0..4095}
redis-cli -h 39.96.196.246 -p 6393 -a sixstar cluster addslots {4096..8190}
redis-cli -h 39.96.196.246 -p 6399 -a sixstar cluster addslots {8191..12285}
redis-cli -h 39.96.196.246 -p 6397 -a sixstar cluster addslots {12286..16383}

127.0.0.1:6379> CLUSTER NODES
aa57cf068ec165a6342f41219fc9e9d74143aec4 39.96.196.246:6397@16397 master - 0 1569740358835 5 connected 12286-16383
02d10e92d78de2e7d1f3e0ae0478ac1db10027b9 39.96.196.246:6392@16392 slave 3d0dc656bf3a25b5b3bf53003df48e81f496c855 0 1569740356000 3 connected
3d0dc656bf3a25b5b3bf53003df48e81f496c855 39.96.196.246:6391@16391 myself,master - 0 1569740357000 3 connected 0-4095
63da978af6a1d3a62e827b13661242e6f745e833 39.96.196.246:6399@16399 master - 0 1569740357832 6 connected 8191-12285
bcaa11483ee4d1875a879f897e734652006a18df 39.96.196.246:6396@16396 slave aa57cf068ec165a6342f41219fc9e9d74143aec4 0 1569740359836 5 connected
6303191227d6c41d81c03b5c707a2302ce29ced8 39.96.196.246:6398@16398 slave 63da978af6a1d3a62e827b13661242e6f745e833 0 1569740357000 7 connected
1363d3366593f7bf24a8f13e4139c82b27f66919 39.96.196.246:6393@16393 master - 0 1569740359000 2 connected 4096-8190
787a3c161416af97161a2f83e226aa7330eca7f4 39.96.196.246:6394@16394 slave 1363d3366593f7bf24a8f13e4139c82b27f66919 0 1569740355000 4 connected
127.0.0.1:6379> 

#现在写一个数据会报错
127.0.0.1:6379> set  a b
(error) MOVED 15495 39.96.196.246:6397
127.0.0.1:6379> 
#要用集群的模式访问
bash-5.0# redis-cli -a sixstar -c
Warning: Using a password with '-a' option on the command line interface may not be safe. #不用管
127.0.0.1:6379> set a b
-> Redirected to slot [15495] located at 39.96.196.246:6397
OK
39.96.196.246:6397> set b b
-> Redirected to slot [3300] located at 39.96.196.246:6391
OK
39.96.196.246:6391> set c c
-> Redirected to slot [7365] located at 39.96.196.246:6393
OK
39.96.196.246:6393> set d d
-> Redirected to slot [11298] located at 39.96.196.246:6399
OK
39.96.196.246:6399> 
#自动存放在对应的集群节点上

```

## 4 移除虚拟槽
>CLUSTER delslots <slot> [slot ...]: 移除一个或多个槽对当前节点的指派

```sh
39.96.196.246:6391> CLUSTER delslots 11298 
OK
39.96.196.246:6391> get d
-> Redirected to slot [11298] located at 39.96.196.246:6399
"d"
39.96.196.246:6399> 
#直接删除，是不管用的当有数据的时候
#把slot=9000迁移到6391
39.96.196.246:6399> CLUSTER SETSLOT 9000 migrating 3d0dc656bf3a25b5b3bf53003df48e81f496c855
OK


```




# redis-trib.rb 创建集群环境

## 1.创建集群
> 一行命令创建集群

帮助命令

```sh
bash-5.0# ./redis-trib.rb help
Usage: redis-trib <command> <options> <arguments ...>
   #创建集群
  create          host1:port1 ... hostN:portN
                  --replicas <arg>
  #检查集群状态
  check           host:port
  #查看集群信息
  info            host:port
  fix             host:port
                  --timeout <arg>
  # 迁移命令             
  reshard         host:port   集群内任意节点地址，用来获取整个集群信息
                  --from <arg>  指定源节点的ID,如果有多个源节点，使用逗号分隔，如果是all源节点变为集群内所有主节点，在迁移过程中提示用户输入
                  --to <arg> 需要迁移的目标节点的ID，目标节点只能填写一个，在迁移过程中提示用户输入
                  --slots <arg> 需要迁移槽的总数量，在迁移过程中提示用户输入
                  --yes 当打印出reshard执行计划时，是否需要用户输入yes确认后再执行reshard
                  --timeout <arg> 控制每次migrate操作的超时时间，默认为60000毫秒
                  --pipeline <arg> 控制每次批量迁移键的数量，默认为10
  rebalance       host:port
                  --weight <arg>
                  --auto-weights
                  --use-empty-masters
                  --timeout <arg>
                  --simulate
                  --pipeline <arg>
                  --threshold <arg>
  #添加节点信息                 
  add-node        new_host:new_port existing_host:existing_port
                  --slave
                  --master-id <arg>
  #删除节点
  del-node        host:port node_id
  set-timeout     host:port milliseconds
  call            host:port command arg arg .. arg
  import          host:port
                  --from <arg>
                  --copy
                  --replace
  help            (show this help)

For check, fix, reshard, del-node, set-timeout you can specify the host and port of any working node in the cluster.
bash-5.0# 
```

```sh
./redis-trib.rb create --replicas 1 39.96.196.246:6391 39.96.196.246:6392 39.96.196.246:6393 39.96.196.246:6394 39.96.196.246:6399 39.96.196.246:6396 39.96.196.246:6397 39.96.196.246:6398

# --replicas 1  表示有一个从节点
1,2,3,4 是主节点
6，7，8，9是从节点
1=> 6
2=> 7
3=> 8
4=> 9

```

## 2. 节点伸缩

### 1.节点扩展

```sh
# 添加新节点 
# add-node [新节点] [原有节点]
bash-5.0# ./redis-trib.rb add-node 39.96.196.246:6400 39.96.196.246:6391 

bash-5.0# ./redis-trib.rb add-node 39.96.196.246:6401 39.96.196.246:6391

# 移除 节点
127.0.0.1:6379> CLUSTER RESET
OK
127.0.0.1:6379> CLUSTER NODES # 查看只有自己
8920f53314108844eeee7745052af45ab2c8d052 39.96.196.246:6401@16401 myself,master - 0 1569746688000 0 connected
127.0.0.1:6379> 

#扩展迁移 redis-trib.rb reshard host:port --from <arg> --to <arg> --slots <arg> --yes --timeout <arg> --pipeline <arg>
./redis-trib.rb reshard  39.96.196.246:6401

#下线节点



```

### 2.节点收缩

>下线节点需要把自己负责的槽迁移到其他节点，原理与之前节点扩容的迁移槽过程一致，但是过程收缩正好和扩容迁移方向相反，下线节点变为源节点，
>其他主 节点变为目标节点，源节点需要把自身负责的4096个槽均匀地迁移到其他主节点上。
>使用 redis-trib.rb reshard 命令完成槽迁移。由于每次执行 reshard 命令只能有一个目标节点，因此需要执行3次 reshard 命令 

准备导出

```sh
# 1.线下迁移槽
redis-trib.rb reshard host:port --from <arg> --to <arg> --slots <arg> --yes --timeout <arg> --pipeline <arg>
./redis-trib.rb reshard  39.96.196.246:6401
把槽均匀给其他节点就行了


# 2.忘记节点 (删除 6400 6401)
./redis-trib.rb del-node 39.96.196.246:6391  5a904932b8e8813d67989ab07df992a3b76fc05c
./redis-trib.rb del-node 39.96.196.246:6391 8920f53314108844eeee7745052af45ab2c8d052

bash-5.0# ./redis-trib.rb del-node 39.96.196.246:6391  5a904932b8e8813d67989ab07df992a3b76fc05c
>>> Removing node 5a904932b8e8813d67989ab07df992a3b76fc05c from cluster 39.96.196.246:6391
>>> Sending CLUSTER FORGET messages to the cluster...
>>> SHUTDOWN the node.
bash-5.0# ./redis-trib.rb del-node 39.96.196.246:6391 8920f53314108844eeee7745052af45ab2c8d052
>>> Removing node 8920f53314108844eeee7745052af45ab2c8d052 from cluster 39.96.196.246:6391
>>> Sending CLUSTER FORGET messages to the cluster...
>>> SHUTDOWN the node.
bash-5.0# 

```