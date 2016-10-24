---
layout: post
title: Java 资源管理
---

{{ page.title }}
================

<p class="meta">01 Jun 2015 - 青岛</p>


资源包括很多，在Java中，内存是自动管理，但是还是有一些别的资源需要手动管理。比如Lock、Connection、File等。

## 1. JDBC连接管理

      Connection conn = null;
      try {
            conn = x.getConnection();
      } finally {
            if (conn != null) {
                  conn.close();
            }
      }

由于Connection.close方法是有异常的，所以通常会使用一个工具类来关闭，例如：

      public static class JdbcUtils {
            public static void close(Connection conn) {
                  if (conn == null) {
                        return;
                  }
                  try {
                        conn.close();
                  } catch(Exception error) {
                        // skip
                  }
            }
            public static void close(Statement stmt) {
                  if (stmt == null) {
                        return;
                  }
                  try {
                        stmt.close();
                  } catch(Exception error) {
                        // skip
                  }
            }
            public static void close(ResultSet rs) {
                  if (rs == null) {
                        return;
                  }
                  try {
                        rs.close();
                  } catch(Exception error) {
                        // skip
                  }
            }
      }

在Java 7之后，Connection/Statement/ResultSet都实现了java.lang.AutoCloseable接口。所以代码可以写的更简洁一些，例如：

      public static class JdbcUtils {
            public static void close(AutoCloseable x) {
                  if (x == null) {
                        return;
                  }
                  try {
                        x.close();
                  } catch(Exception error) {
                        // skip
                  }
            }
      }

但是由于我们不能仅仅为了好看，就是的代码只能够运行在Java7上，所以还是坚持原先更麻烦的分开三个Close方法。


很多连接池的实现中，Connection.close之后，相关的Statement和ResultSet也会自动关闭，但最好还是自己管理比较好。

      Connection conn = null;
      PreparedSatement pstmt = null;
      ResultSet rs = null;
      try {
            conn = x.getConnection();
            pstmt = conn.preparedStatement("select * from X where fid = ?");
            rs = pstmt.executeQuery();
      } finally {
            JdbcUtils.close(rs);
            JdbcUtils.close(pstmt);
            JdbcUtils.close(conn);
      }

一般都是先关闭ResultSet，然后是Statement，最后是Connnection。

## 2. 良好的习惯
如上所述，Connection/Socket等资源需要手动关闭的，很容易出错，我们应该如何解决这个问题呢？梁肇新提过一种技巧，我很认同，十多年坚持下来，一直觉得很好用。那就是申请的时候，先写释放资源的代码，再写业务代码。梁肇新把这个技巧称之为“结对”。

### 2.1 第一步

      InputStream in = null;
      try {
            in = new FileInputStream("....");
      } finally {
            IOUtils.close(in);
      }

### 2.2 第二步

      InputStream in = null;
      try {
            in = new FileInputStream("....");

            // 第二步补充的代码
            final int BLOCK_SIZE = 1024;
            byte[] block = new byte[BLOCK_SIZE];
            int len = in.readBytes(block);
            // ...
      } finally {
            IOUtils.close(in);
      }
