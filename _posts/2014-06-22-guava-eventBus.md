---
layout: post
title: guava EventBus示例
---

{{ page.title }}
================

<p class="meta">22 Jun 2014 - 北京</p>

EventBus是Guava的事件处理机制，是设计模式中的观察者模式（生产/消费者编程模型）的优雅实现。对于事件监听和发布订阅模式，EventBus是一个非常优雅和简单解决方案，我们不用创建复杂的类和接口层次结构。

Observer模式是比较常用的设计模式之一，虽然有时候在具体代码里，它不一定叫这个名字，比如改头换面叫个Listener，但模式就是这个模式。手工实现一个Observer也不是多复杂的一件事，只是因为这个设计模式实在太常用了，Java就把它放到了JDK里面：Observable和Observer，从JDK 1.0里，它们就一直在那里。从某种程度上说，它简化了Observer模式的开发，至少我们不用再手工维护自己的Observer列表了。不过，如前所述，JDK里的Observer从1.0就在那里了，直到Java 7，它都没有什么改变，就连通知的参数还是Object类型。要知道，Java 5就已经泛型了。Java 5是一次大规模的语法调整，许多程序库从那开始重新设计了API，使其更简洁易用。当然，那些不做应对的程序库，多半也就过时了。这也就是这里要讨论知识更新的原因所在。今天，对于普通的应用，如果要使用Observer模式该如何做呢？答案是Guava的EventBus。

EventBus基本用法：

使用Guava之后, 如果要订阅消息, 就不用再继承指定的接口, 只需要在指定的方法上加上@Subscribe注解即可。代码如下：

```
import com.google.common.eventbus.EventBus;
import com.google.common.eventbus.Subscribe;

/**
 * Created by outofmemory.cn on 2016/10/9.
 */
public class HiEventBus {

    public static class EventBusListener {
        @Subscribe
        public void onEvent(CustomerChangedEvent event) {
            System.out.println(event.getMessage());
        }

        @Subscribe
        public void onEvent2(CustomerChangedEvent event) {
            System.out.println(event.getMessage());
        }

    }

    public static class CustomerChangedEvent {

        public String getMessage() {
            return "change message";
        }
    }

    public static void main(String[] args) {
        EventBus eventBus = new EventBus();
        eventBus.register(new EventBusListener());
        eventBus.post(new CustomerChangedEvent());
    }
}
```