#This my first nginx Dockerfile
# Version 1.0
# Base images 基础镜像
FROM centos
#MAINTAINER 维护者信息
MAINTAINER lichenjun<firren@163.com>

#ENV 设置环境变量
ENV PATH /usr/local/nginx/sbin:$PATH

#RUN执行以下命令
RUN yum install -y epel-release wget lftp gcc gcc-c++ make openssl-devel pcre-devel pcre python && yum clean all
RUN useradd -s /sbin/nologin -M www

RUN cd /usr/local/src && wget http://file.lichenjun.cn/nginx-1.17.3.tar.gz && tar -xvf nginx-1.17.3.tar.gz && cd nginx-1.17.3 \
	&& ./configure --prefix=/usr/local/nginx --user=www --group=www && make && make install && rm -rf *


RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime  && echo 'Asia/Shanghai' > /etc/timezone

#RUN echo "daemon off;">> /etc/nginx.conf
#EXPOSE 映射端口
EXPOSE 80
#entrypoint的作用是，把整个container变成了一个可执行的文件，这样不能够通过替换CMD的方法来改变创建container的方式。
#但是可以通过参数传递的方法影响到container内部,每个Dockerfile只能够包含一个entrypoint
#当定义了entrypoint以后，CMD只能够作为参数进行传递
#ENTRYPOINT ["nginx"]
#CMD 运行以下命令
CMD ["nginx","-g","daemon off;"]

#http://nginx.org/download/nginx-1.17.3.tar.gz
#https://mirrors.tuna.tsinghua.edu.cn/epel//epel-release-latest-7.noarch.rpm