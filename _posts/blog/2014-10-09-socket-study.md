---
layout: post
title: Java Socket编程
category: blog
description: Scoket编程对大家肯定不陌生。然而，本文我主要写一些socket的基础知识，及自己对socket的理解。
---
Scoket编程对大家肯定不陌生。然而，本文我主要写一些socket的基础知识，及自己对socket的理解。

####Socket是什么呢？

Socket是应用层与TCP/IP协议族通信的中间软件抽象层，它是一组接口。在设计模式中，Socket其实就是一个门面模式，它把复杂的TCP/IP协议族隐藏在Socket接口后面，对用户来说，一组简单的接口就是全部，让Socket去组织数据，以符合指定的协议。
![ssh key success](/images/blog/socket1.jpg)
对于Socket之间的通信其实很简单，首先ServerSocket将在服务端监听某个端口，当发现客户端有Socket来试图连接它时，它会accept该Socket的连接请求，同时在服务端建立一个对应的Socket与之进行通信。这样就有两个Socket了，客户端和服务端各一个。服务端往Socket的输出流里面写东西，客户端就可以通过Socket的输入流读取对应的内容。Socket与Socket之间是双向连通的，所以客户端也可以往对应的Socket输出流里面写东西，然后服务端对应的Socket的输入流就可以读出对应的内容。下面来看一些服务端与客户端通信的例子：
#####1、客户端写服务端读

**服务端代码**

	public class Server {
	 
	   public static void main(String args[]) throws IOException {
	      //为了简单起见，所有的异常信息都往外抛
	      int port = 8899;
	      //定义一个ServerSocket监听在端口8899上
	      ServerSocket server = new ServerSocket(port);
	      //server尝试接收其他Socket的连接请求，server的accept方法是阻塞式的
	      Socket socket = server.accept();
	      //跟客户端建立好连接之后，我们就可以获取socket的InputStream，并从中读取客户端发过来的信息了。
	      Reader reader = new InputStreamReader(socket.getInputStream());
	      char chars[] = new char[64];
	      int len;
	      StringBuilder sb = new StringBuilder();
	      while ((len=reader.read(chars)) != -1) {
	         sb.append(new String(chars, 0, len));
	      }
	      System.out.println("from client: " + sb);
	      reader.close();
	      socket.close();
	      server.close();
	   }
	   
	}

服务端从Socket的InputStream中读取数据的操作也是阻塞式的，如果从输入流中没有读取到数据程序会一直在那里不动，直到客户端往Socket的输出流中写入了数据，或关闭了Socket的输出流。当然，对于客户端的Socket也是同样如此。在操作完以后，整个程序结束前记得关闭对应的资源，即关闭对应的IO流和Socket。

**客户端代码**

	public class Client {
	 
	   public static void main(String args[]) throws Exception {
	      //为了简单起见，所有的异常都直接往外抛
	      String host = "127.0.0.1";  //要连接的服务端IP地址
	      int port = 8899;   //要连接的服务端对应的监听端口
	      //与服务端建立连接
	      Socket client = new Socket(host, port);
	      //建立连接后就可以往服务端写数据了
	      Writer writer = new OutputStreamWriter(client.getOutputStream());
	      writer.write("Hello Server.");
	      writer.flush();//写完后要记得flush
	      writer.close();
	      client.close();
	   }
	   
	}

对于客户端往Socket的输出流里面写数据传递给服务端要注意一点，如果写操作之后程序不是对应着输出流的关闭，而是进行其他阻塞式的操作（比如从输入流里面读数据），记住要flush一下，只有这样服务端才能收到客户端发送的数据，否则可能会引起两边无限的互相等待。在稍后讲到客户端和服务端同时读和写的时候会说到这个问题。
#### 2、客户端和服务端同时读和写
前面已经说了Socket之间是双向通信的，它既可以接收数据，同时也可以发送数据。

