---
layout: post
title: RocketMQ顺序消费的应用
---

{{ page.title }}
================

<p class="meta">11 JUN 2017 - 北京</p>

最近在项目中遇到rocketMQ的顺序问题，在此记录一下

分布式消息系统作为实现分布式系统可扩展、可伸缩性的关键组件，需要具有高吞吐量、高可用等特点。而谈到消息系统的设计，就回避不了两个问题：

* 消息的顺序问题

* 消息的重复问题

实际上，RocketMQ是支持顺序消费的，但这个顺序，不是全局顺序，只是分区顺序，要全局顺序只能一个分区。
之所以出现你这个场景看起来不是顺序的，是因为发送消息的时候，消息发送默认是会采用轮询的。

![](/pic/2017/06-11-1.jpg)

而消费端消费的时候，是会分配到多个queue的，多个queue是同时拉取提交消费。

![](/pic/2017/06-11-2.jpg)

但是同一条queue里面，RocketMQ的确是能保证FIFO的。那么要做到顺序消息，应该怎么实现呢--把消息确保投递到同一条queue，

rocketmq消息生产端示例代码如下：

```java
    SendResult result = producer.send(message, new MessageQueueSelector() {
        @Override
        public MessageQueue select(List<MessageQueue> mqs, Message message, Object o) {
            int index = o.hashCode()%mqs.size();
            System.out.println("args:"+o+",hash;"+o.hashCode()+",mqs.size():"+mqs.size()+",index:"+index);
            return mqs.get(index);
        }
    },appid);
```  

即： 相同订单号的--->有相同的hashCode(hash存在负数，取正)--->有相同的模--->有相同的queue。(如果appid为int类型，可以直接取膜)

![](/pic/2017/06-11-3.jpg)

这样同一批你需要做到顺序消费的肯定会投递到同一个queue，同一个queue肯定会投递到同一个消费实例，同一个消费实例肯定是顺序拉取并顺序提交线程池的，只要保证消费端顺序消费，则大功告成！

如何保证顺序消费？ 如果是使用MessageListenerOrderly则自带此实现，如果是使用MessageListenerConcurrently，则需要把线程池改为单线程模式。还可以在消费端Consumer消费时加上了逻辑怕判断，当工单的前一个状态没收收到时，把当前消息 `SUSPEND_CURRENT_QUEUE_A_MOMENT` 挂起消费队列一会会，稍后继续消费。
不过消费失败的消息一直失败，也不可能一直消费。当超过消费重试上限时，Consumer 会将消费失败超过上限（默认 ：16次）的消息发回到 Broker 死信队列。此时，消息队列无需挂起，继续消费后面的消息。


让我们来看看代码：

