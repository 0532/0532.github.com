---
layout: post
title: 幂等组件介绍及使用
---

{{ page.title }}
================

<p class="meta">28 Jue 2021 - 北京</p>


### 1.背景

咱们的业务很少有涉及幂等的功能，在设计账户系统时有用到，就把幂等的功能抽到一个单独的服务，打包成一个简单的工具包，方便以后使用

### 2.使用方法

**I，添加依赖**

```text
<dependency>
  <groupId>com.rongbei.saas</groupId>
  <artifactId>saas-idempotent-spring-boot-starter</artifactId>
  <version>0.0.1-SNAPSHOT</version>
</dependency>
```


**II，创建表**


```text
CREATE TABLE `trade_seq` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `tenant_id` varchar(32) NOT NULL COMMENT '租户id',
  `trace_id` varchar(50) NOT NULL DEFAULT '' COMMENT 'traceid',
  `request_id` varchar(50) NOT NULL DEFAULT '' COMMENT '交易流水号',
  `request_req` varchar(2000) NOT NULL DEFAULT '' COMMENT '入参',
  `request_type` int(4) NOT NULL COMMENT '交易类型，',
  `comments` varchar(255) DEFAULT NULL COMMENT '备注',
  `request_status` int(4) NOT NULL COMMENT '0-初始化，1-成功，2-失败',
  `operator` varchar(50) DEFAULT '' COMMENT '操作人',
  `ctime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `mtime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_request` (`request_id`,`request_status`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COMMENT='交易流水';
```

**III，添加扫描**

```text

start类中添加 `com.rongbei.saas.idempotent` 进行注解扫描

mybatis配置文件中添加 `com.rongbei.saas.idempotent.repository.mapper` mapper扫描

用法有两种：
    1. `@RequestIdempotent("#request.requestId")` 显示的从入参中指定唯一主键，进行幂等处理
    2. `@RequestIdempotent` 没有指定主键，会通过`所有入参+分钟级别时间戳`进行md5生成唯一主键，进行幂等处理，

  注：2 用法只能控制分钟级别重复请求，无法控制全局幂等，需要全局幂等还需要入参指定

```

### 3.优化空间

1，mysql数据库升级为其他db

2，调用方无需创建表，统一调用幂等服务