**服务端代码**

	public class Server {
	 
	   public static void main(String args[]) throws IOException {
	      //为了简单起见，所有的异常信息都往外抛
	      int port = 8899;
	      //定义一个ServerSocket监听在端口8899上
	      ServerSocket server = new ServerSocket(port);
	      //server尝试接收其他Socket的连接请求，server的accept方法是阻塞式的
	      Socket socket = server.accept();
	      //跟客户端建立好连接之后，我们就可以获取socket的InputStream，并从中读取客户端发过来的信息了。
	      Reader reader = new InputStreamReader(socket.getInputStream());
	      char chars[] = new char[64];
	      int len;
	      StringBuilder sb = new StringBuilder();
	      while ((len=reader.read(chars)) != -1) {
	         sb.append(new String(chars, 0, len));
	      }
	      System.out.println("from client: " + sb);
	      //读完后写一句
	      Writer writer = new OutputStreamWriter(socket.getOutputStream());
	      writer.write("Hello Client.");
	      writer.flush();
	      writer.close();
	      reader.close();
	      socket.close();
	      server.close();
	   }
	   
	}

在上述代码中首先我们从输入流中读取客户端发送过来的数据，接下来我们再往输出流里面写入数据给客户端，接下来关闭对应的资源文件。而实际上上述代码可能并不会按照我们预先设想的方式运行，因为从输入流中读取数据是一个阻塞式操作，在上述的while循环中当读到数据的时候就会执行循环体，否则就会阻塞，这样后面的写操作就永远都执行不了了。除非客户端对应的Socket关闭了阻塞才会停止，while循环也会跳出。针对这种可能永远无法执行下去的情况的解决方法是while循环需要在里面有条件的跳出来，纵观上述代码，在不断变化的也只有取到的长度len和读到的数据了，len已经是不能用的了，唯一能用的就是读到的数据了。针对这种情况，通常我们都会约定一个结束标记，当客户端发送过来的数据包含某个结束标记时就说明当前的数据已经发送完毕了，这个时候我们就可以进行循环的跳出了。那么改进后的代码会是这个样子：

	public class Server {
	 
	   public static void main(String args[]) throws IOException {
	      //为了简单起见，所有的异常信息都往外抛
	      int port = 8899;
	      //定义一个ServerSocket监听在端口8899上
	      ServerSocket server = new ServerSocket(port);
	      //server尝试接收其他Socket的连接请求，server的accept方法是阻塞式的
	      Socket socket = server.accept();
	      //跟客户端建立好连接之后，我们就可以获取socket的InputStream，并从中读取客户端发过来的信息了。
	      Reader reader = new InputStreamReader(socket.getInputStream());
	      char chars[] = new char[64];
	      int len;
	      StringBuilder sb = new StringBuilder();
	      String temp;
	      int index;
	      while ((len=reader.read(chars)) != -1) {
	         temp = new String(chars, 0, len);
	         if ((index = temp.indexOf("eof")) != -1) {//遇到eof时就结束接收
	            sb.append(temp.substring(0, index));
	            break;
	         }
	         sb.append(temp);
	      }
	      System.out.println("from client: " + sb);
	      //读完后写一句
	      Writer writer = new OutputStreamWriter(socket.getOutputStream());
	      writer.write("Hello Client.");
	      writer.flush();
	      writer.close();
	      reader.close();
	      socket.close();
	      server.close();
	   }
	   
	}

在上述代码中，当服务端读取到客户端发送的结束标记，即“eof”时就会结束数据的接收，终止循环，这样后续的代码又可以继续进行了。

**客户端代码**

	public class Client {
	 
	   public static void main(String args[]) throws Exception {
	      //为了简单起见，所有的异常都直接往外抛
	     String host = "127.0.0.1";  //要连接的服务端IP地址
	     int port = 8899;   //要连接的服务端对应的监听端口
	     //与服务端建立连接
	     Socket client = new Socket(host, port);
	      //建立连接后就可以往服务端写数据了
	     Writer writer = new OutputStreamWriter(client.getOutputStream());
	      writer.write("Hello Server.");
	      writer.flush();
	      //写完以后进行读操作
	     Reader reader = new InputStreamReader(client.getInputStream());
	      char chars[] = new char[64];
	      int len;
	      StringBuffer sb = new StringBuffer();
	      while ((len=reader.read(chars)) != -1) {
	         sb.append(new String(chars, 0, len));
	      }
	      System.out.println("from server: " + sb);
	      writer.close();
	      reader.close();
	      client.close();
	   }
	   
	}