```java
1: // 【ConsumeMessageOrderlyService.java】
  2: /**
  3:  * 处理消费结果，并返回是否继续消费
  4:  *
  5:  * @param msgs 消息
  6:  * @param status 消费结果状态
  7:  * @param context 消费Context
  8:  * @param consumeRequest 消费请求
  9:  * @return 是否继续消费
 10:  */
 11: public boolean processConsumeResult(//
 12:     final List<MessageExt> msgs, //
 13:     final ConsumeOrderlyStatus status, //
 14:     final ConsumeOrderlyContext context, //
 15:     final ConsumeRequest consumeRequest//
 16: ) {
 17:     boolean continueConsume = true;
 18:     long commitOffset = -1L;
 19:     if (context.isAutoCommit()) {
 20:         switch (status) {
 21:             case COMMIT:
 22:             case ROLLBACK:
 23:                 log.warn("the message queue consume result is illegal, we think you want to ack these message {}", consumeRequest.getMessageQueue());
 24:             case SUCCESS:
 25:                 // 提交消息已消费成功到消息处理队列
 26:                 commitOffset = consumeRequest.getProcessQueue().commit();
 27:                 // 统计
 28:                 this.getConsumerStatsManager().incConsumeOKTPS(consumerGroup, consumeRequest.getMessageQueue().getTopic(), msgs.size());
 29:                 break;
 30:             case SUSPEND_CURRENT_QUEUE_A_MOMENT:
 31:                 // 统计
 32:                 this.getConsumerStatsManager().incConsumeFailedTPS(consumerGroup, consumeRequest.getMessageQueue().getTopic(), msgs.size());
 33:                 if (checkReconsumeTimes(msgs)) { // 计算是否暂时挂起（暂停）消费N毫秒，默认：10ms
 34:                     // 设置消息重新消费
 35:                     consumeRequest.getProcessQueue().makeMessageToCosumeAgain(msgs);
 36:                     // 提交延迟消费请求
 37:                     this.submitConsumeRequestLater(//
 38:                         consumeRequest.getProcessQueue(), //
 39:                         consumeRequest.getMessageQueue(), //
 40:                         context.getSuspendCurrentQueueTimeMillis());
 41:                     continueConsume = false;
 42:                 } else {
 43:                     commitOffset = consumeRequest.getProcessQueue().commit();
 44:                 }
 45:                 break;
 46:             default:
 47:                 break;
 48:         }
 49:     } else {
 50:         switch (status) {
 51:             case SUCCESS:
 52:                 this.getConsumerStatsManager().incConsumeOKTPS(consumerGroup, consumeRequest.getMessageQueue().getTopic(), msgs.size());
 53:                 break;
 54:             case COMMIT:
 55:                 // 提交消息已消费成功到消息处理队列
 56:                 commitOffset = consumeRequest.getProcessQueue().commit();
 57:                 break;
 58:             case ROLLBACK:
 59:                 // 设置消息重新消费
 60:                 consumeRequest.getProcessQueue().rollback();
 61:                 this.submitConsumeRequestLater(//
 62:                     consumeRequest.getProcessQueue(), //
 63:                     consumeRequest.getMessageQueue(), //
 64:                     context.getSuspendCurrentQueueTimeMillis());
 65:                 continueConsume = false;
 66:                 break;
 67:             case SUSPEND_CURRENT_QUEUE_A_MOMENT: // 计算是否暂时挂起（暂停）消费N毫秒，默认：10ms
 68:                 this.getConsumerStatsManager().incConsumeFailedTPS(consumerGroup, consumeRequest.getMessageQueue().getTopic(), msgs.size());
 69:                 if (checkReconsumeTimes(msgs)) {
 70:                     // 设置消息重新消费
 71:                     consumeRequest.getProcessQueue().makeMessageToCosumeAgain(msgs);
 72:                     // 提交延迟消费请求
 73:                     this.submitConsumeRequestLater(//
 74:                         consumeRequest.getProcessQueue(), //
 75:                         consumeRequest.getMessageQueue(), //
 76:                         context.getSuspendCurrentQueueTimeMillis());
 77:                     continueConsume = false;
 78:                 }
 79:                 break;
 80:             default:
 81:                 break;
 82:         }
 83:     }
 84: 
 85:     // 消息处理队列未dropped，提交有效消费进度
 86:     if (commitOffset >= 0 && !consumeRequest.getProcessQueue().isDropped()) {
 87:         this.defaultMQPushConsumerImpl.getOffsetStore().updateOffset(consumeRequest.getMessageQueue(), commitOffset, false);
 88:     }
 89: 
 90:     return continueConsume;
 91: }
 92: 
 93: private int getMaxReconsumeTimes() {
 94:     // default reconsume times: Integer.MAX_VALUE
 95:     if (this.defaultMQPushConsumer.getMaxReconsumeTimes() == -1) {
 96:         return Integer.MAX_VALUE;
 97:     } else {
 98:         return this.defaultMQPushConsumer.getMaxReconsumeTimes();
 99:     }
100: }
101: 
102: /**
103:  * 计算是否要暂停消费
104:  * 不暂停条件：存在消息都超过最大消费次数并且都发回broker成功
105:  *
106:  * @param msgs 消息
107:  * @return 是否要暂停
108:  */
109: private boolean checkReconsumeTimes(List<MessageExt> msgs) {
110:     boolean suspend = false;
111:     if (msgs != null && !msgs.isEmpty()) {
112:         for (MessageExt msg : msgs) {
113:             if (msg.getReconsumeTimes() >= getMaxReconsumeTimes()) {
114:                 MessageAccessor.setReconsumeTime(msg, String.valueOf(msg.getReconsumeTimes()));
115:                 if (!sendMessageBack(msg)) { // 发回失败，中断
116:                     suspend = true;
117:                     msg.setReconsumeTimes(msg.getReconsumeTimes() + 1);
118:                 }
119:             } else {
120:                 suspend = true;
121:                 msg.setReconsumeTimes(msg.getReconsumeTimes() + 1);
122:             }
123:         }
124:     }
125:     return suspend;
126: }
127: 
128: /**
129:  * 发回消息。
130:  * 消息发回broker后，对应的消息队列是死信队列。
131:  *
132:  * @param msg 消息
133:  * @return 是否发送成功
134:  */
135: public boolean sendMessageBack(final MessageExt msg) {
136:     try {
137:         // max reconsume times exceeded then send to dead letter queue.
138:         Message newMsg = new Message(MixAll.getRetryTopic(this.defaultMQPushConsumer.getConsumerGroup()), msg.getBody());
139:         String originMsgId = MessageAccessor.getOriginMessageId(msg);
140:         MessageAccessor.setOriginMessageId(newMsg, UtilAll.isBlank(originMsgId) ? msg.getMsgId() : originMsgId);
141:         newMsg.setFlag(msg.getFlag());
142:         MessageAccessor.setProperties(newMsg, msg.getProperties());
143:         MessageAccessor.putProperty(newMsg, MessageConst.PROPERTY_RETRY_TOPIC, msg.getTopic());
144:         MessageAccessor.setReconsumeTime(newMsg, String.valueOf(msg.getReconsumeTimes()));
145:         MessageAccessor.setMaxReconsumeTimes(newMsg, String.valueOf(getMaxReconsumeTimes()));
146:         newMsg.setDelayTimeLevel(3 + msg.getReconsumeTimes());
147: 
148:         this.defaultMQPushConsumer.getDefaultMQPushConsumerImpl().getmQClientFactory().getDefaultMQProducer().send(newMsg);
149:         return true;
150:     } catch (Exception e) {
151:         log.error("sendMessageBack exception, group: " + this.consumerGroup + " msg: " + msg.toString(), e);
152:     }
153: 
154:     return false;
155: }
```
第 21 至 29 行 ：消费成功。在自动提交进度( AutoCommit )的情况下，COMMIT、ROLLBACK、SUCCESS 逻辑已经统一。

