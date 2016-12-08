---
layout: post
title: guava帮我们throw Exception之throwables
---

{{ page.title }}
================

<p class="meta">16 May 2014 - 青岛</p>

guava类库中的Throwables提供了一些异常处理的静态方法，这些方法的从功能上分为两类，一类是帮你抛出异常，另外一类是帮你处理异常。

也许你会想：为什么要帮我们处理异常呢？我们自己不会抛出异常吗？

假定下面的方法是我们要调用的方法。

```
    public void doSomething() throws Throwable {
        //ignore method body
    }

    public void doSomethingElse() throws Exception {
        //ignore method body
    }
```

这两个方法的签名一个throws出了Throwable另外一个throws出了Exception，他们没有定义具体会抛出什么异常，也就是说他们什么异常都有可能抛出来，如果我们要调用这样的方法，就需要对他们的异常做一些处理了，我们需要判断什么样的异常需要抛出去，什么样的异常需要封装成RuntimeException。而这些事情就是Throwables类要帮我们做的事情。

假定我们要实现一个doIt的方法，该方法要调用doSomething方法，而doIt的定义中只允许抛出SQLException，我们可以这样做：

```
    public void doIt() throws SQLException {
        try {
            doSomething();
        } catch (Throwable throwable) {
            Throwables.propagateIfInstanceOf(throwable, SQLException.class);
            Throwables.propagateIfPossible(throwable);
        }
    }
```

请注意doIt的catch块，下面这行代码的意思是如果异常的类型是SQLException，那么抛出这个异常

```Throwables.propagateIfInstanceOf(throwable, SQLException.class);```

第二行表示如果异常是Error类型，那么抛出这个类型，否则将抛出RuntimeException，我们知道RuntimeException是不需要在throws中声明的。

```Throwables.propagateIfPossible(throwable); ```

Throwables类还为我们提供了一些方便的异常处理帮助方法:

我们可以通过Throwables.getRooCause(Throwable)获得根异常
可以使用getCausalChain方法获得异常的列表
可以通过getStackTraceAsString获得异常堆栈的字符串