在上述代码中我们先是给服务端发送了一段数据，之后读取服务端返回来的数据，跟之前的服务端一样在读的过程中有可能导致程序一直挂在那里，永远跳不出while循环。这段代码配合服务端的第一段代码就正好让我们分析服务端永远在那里接收数据，永远跳不出while循环，也就没有之后的服务端返回数据给客户端，客户端也就不可能接收到服务端返回的数据。解决方法如服务端第二段代码所示，在客户端发送数据完毕后，往输出流里面写入结束标记告诉服务端数据已经发送完毕了，同样服务端返回数据完毕后也发一个标记告诉客户端。那么修改后的客户端代码就应该是这个样子：

	public class Client {
	 
	   public static void main(String args[]) throws Exception {
	      //为了简单起见，所有的异常都直接往外抛
	     String host = "127.0.0.1";  //要连接的服务端IP地址
	     int port = 8899;   //要连接的服务端对应的监听端口
	     //与服务端建立连接
	     Socket client = new Socket(host, port);
	      //建立连接后就可以往服务端写数据了
	     Writer writer = new OutputStreamWriter(client.getOutputStream());
	      writer.write("Hello Server.");
	      writer.write("eof");
	      writer.flush();
	      //写完以后进行读操作
	     Reader reader = new InputStreamReader(client.getInputStream());
	      char chars[] = new char[64];
	      int len;
	      StringBuffer sb = new StringBuffer();
	      String temp;
	      int index;
	      while ((len=reader.read(chars)) != -1) {
	         temp = new String(chars, 0, len);
	         if ((index = temp.indexOf("eof")) != -1) {
	            sb.append(temp.substring(0, index));
	            break;
	         }
	         sb.append(new String(chars, 0, len));
	      }
	      System.out.println("from server: " + sb);
	      writer.close();
	      reader.close();
	      client.close();
	   }
	   
	}
 
我们日常使用的比较多的都是这种客户端发送数据给服务端，服务端接收数据后再返回相应的结果给客户端这种形式。只是客户端和服务端之间不再是这种一对一的关系，而是下面要讲到的多个客户端对应同一个服务端的情况。

####3、多个客户端连接同一个服务端

像前面讲的两个例子都是服务端接收一个客户端的请求之后就结束了，不能再接收其他客户端的请求了，这往往是不能满足我们的要求的。通常我们会这样做：

	public class Server {
	 
	   public static void main(String args[]) throws IOException {
	      //为了简单起见，所有的异常信息都往外抛
	     int port = 8899;
	      //定义一个ServerSocket监听在端口8899上
	     ServerSocket server = new ServerSocket(port);
	      while (true) {
	         //server尝试接收其他Socket的连接请求，server的accept方法是阻塞式的
	       Socket socket = server.accept();
	         //跟客户端建立好连接之后，我们就可以获取socket的InputStream，并从中读取客户端发过来的信息了。
	       Reader reader = new InputStreamReader(socket.getInputStream());
	         char chars[] = new char[64];
	         int len;
	         StringBuilder sb = new StringBuilder();
	         String temp;
	         int index;
	         while ((len=reader.read(chars)) != -1) {
	            temp = new String(chars, 0, len);
	            if ((index = temp.indexOf("eof")) != -1) {//遇到eof时就结束接收
	                sb.append(temp.substring(0, index));
	                break;
	            }
	            sb.append(temp);
	         }
	         System.out.println("from client: " + sb);
	         //读完后写一句
	       Writer writer = new OutputStreamWriter(socket.getOutputStream());
	         writer.write("Hello Client.");
	         writer.flush();
	         writer.close();
	         reader.close();
	         socket.close();
	      }
	   }
	   
	}

在上面代码中我们用了一个死循环，在循环体里面ServerSocket调用其accept方法试图接收来自客户端的连接请求。当没有接收到请求的时候，程序会在这里阻塞直到接收到来自客户端的连接请求，之后会跟当前建立好连接的客户端进行通信，完了后会接着执行循环体再次尝试接收新的连接请求。这样我们的ServerSocket就能接收来自所有客户端的连接请求了，并且与它们进行通信了。这就实现了一个简单的一个服务端与多个客户端进行通信的模式。


