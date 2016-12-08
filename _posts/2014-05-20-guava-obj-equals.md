---
layout: post
title: 看看guava是如何写equals方法
---

{{ page.title }}
================

<p class="meta">20 May 2014 - 青岛</p>

我们在开发中经常会需要比较两个对象是否相等，这时候我们需要考虑比较的两个对象是否为null，然后再调用equals方法来比较是否相等，google guava库的com.google.common.base.Objects类提供了一个静态方法equals可以避免我们自己做是否为空的判断，示例如下：

```
        Object a = null;
        Object b = new Object();
        boolean aEqualsB = Objects.equal(a, b);
```

Objects.equals的实现是很完美的，其实现代码如下：

```
  public static boolean equal(@Nullable Object a, @Nullable Object b) {
    return a == b || (a != null && a.equals(b));
  }
```

首先判断a b是否是同一个对象，如果是同一对象，那么直接返回相等，如果不是同一对象再判断a不为null并且a.equals(b). 这样做既考虑了性能也考虑了null空指针的问题。

另外Objects类中还为我们提供了方便的重写toString()方法的机制，我们通过例子来了解一下吧：

```
package cn.outofmemory.guava.base;

import com.google.common.base.Objects;

public class ObjectsDemo {
    public static void main(String [] args) {
      Student jim = new Student();
        jim.setId(1);
        jim.setName("Jim");
        jim.setAge(13);
        System.out.println(jim.toString());
    }

    public static class Student {
        private int id;
        private String name;
        private int age;

        public int getId() {
            return id;
        }
        public void setId(int id) {
            this.id = id;
        }

        public String getName() {
            return name;
        }
        public void setName(String name) {
            this.name = name;
        }

        public int getAge() {
            return age;
        }
        public void setAge(int age) {
            this.age = age;
        }

        public String toString() {
            return Objects.toStringHelper(this.getClass())
                    .add("id", id)
                    .add("name", name)
                    .add("age", age)
                    .omitNullValues().toString();
        }
    }
}
```

 我们定义了一个Student类，该类有三个属性，分别为id，name，age，我们重写了toString()方法，在这个方法中我们使用了Objects.toStringHelper方法，首先指定toString的类，然后依次add属性名称和属性值，可以使用omitNullValues()方法来指定忽略空值，最后调用其toString()方法，就可以得到一个格式很好的toString实现了。

上面代码输出的结果是：

```Student{id=1, name=Jim, age=13}```

这种方式写起来很简单，可读性也很好，所以用Guava吧。