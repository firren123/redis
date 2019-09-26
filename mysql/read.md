# 将MYSQL数据迁移到Redis

场景是从MySQL中将数据导入到Redis的Hash结构中。当然，最直接的做法就是遍历MySQL数据，一条一条写入到Redis中。这样可能没什么错，但是速度会非常慢。而如果能够使MySQL的查询输出数据直接能够与Redis命令行的输入数据协议相吻合，可能就省事多了。

800w的数据迁移，时间从90分钟缩短到2分钟。

案例如下：
MySQL数据表结构：
```sql
CREATE TABLE `events_all_time` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `action` varchar(255) NOT NULL,
  `count` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_action` (`action`) USING HASH COMMENT 'x'
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

```
Redis存储结构：
HSET events_all_time [action] [count]
下面是重点，能过下面SQL语句将MySQL输出直接变更成redis-cli可接收的格式：
```sql
SELECT
	concat(
	"*4\r\n",
	'$',
	LENGTH( redis_cmd ),
	'\r\n',
	redis_cmd,
	'\r\n',
	'$',
	LENGTH( redis_key ),
	'\r\n',
	redis_key,
	'\r\n',
	'$',
	LENGTH( hkey ),
	'\r\n',
	hkey,
	'\r\n',
	'$',
	LENGTH( hval ),
	'\r\n',
	hval,
	'\r'
	) as f
FROM
( SELECT 'HSET' AS redis_cmd, 'events_all_time' AS redis_key, action AS hkey, count AS hval FROM events_all_time ) AS t
```

然后用管道符重定向输出即可：
```sh
# mysql stats_db --skip-column-names --raw < events_to_redis.sql | redis-cli --pipe


mysql -h127.0.0.1 -uroot -proot composer --skip-column-names --raw < events_to_redis.sql | redis-cli -p 6381 -a 123456 --pipe
```
使用redis内部的数据格式然后走pipeline，比遍历mysql一行一行的写redis快多了!


# 多字段导入

首先需要构造数据的基本格式，如命令  
```sh
hmset news105 news_title title105 news_content content105 news_views 28 
```
拆分成以下格式：

复制代码
```sh
*8   // 按空格拆分有几段 
$5   // 代表 hmset 的字符长度
hmset
$7   // 代表 news105 的字符长度，以此类推·
news105
$10
news_title
$8
title105
$12
news_content
$10
content105
$10
news_views
$2
28
```
利用 MySQL 构造数据
数据表（news）结构：



利用 sql 拼接数据（news.sql）：
```sql
select concat('*8','\r\n','$5','\r\n','hmset','\r\n','$',LENGTH(news_id)+4,'\r\n','news',news_id,'\r\n'
,'$10','\r\n','news_title','\r\n','$',LENGTH(news_title),'\r\n',news_title,'\r\n','$12','\r\n','news_content','\r\n'
,'$',LENGTH(news_content),'\r\n',news_content,'\r\n','$10','\r\n','news_views','\r\n','$',LENGTH(news_views),'\r\n',news_views
,'\r')
from news order by news_views desc limit 0,5
```
导出 sql 执行结果（news）：
```shell
mysql -uroot -p123456 -D 数据库名 --skip-column-names --raw < news
```
--skip-column-names：不显示列名
--raw：原生输出，不做任何转义
至此，数据构造完毕。批量插入 redis：
```shell
cat news | redis-cli --pipe
```