上述例子中虽然实现了一个服务端跟多个客户端进行通信，但是还存在一个问题。在上述例子中，我们的服务端处理客户端的连接请求是同步进行的，每次接收到来自客户端的连接请求后，都要先跟当前的客户端通信完之后才能再处理下一个连接请求。这在并发比较多的情况下会严重影响程序的性能，为此，我们可以把它改为如下这种异步处理与客户端通信的方式：

	public class Server {
	   
	   public static void main(String args[]) throws IOException {
	      //为了简单起见，所有的异常信息都往外抛
	     int port = 8899;
	      //定义一个ServerSocket监听在端口8899上
	     ServerSocket server = new ServerSocket(port);
	      while (true) {
	         //server尝试接收其他Socket的连接请求，server的accept方法是阻塞式的
	         Socket socket = server.accept();
	         //每接收到一个Socket就建立一个新的线程来处理它
	         new Thread(new Task(socket)).start();
	      }
	   }
	   
	   /**
	    * 用来处理Socket请求的
	   */
	   static class Task implements Runnable {
	 
	      private Socket socket;
	      
	      public Task(Socket socket) {
	         this.socket = socket;
	      }
	      
	      public void run() {

	         try {

	            handleSocket();
	         } catch (Exception e) {
	            e.printStackTrace();
	         }
	      }
	      
	      /**
	       * 跟客户端Socket进行通信
	       * @throws Exception
	       */
	      private void handleSocket() throws Exception {
	         Reader reader = new InputStreamReader(socket.getInputStream());
	         char chars[] = new char[64];
	         int len;
	         StringBuilder sb = new StringBuilder();
	         String temp;
	         int index;
	         while ((len=reader.read(chars)) != -1) {
	            temp = new String(chars, 0, len);
	            if ((index = temp.indexOf("eof")) != -1) {//遇到eof时就结束接收
	             sb.append(temp.substring(0, index));
	                break;
	            }
	            sb.append(temp);
	         }
	         System.out.println("from client: " + sb);
	         //读完后写一句
	       Writer writer = new OutputStreamWriter(socket.getOutputStream());
	         writer.write("Hello Client.");
	         writer.flush();
	         writer.close();
	         reader.close();
	         socket.close();
	      }
	      
	   }
	   
	}

在上面代码中，每次ServerSocket接收到一个新的Socket连接请求后都会新起一个线程来跟当前Socket进行通信，这样就达到了异步处理与客户端Socket进行通信的情况。


在从Socket的InputStream中接收数据时，像上面那样一点点的读就太复杂了，有时候我们就会换成使用BufferedReader来一次读一行，如：

	public class Server {
	 
	   public static void main(String args[]) throws IOException {
	      //为了简单起见，所有的异常信息都往外抛
	     int port = 8899;
	      //定义一个ServerSocket监听在端口8899上
	     ServerSocket server = new ServerSocket(port);
	      while (true) {
	         //server尝试接收其他Socket的连接请求，server的accept方法是阻塞式的
	         Socket socket = server.accept();
	         //每接收到一个Socket就建立一个新的线程来处理它
	         new Thread(new Task(socket)).start();
	      }
	   }
	   
	   /**
	    * 用来处理Socket请求的
	   */
	   static class Task implements Runnable {
	 
	      private Socket socket;
	      
	      public Task(Socket socket) {
	         this.socket = socket;
	      }
	      
	      public void run() {
	         try {
	            handleSocket();
	         } catch (Exception e) {
	            e.printStackTrace();
	         }
	      }
	      
	      /**
	       * 跟客户端Socket进行通信
	      * @throws Exception
	       */
	      private void handleSocket() throws Exception {
	         BufferedReader br = new BufferedReader(new InputStreamReader(socket.getInputStream()));
	         StringBuilder sb = new StringBuilder();
	         String temp;
	         int index;
	         while ((temp=br.readLine()) != null) {
	            System.out.println(temp);
	            if ((index = temp.indexOf("eof")) != -1) {//遇到eof时就结束接收
	             sb.append(temp.substring(0, index));
	                break;
	            }
	            sb.append(temp);
	         }
	         System.out.println("from client: " + sb);
	         //读完后写一句
	       Writer writer = new OutputStreamWriter(socket.getOutputStream());
	         writer.write("Hello Client.");
	         writer.write("eof\n");
	         writer.flush();
	         writer.close();
	         br.close();
	         socket.close();
	      }
	   }
	}

