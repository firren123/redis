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