第 30 至 45 行 ：消费失败。当消息重试次数超过上限（默认 ：16次）时，将消息发送到 Broker 死信队列，跳过这些消息。此时，消息队列无需挂起，继续消费后面的消息。

第 85 至 88 行 ：提交消费进度。


* 消息处理队列核心方法 *

涉及到的四个核心方法的源码：

```java
  1: // 【ProcessQueue.java】
  2: /**
  3:  * 消息映射
  4:  * key：消息队列位置
  5:  */
  6: private final TreeMap<Long, MessageExt> msgTreeMap = new TreeMap<>();    /**
  7:  * 消息映射临时存储（消费中的消息）
  8:  */
  9: private final TreeMap<Long, MessageExt> msgTreeMapTemp = new TreeMap<>();
 10: 
 11: /**
 12:  * 回滚消费中的消息
 13:  * 逻辑类似于{@link #makeMessageToCosumeAgain(List)}
 14:  */
 15: public void rollback() {
 16:     try {
 17:         this.lockTreeMap.writeLock().lockInterruptibly();
 18:         try {
 19:             this.msgTreeMap.putAll(this.msgTreeMapTemp);
 20:             this.msgTreeMapTemp.clear();
 21:         } finally {
 22:             this.lockTreeMap.writeLock().unlock();
 23:         }
 24:     } catch (InterruptedException e) {
 25:         log.error("rollback exception", e);
 26:     }
 27: }
 28: 
 29: /**
 30:  * 提交消费中的消息已消费成功，返回消费进度
 31:  *
 32:  * @return 消费进度
 33:  */
 34: public long commit() {
 35:     try {
 36:         this.lockTreeMap.writeLock().lockInterruptibly();
 37:         try {
 38:             // 消费进度
 39:             Long offset = this.msgTreeMapTemp.lastKey();
 40: 
 41:             //
 42:             msgCount.addAndGet(this.msgTreeMapTemp.size() * (-1));
 43: 
 44:             //
 45:             this.msgTreeMapTemp.clear();
 46: 
 47:             // 返回消费进度
 48:             if (offset != null) {
 49:                 return offset + 1;
 50:             }
 51:         } finally {
 52:             this.lockTreeMap.writeLock().unlock();
 53:         }
 54:     } catch (InterruptedException e) {
 55:         log.error("commit exception", e);
 56:     }
 57: 
 58:     return -1;
 59: }
 60: 
 61: /**
 62:  * 指定消息重新消费
 63:  * 逻辑类似于{@link #rollback()}
 64:  *
 65:  * @param msgs 消息
 66:  */
 67: public void makeMessageToCosumeAgain(List<MessageExt> msgs) {
 68:     try {
 69:         this.lockTreeMap.writeLock().lockInterruptibly();
 70:         try {
 71:             for (MessageExt msg : msgs) {
 72:                 this.msgTreeMapTemp.remove(msg.getQueueOffset());
 73:                 this.msgTreeMap.put(msg.getQueueOffset(), msg);
 74:             }
 75:         } finally {
 76:             this.lockTreeMap.writeLock().unlock();
 77:         }
 78:     } catch (InterruptedException e) {
 79:         log.error("makeMessageToCosumeAgain exception", e);
 80:     }
 81: }
 82: 
 83: /**
 84:  * 获得持有消息前N条
 85:  *
 86:  * @param batchSize 条数
 87:  * @return 消息
 88:  */
 89: public List<MessageExt> takeMessags(final int batchSize) {
 90:     List<MessageExt> result = new ArrayList<>(batchSize);
 91:     final long now = System.currentTimeMillis();
 92:     try {
 93:         this.lockTreeMap.writeLock().lockInterruptibly();
 94:         this.lastConsumeTimestamp = now;
 95:         try {
 96:             if (!this.msgTreeMap.isEmpty()) {
 97:                 for (int i = 0; i < batchSize; i++) {
 98:                     Map.Entry<Long, MessageExt> entry = this.msgTreeMap.pollFirstEntry();
 99:                     if (entry != null) {
100:                         result.add(entry.getValue());
101:                         msgTreeMapTemp.put(entry.getKey(), entry.getValue());
102:                     } else {
103:                         break;
104:                     }
105:                 }
106:             }
107: 
108:             if (result.isEmpty()) {
109:                 consuming = false;
110:             }
111:         } finally {
112:             this.lockTreeMap.writeLock().unlock();
113:         }
114:     } catch (InterruptedException e) {
115:         log.error("take Messages exception", e);
116:     }
117: 
118:     return result;
119: }
```

这里假设触发了重排导致queue分配给了别人也没关系，由于queue的消息永远是FIFO，最多只是已经消费的消息重复而已，queue内顺序还是能保证，(重复又是另一问题，在后面分析)