这个时候需要注意的是，BufferedReader的readLine方法是一次读一行的，这个方法是阻塞的，直到它读到了一行数据为止程序才会继续往下执行，那么readLine什么时候才会读到一行呢？直到程序遇到了换行符或者是对应流的结束符readLine方法才会认为读到了一行，才会结束其阻塞，让程序继续往下执行。所以我们在使用BufferedReader的readLine读取数据的时候一定要记得在对应的输出流里面一定要写入换行符（流结束之后会自动标记为结束，readLine可以识别），写入换行符之后一定记得如果输出流不是马上关闭的情况下记得flush一下，这样数据才会真正的从缓冲区里面写入。对应上面的代码我们的客户端程序应该这样写：

	public class Client {

	   public static void main(String args[]) throws Exception {
	      //为了简单起见，所有的异常都直接往外抛
	     String host = "127.0.0.1";  //要连接的服务端IP地址
	     int port = 8899;   //要连接的服务端对应的监听端口
	     //与服务端建立连接
	     Socket client = new Socket(host, port);
	      //建立连接后就可以往服务端写数据了
	     Writer writer = new OutputStreamWriter(client.getOutputStream());
	      writer.write("Hello Server.");
	      writer.write("eof\n");
	      writer.flush();
	      //写完以后进行读操作
	     BufferedReader br = new BufferedReader(new InputStreamReader(client.getInputStream()));
	      StringBuffer sb = new StringBuffer();
	      String temp;
	      int index;
	      while ((temp=br.readLine()) != null) {
	         if ((index = temp.indexOf("eof")) != -1) {
	            sb.append(temp.substring(0, index));
	            break;
	         }
	         sb.append(temp);
	      }
	      System.out.println("from server: " + sb);
	      writer.close();
	      br.close();
	      client.close();
	   }
	}

####4、设置超时时间

 假设有这样一种需求，我们的客户端需要通过Socket从服务端获取到XX信息，然后给用户展示在页面上。我们知道Socket在读数据的时候是阻塞式的，如果没有读到数据程序会一直阻塞在那里。在同步请求的时候我们肯定是不能允许这样的情况发生的，这就需要我们在请求达到一定的时间后控制阻塞的中断，让程序得以继续运行。Socket为我们提供了一个setSoTimeout()方法来设置接收数据的超时时间，单位是毫秒。当设置的超时时间大于0，并且超过了这一时间Socket还没有接收到返回的数据的话，Socket就会抛出一个SocketTimeoutException。
 

 假设我们需要控制我们的客户端在开始读取数据10秒后还没有读到数据就中断阻塞的话我们可以这样做：

	 public class Client {
	 
	   public static void main(String args[]) throws Exception {
	      //为了简单起见，所有的异常都直接往外抛
	     String host = "127.0.0.1";  //要连接的服务端IP地址
	     int port = 8899;   //要连接的服务端对应的监听端口
	     //与服务端建立连接
	     Socket client = new Socket(host, port);
	      //建立连接后就可以往服务端写数据了
	     Writer writer = new OutputStreamWriter(client.getOutputStream());
	      writer.write("Hello Server.");
	      writer.write("eof\n");
	      writer.flush();
	      //写完以后进行读操作
	     BufferedReader br = new BufferedReader(new InputStreamReader(client.getInputStream()));
	      //设置超时间为10秒
	     client.setSoTimeout(10*1000);
	      StringBuffer sb = new StringBuffer();
	      String temp;
	      int index;
	      try {
	         while ((temp=br.readLine()) != null) {
	            if ((index = temp.indexOf("eof")) != -1) {
	                sb.append(temp.substring(0, index));
	                break;
	            }
	            sb.append(temp);
	         }
	      } catch (SocketTimeoutException e) {
	         System.out.println("数据读取超时。");
	      }
	      System.out.println("from server: " + sb);
	      writer.close();
	      br.close();
	      client.close();
	   }
	}

