#!/bin/sh

# 所有服务管理

# echo 输出颜色值
color_blue="\033[36m"
color_white="\033[37m"
color_base=$color_blue
color_other=$color_white

# service执行类型
exec_type=""
exec_type_start="start"
exec_type_stop="stop"

# service相关变量
service_name=""
service_path=""
service_start=""
service_stop=""
service_log=""
service_isRestart=true

# 用户目录
user_folder="/Users/tanliqingcn/SoftWare/settings/"
# 输出目录
out_folder_log=$user_folder"logs/service_my/"
# brew目录
brew_folder="/usr/local/Cellar/"

# service-mysql
service_mysql()
{
  service_name="mysql"
  service_path=$user_folder
  service_start="mysql.server start"
  service_stop="mysql.server stop"
  service_isRestart=false
  service_handle
}

# service-nginx
service_nginx()
{
  service_name="nginx"
  service_path=$user_folder
  service_start="sudo nginx"
  service_stop="sudo nginx -s stop"
  service_isRestart=true
  service_handle
}

# service-zooKeeper
service_zooKeeper()
{
  service_name="zooKeeper"
  service_path="/Users/tanliqingcn"
  service_start="zkServer start"
  service_stop="zkServer stop"
  service_isRestart=true
  service_handle
}

# service-hadoop
service_hadoop()
{
  service_name="hadoop"
  service_path=$user_folder"hadoop/hadoop-2.7.1/sbin"
  service_start="./start-all.sh"
  service_stop="./stop-all.sh"
  service_isRestart=true
  service_handle
}

# service-spark
service_spark()
{
  service_name="spark"
  service_path=$brew_folder"apache-spark/1.5.1/libexec/sbin"
  service_start="./start-all.sh"
  service_stop="./stop-all.sh"
  service_isRestart=true
  service_handle
}

# service-redis
service_redis()
{
  service_name="redis"
  service_path=$user_folder"redis/data"
  service_log=$out_folder_log$service_name".log"
  service_start="nohup redis-server > $service_log"
  service_stop="echo $service_name has no stop command"
  service_isRestart=false
  service_handle
}

# service-elasticsearch
service_elasticsearch()
{
  service_name="elasticsearch"
  service_path=$user_folder"elasticsearch/elasticsearch-1.6.0"
  service_log=$out_folder_log$service_name".log"
  service_start="nohup bin/elasticsearch > $service_log"
  service_stop="echo $service_name has no stop command"
  service_isRestart=false
  service_handle
}

# service-cassandra
service_cassandra()
{
  service_name="cassandra"
  service_path=$brew_folder"cassandra/2.2.2/bin"
  service_log=$out_folder_log$service_name".log"
  service_start="nohup cassandra > $service_log"
  service_stop="echo $service_name has no stop command"
  service_isRestart=false
  service_handle
}

# service-hive
service_hive()
{
  service_name="hive"
  service_path=$user_folder"hive/hive-1.0.1/bin"
  service_log=$out_folder_log$service_name".log"
  service_start="nohup ./hive --service metastore > $service_log"
  service_stop="echo $service_name has no stop command"
  service_isRestart=false
  service_handle
}

# service-复杂的启动处理
service_start_complex()
{
  if [ "$service_isRestart" = true ];then
    service_start
  else
    service_start_once
  fi
}

# service-只能启动一次的
service_start_once()
{
  if ps -ef | grep $service_name | egrep -v grep >/dev/null;then
    echo "$color_base""$service_name cannot restarted because of no stop command."
  else
    service_start
  fi
}

# service-默认的启动处理
service_start()
{
  if ps -ef | grep $service_name | egrep -v grep >/dev/null;then
    echo "$color_base""$service_name is started. And $service_name will restart."
    echo "$color_other""now $service_name service will export execution process results."
    cd $service_path
    eval $service_stop
    eval $service_start
    echo "$color_base""$service_name is restarted."
  else
    echo "$color_base""$service_name will start."
    echo "$color_other""now $service_name service will export execution process results."
    cd $service_path
    eval $service_start
    echo "$color_base""$service_name is started."
  fi
}

# service-停止
service_stop()
{
  echo "$color_base""$service_name will stop."
  echo "$color_other""now $service_name service will export execution process results."
  cd $service_path
  eval $service_stop
  echo "$color_base""$service_name is stoped."
}

# service-处理
service_handle()
{
  if [ "$exec_type" = "$exec_type_start" ];then
    service_start_complex
  else
    service_stop
  fi
}

# service-基础服务
executionSequence_base()
{
  echo "$color_base""Will $exec_type the basic service."
  service_mysql
  service_nginx
}

# service-大数据相关服务
executionSequence_bigData()
{
  echo "$color_base""Will $exec_type the big data service."
  service_zooKeeper
  service_hadoop
  service_spark
}

# 暂时不能解决有：命令不能退出且具有前后启动关系的任务执行的问题
# 互不影响的执行
execution_no_effect()
{
  service_redis & service_elasticsearch & service_hive & service_cassandra
}

# 清空日志
clearLogs()
{
  echo "Will clear logs."
  cd $out_folder_log
  eval "rm *"
}
# service-执行顺序
executionSequence()
{
  clearLogs
  executionSequence_base
  executionSequence_bigData
  execution_no_effect
}

case "$1" in
  'start')
    exec_type=$exec_type_start
    executionSequence
    ;;
  'stop')
    exec_type=$exec_type_stop
    executionSequence
    ;;
  *)
    echo "$color_base""Commands: "
    echo "  start: start all service."
    echo "  stop: stop all service which has stop command."
    echo "Comments: These services include mysql、nginx、redis、elasticsearch、"
    echo "          elasticsearch、zookeeper、hadoop、spark、hive、cassandra."
    exit 1
    ;;
esac