####5、接收数据乱码

对于这种服务端或客户端接收中文乱码的情况通常是因为数据发送时使用的编码跟接收时候使用的编码不一致。比如有下面这样一段服务端代码：


	public class Server {
	 
	   public static void main(String args[]) throws IOException {
	      //为了简单起见，所有的异常信息都往外抛
	      int port = 8899;
	      //定义一个ServerSocket监听在端口8899上
	      ServerSocket server = new ServerSocket(port);
	      while (true) {
	         //server尝试接收其他Socket的连接请求，server的accept方法是阻塞式的
	         Socket socket = server.accept();
	         //每接收到一个Socket就建立一个新的线程来处理它
	         new Thread(new Task(socket)).start();
	      }
	   }
	   
	   /**
	    * 用来处理Socket请求的
	    */
	   static class Task implements Runnable {
	 
	      private Socket socket;
	      
	      public Task(Socket socket) {
	         this.socket = socket;
	      }
	      
	      public void run() {
	         try {
	            handleSocket();
	         } catch (Exception e) {
	            e.printStackTrace();
	         }
	      }
	      
	      /**
	       * 跟客户端Socket进行通信
	      * @throws Exception
	       */
	      private void handleSocket() throws Exception {
	         BufferedReader br = new BufferedReader(new InputStreamReader(socket.getInputStream(), "GBK"));
	         StringBuilder sb = new StringBuilder();
	         String temp;
	         int index;
	         while ((temp=br.readLine()) != null) {
	            System.out.println(temp);
	            if ((index = temp.indexOf("eof")) != -1) {//遇到eof时就结束接收
	             sb.append(temp.substring(0, index));
	                break;
	            }
	            sb.append(temp);
	         }
	         System.out.println("客户端: " + sb);
	         //读完后写一句
	       Writer writer = new OutputStreamWriter(socket.getOutputStream(), "UTF-8");
	         writer.write("你好，客户端。");
	         writer.write("eof\n");
	         writer.flush();
	         writer.close();
	         br.close();
	         socket.close();
	      }
	   }
	}

这里用来测试我就弄的混乱了一点。在上面服务端代码中我们在定义输入流的时候明确定义了使用GBK编码来读取数据，而在定义输出流的时候明确指定了将使用UTF-8编码来发送数据。如果客户端上送数据的时候不以GBK编码来发送的话服务端接收的数据就很有可能会乱码；同样如果客户端接收数据的时候不以服务端发送数据的编码，即UTF-8编码来接收数据的话也极有可能会出现数据乱码的情况。所以，对于上述服务端代码，为使我们的程序能够读取对方发送过来的数据，而不出现乱码情况，我们的客户端应该是这样的：

	public class Client {
	 
	   public static void main(String args[]) throws Exception {
	      //为了简单起见，所有的异常都直接往外抛
	     String host = "127.0.0.1";  //要连接的服务端IP地址
	     int port = 8899;   //要连接的服务端对应的监听端口
	     //与服务端建立连接
	     Socket client = new Socket(host, port);
	      //建立连接后就可以往服务端写数据了
	     Writer writer = new OutputStreamWriter(client.getOutputStream(), "GBK");
	      writer.write("你好，服务端。");
	      writer.write("eof\n");
	      writer.flush();
	      //写完以后进行读操作
	     BufferedReader br = new BufferedReader(new InputStreamReader(client.getInputStream(), "UTF-8"));
	      //设置超时间为10秒
	     client.setSoTimeout(10*1000);
	      StringBuffer sb = new StringBuffer();
	      String temp;
	      int index;
	      try {
	         while ((temp=br.readLine()) != null) {
	            if ((index = temp.indexOf("eof")) != -1) {
	                sb.append(temp.substring(0, index));
	                break;
	            }
	            sb.append(temp);
	         }
	      } catch (SocketTimeoutException e) {
	         System.out.println("数据读取超时。");
	      }
	      System.out.println("服务端: " + sb);
	      writer.close();
	      br.close();
	      client.close();
	   }
	}
	
[1]:    {{ page.url}}  ({{ page.title }})