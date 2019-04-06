#随手写的博客 当做是记录吧

1.ubuntu免密码登录远程服务器
日常工作中，经常需要登录远程服务器进行工作，而每次敲那一长串命令和密码，非常耗时，虽然密码可以写在脚本里直接执行，但是密码还是每次得敲，而且公司的密码，一般都设置得很复杂，一两次还好，每次都敲，也烦也耗时；使用密码登录还有一个最大的弊端就是不安全，你每次登录，密码就会在网络中游走一次，这是非常不安全的，很多公司规定不能使用这种方式登录，所以这里跟大家分享一下使用密钥登录
机器1：个人电脑 Ubuntu14.04 LTS系统 
机器2： 阿里云服务器 ubuntu16.04 LTS系统 
步骤1：在我的机器上生成ssh密钥对 命令：ssh-keygen -t rsa 在这过程中会提示输入密码， 密码可以不输入 直接enter 接着会提示密钥对的保存路径 也可以不输入 使用默认的路径 ～/.ssh/目录（“～”是当前用户的home路径） 进入～/.ssh/， ls -l 可以看到刚才生成的密钥对，如下所示 id_rsa id_rsa.pub known_hosts 其中 id_rsa是密钥，一定要保存好，切勿泄露，id_rsa.pub是公钥，需要放到远程机器上的 
步骤2：上传公钥到远程服务器上 使用命令 scp ～/.ssh/id_rsa.pub 用户名@服务器ip:～/.ssh/authorized_keys scp是linux下跨机器复制命令，详细用法请自行google， 这个命令需要注意的是，ssh需要使用默认的端口 如果不是默认的端口，则不能使用该命令进行远程拷贝 ，上面的命令是把 本机的id_rsa.pub里面的内容赋值到远程服务器的~/.ssh/authorized_keys文件里，注意 如果authorized_keys文件本来有内容 ， 则会被覆盖 所以，如果怕被覆盖，可以使用其他名字上传 如：scp ～/.ssh/id_rsa.pub 用户名@服务器ip:～/.ssh/abcde 这样，我们的公钥就会保存在acbde的文件里，然后 使用密码登录上远程服务器，进入~/.ssh/文件夹，使用命令
cat abcde>>authorized_keys 注意，这里一定要使用>> 不能使用单个> 单个也会覆盖，两个表示追加。 到这里基本完成了，尝试使用命令登录ssh xxx@xxx.xxx.xxx.xxx -p xx 如果没有提示输入密码，那么就算是操作成功了

2.远程登录tomcat manager app
最近在阿里云服务器上搭建了tomcat，由于是第一次搭建远程tomcat，中途出现了一小插曲，再此记录一下。其实大部分步骤和本机搭建没什么两样，毕竟tomcat是一个非常成熟的夸平台web容器。首先upload tomcat压缩包到服务器，解压到指定文件夹，为bin下面的几个脚本设置运行权限，再到阿里云官网控制台开放服务器的8080端口，启动tomcat,在本机输入 http://ip:8080， 熟悉的界面如期而至；我以为就这么轻松搞定时，问题来了，当我点击manager app进入管理应用界面时，出现了403，马上意识到没有配用户名密码，vi打开{tomcatpath}/conf/tomcat-user.xml 添加<role rolename="manager-gui"/> <user username="xxx" password="xxx" roles="manager-gui" />,重启tomcat；再次访问，what the hell， 还是403禁止访问，一开始以为打开方式不对，之后强刷换 浏览器 隐身模式 从本机拷贝一份能正常操作的tomcat-user.xml覆盖服务器的 重启tomcat 重启服务器 所有的所以都试过，还是不行，当时非常纳闷，因为所有的办法都试过了，还不行，由于一开始以为问题的根源都是在tomcat-user.xml文件的配置没有搞好，所有baidu google一直往这方面搜索，都没找到能解决的答案。当我绝望的看着那403页面时，咦，好像发现了 什么，在这个页面有一行 By default the Manager is only accessible from a browser running on the same machine as Tomcat. If you wish to modify this restriction, you'll need to edit the Manager's context.xml file.大概意思是说manager默认只允许本机器访问，如果需要改变这个限制，则需要编辑context.xml文件，那么问题又来了，路径呢？？？没办法 ，搜索吧{tomcatpath} 下 find . -name context.xml 得到的结果是在{tomcatpath}/webapps/host-manager/META-INF/context.xml   {tomcatpath}/webapps/manager/META-INF/context.xml 但是META-INF一般都是放外部jar的信息用的呀，确定是这个context.xml吗？不管了，试试再说吧，试？怎么试？没有模板，怎么个配法。不纠结了，既然问题的源头都找到了，何不google一下呢，有了定向的问题，还快就搜到了答案，在{tomcatpath}/conf/Catalina/localhost下面的manager.xml(如果没有，则新建)添加
<Context privileged="true" antiResourceLocking="false"   
         docBase="${catalina.home}/webapps/manager">
             <Valve className="org.apache.catalina.valves.RemoteAddrValve" allow="^.*$" />
</Context>

好 ,执行.startup.sh 再来，当我准备松口气时，发现还是too young too simple , 这次可恶的403页面没有出现了，但是密码正确硬是说我不正确，当时我就想拿起我这三块钱的拖鞋砸烂这三百块的电脑。绝望之际，我也不知为什么，就是很突然的想查看一下tomcat的进程，ps -ef | grep tomcat ,结果如下图

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/ps_tomcat.png)

 不看不知道，一看吓一跳，怎么会有两个进程的，难不成刚才直接运行了.startup.sh 而没有先执行shutdown.sh，就起来了两个了？但是为什么不会出现端口冲突呢，又是一个纳闷现象，管不了那么多了，先kill了两个tomcat进程在说，再次启动，噗，thanks godness!!!

3.将ssh的公钥复制到远程机器时，尽然不能成功，还是要输密码，原来是我在vi打开文件后，没有进入insert模式，直接粘贴了，也奇怪，它竟然能复制成功，但是就是不可行，后来删除内容，再进入编辑模式后粘贴，保存， 成功了

ubuntu安装nginx服务器：
1.登录阿里云服务器
2.下载nginx安装文件：
 wget http://nginx.org/download/nginx-1.15.1.tar.gz
 解压：
tar -zxvf nginx-1.15.1.tar.gz
安装依赖

sudo apt-get update
sudo apt-get install openssl
sudo apt-get install libssl-dev
sudo apt-get install libpcre3-de
进入解压后的文件夹：cd nginx-1.15.1
执行：./configure --with-http_ssl_module (如果不带上--with-http_ssl_module则不支持https)
编译：make
安装: make install (如果有错误 有可能是权限问题 试试使用sudo make install执行)
安装后的文件默认放在/usr/local/nginx/下面
3.测试：
sudo ./nginx -v 显示版本
sudo ./nginx -t 测试
sudo ./nginx -s reload 重新载入配置文件(记住，修改了配置文件需要重新载入，不能直接reopen)
sudo ./nginx -s stop 停止
sudo ./ngxin -s reopen 重启
上面的命令中 执行reload stop reopen可能会报错：nginx: [error] invalid PID number "" in "/usr/local/nginx/logs/nginx.pid"，这时可以向nginx指定配置文件：$ sudo ./nginx -c /usr/local/etc/nginx/nginx.conf
而执行上面的命令又有可能会出错（linxu经常是这样，一个错误未解决，另一个错误又出现了，心累）
nginx: [emerg] listen() to 0.0.0.0:80, backlog 511 failed (98: Address already in use)
端口被占用了（不出意外，应该是apache2占用了80端口，找到它并kill了它就ok了）
netstat -atunp 找到80端口的进程 执行
kill -9 pid杀死进程
再执行上面的 sudo ./nginx -c /usr/local/etc/nginx/nginx.conf命令
这时试试sudo ./nginx-s reload看看是不是正常启动了
打开浏览器，在地址栏输入ip地址 如果看到Welcome to nginx!表示已经成功搭建好nginx服务器了，如果不能访问，则有可能是服务器的端口没有打开，这时需要到服务器管理后台添加安全组策略了，至于如何添加，这里就不多加描述了，可以自行百度。
搭建https:
首先需要申请ssl证书，可以到阿里云申请免费的ssl证书
进入阿里云控制台

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/https/product.png)

点击购买证书
 
 ![image](https://github.com/Mitnick5194/myBlog/blob/master/images/https/buy.png)

 没有看到免费的，其实免费的入口有点隐蔽，不知是不是阿里云故意这样做的，需要点击选择品牌：Symantec、证书类型：增强型OV SSl，这时候，免费型DV SSL入口才会出现

  ![image](https://github.com/Mitnick5194/myBlog/blob/master/images/https/free.png)

根据提示购买就ok了，遇到支付，直接点击支付，因为是免费的，所以点击完后会跳转到成功页面
进入ssl证书控制台，会看到你刚才申请的证书，此时只是购买了，还没有完善信息，按照提示填写相关信息，提交审核，审核时间一般比较快，当审核通过，状态变成
已签发状态就可以进行下载了，下载类型有很多，我们这里用到的是nginx，所以选择nginx

  ![image](https://github.com/Mitnick5194/myBlog/blob/master/images/https/dl.png)

  下载的压缩包解压出来，里面有一个.pem和.key文件，把这两个文件上传到服务器，路径可以自定义，我是放在/usr/local/nginx/conf/cert/目录下（usrlocal/nginx是我的nginx安装
  目录）

  编辑nginx.conf文件

  ![image](https://github.com/Mitnick5194/myBlog/blob/master/images/https/conf.png)

到此,nginx已经成功配置了ssl，重新载入配置文件并重启服务 ./nginx -s reload ./nginx -s reopen：
sudo ./nginx -s reload
打开浏览器，使用https访问，如果能成功访问到nginx，则成功搭建https

eclipse搭建maven和tomcat项目
我们知道，在myeclipse上搭建一个web项目非常简单，因为myeclipse已经帮我们做好了大部分工作了，但是，如果在eclipse上搭建web项目，过程还是有点繁琐的，既然繁琐，为什么不直接使用myeclipse呢，当然
是有原因的，myeclipse固然是好，但是它的缺点也很明显，首先，我们要知道，myeclipse是收费的，而eclipse是免费的，这个也是myeclipse最大的缺点，所以很多企业都不会使用myeclipse，而是直接使用免费的
eclipse，其次，myeclipse集成了非常多的其他插件，很多插件我们根本就不需要用到，这就使得myeclipse显得非常臃肿，启动也非常慢。
	上面大概的说了一下我们为什么需要使用eclipse的原因，接下来进入我们的主题，开始在eclipse搭建web项目，并整合spring
注意，以下教程是在eclipse luna版本进行，不同版本的eclipse可能会有点不一样
准备材料：apache-maven-3.5.4 下载地址：http://mirrors.hust.edu.cn/apache/maven/maven-3/3.5.4/source/apache-maven-3.5.4-src.zip
apache-tomcat-7.0.53 下载地址：https://tomcat.apache.org/download-70.cgi
1. 
1.1 解压下载的maven，进入解压后的目录，找到conf文件夹，点击进入，编辑settings.xml文件，找到
<localRepository>your repository path</localRepository>
配置你的仓库路径，如果不配，则默认使用 ${user.home}/.m2/repository，其他节点可根据自己的需求进行配置

1.2 解压tomcat到特定路径

2. 打开eclipse，点击 window --> preferences -->下图

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/setting.png)

3.配置tomcat：window --> preferences --> 下图：

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/tom1.png)

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/tom2.png)

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/tom3.png)


4.创建maven项目：右击 --> new -->other -> maven project --> 下图

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/maven1.png)

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/maven2.png)

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/maven3.png)

这时候创建好的项目并不能用于web开发。
5.将项目转换成Dynamic Web Project项目：
右击项目 --> properties --> 下图：

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/dy1.png)

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/dy2.png)

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/dy3.png)

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/dy4.png)

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/dy5.png)

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/dy6.png)

添加项目到服务器上：

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/ser1.png)
![image](https://github.com/Mitnick5194/myBlog/blob/master/images/ser2.png)
![image](https://github.com/Mitnick5194/myBlog/blob/master/images/ser3.png)
![image](https://github.com/Mitnick5194/myBlog/blob/master/images/ser4.png)

当我们看到了hello world 证明我们的项目已经跑起来了。
6.整合spring：
6.1 打开pom.xml 文件，在dependencies节点（如果没有，则创建）下面添加
<!-- spring -->
    <dependency>
		<groupId>org.springframework</groupId>
		<artifactId>spring-webmvc</artifactId>
		<version>2.5.6.SEC01</version>
	</dependency>
6.2 打开web.xml文件，tomcat启动时监听spring，添加如下配置：
	<context-param>
		<param-name>contextConfigLocation</param-name>
		<param-value>/WEB-INF/spring.xml</param-value>
	</context-param>
	<listener>
		<listener-class>org.springframework.web.context.ContextLoaderListener</listener-class>
	</listener>
	<!-- spring MVC -->
	<servlet>
		<servlet-name>springMVC</servlet-name>
		<servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
		<init-param>
			<param-name>contextConfigLocation</param-name>
			<param-value>/WEB-INF/spring-mvc-conf.xml</param-value>
		</init-param>
		<load-on-startup>1</load-on-startup>
	</servlet>
	<servlet-mapping>
		<servlet-name>springMVC</servlet-name>
		<!-- 拦截所有以.do结束的请求 -->
		<url-pattern>*.do</url-pattern>
	</servlet-mapping>

6.3 在WEB-INF文件夹下面创建spring.xml和spring-mvc.xml文件
spring.xml暂时不注入任何东西，只加入必要的命名空间保证不报错就好了，

<?xml version="1.0" encoding="UTF-8" ?>
<beans xmlns="http://www.springframework.org/schema/beans"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:context="http://www.springframework.org/schema/context"
	xmlns:p="http://www.springframework.org/schema/p"
	xsi:schemaLocation="http://www.springframework.org/schema/beans
  http://www.springframework.org/schema/beans/spring-beans-2.5.xsd">
</beans>

spring-mvc.xml按添加如下配置：

<?xml version="1.0" encoding="UTF-8" ?>
<!-- 基础业务模块配置文件 -->
<beans xmlns="http://www.springframework.org/schema/beans"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:context="http://www.springframework.org/schema/context"
	xmlns:p="http://www.springframework.org/schema/p"
	xsi:schemaLocation="http://www.springframework.org/schema/beans
  http://www.springframework.org/schema/beans/spring-beans-2.5.xsd
  http://www.springframework.org/schema/context
  http://www.springframework.org/schema/context/spring-context-2.5.xsd
	http://www.springframework.org/schema/tx
	http://www.springframework.org/schema/tx/spring-tx-2.5.xsd
	http://www.springframework.org/schema/aop
	http://www.springframework.org/schema/aop/spring-aop-2.5.xsd">
	
	
	<!-- 添加前后缀 -->
	<bean id="S-IRVR"
		class="org.springframework.web.servlet.view.InternalResourceViewResolver"
		p:prefix="/" p:suffix=".jsp" />
	<!-- 规约所有进行扫描的类，使用依赖控制器类名字的惯例优先原则， 
	将URI映射到控制器 如：“/xxx/index.do”对应“com.ajie.controller.XxxController.index()” -->
	<context:component-scan base-package="com.ajie.controller" />

	<bean id="S-CCHM"
		class="org.springframework.web.servlet.mvc.support.ControllerClassNameHandlerMapping">
		<property name="caseSensitive" value="false" />
	</bean>
	<!-- 除了惯例优先原则，以下是特例的URI及控制器映射 -->
	<bean id="S-SUHM"
		class="org.springframework.web.servlet.handler.SimpleUrlHandlerMapping">
		<property name="mappings">
			<value>
			<!-- 添加一个测试controller -->
			/myTestPro/hello/*.do=helloController
			</value>
		</property>
	</bean>
</beans>

创建controller：

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/con1.png)

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/con2.png)

这时候再次启动tomcat，你会发现报错了，包java.lang.ClassNotFoundException: org.springframework.web.context.ContextLoaderListener竟然说抱不到类，不是已经在maven里导入了吗，这时候
查看项目，你会发现，在项目的lib下面并没有maven导入的包，我们需要做以下的操作：
右击项目 --> properites --> 下图：
![image](https://github.com/Mitnick5194/myBlog/blob/master/images/lib.png)

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/lib2.png)

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/lib3.png)

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/lib4.png)

再次启动tomcat，发现一切正常，打开浏览器试试访问我们的控制器方法：
熟悉的hello world再次呈现在我们的眼前

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/ret1.png)

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/ret2.png)

右击项目 -->run as --> maven install 安装项目，这是会在仓库里找到该项目的war包，
但是使用解压工具解压出来我们可以看到，此时打包的是src/main/webapp下面的web项目
并不是我们的webapp；这时候需要更改pom文件

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/pom1.png)
再次install，war包下面的文件就是我们指定的webapp下面的文件了


方法2：
直接在pom里引入tomcat的maven插件，这个方法更便捷：
创建一个maven项目，不用选择模板，直接新建一个simple maven项目:

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/m2new1.png)

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/m2new2.png)
在pom.xml引入插件：
<plugin>
	<groupId>org.apache.tomcat.maven</groupId>
	<artifactId>tomcat7-maven-plugin</artifactId>
	<version>2.2</version>
	<configuration>
		<port>8080</port>
		<path>/</path>
	</configuration>
</plugin>
如果需要安装tomcat8插件，那么直接安装是不行的，这时候需要指定一个私服路径来下载插件包：
 <pluginRepositories> 
	 <pluginRepository> 
		<id>alfresco-public</id>    
		<url>https://artifacts.alfresco.com/nexus/content/groups/public</url> 
	  </pluginRepository>
 	</pluginRepositories>
  
  <build>
  	<plugins>
  		<plugin>
	          <groupId>org.apache.tomcat.maven</groupId>
	         <artifactId>tomcat8-maven-plugin</artifactId>
	          <version>3.0-r1655215</version>
  			</plugin>
  	</plugins>
创建web.xml文件和首页文件

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/m2file1.png)

运行项目：
run as --> maven build -->命令 clean tomcat7:run
注意，因为我们在插件中引入了的是tomcat7的插件，所以在运行的时候命令需要带上版本号，
如果不带上版本号，那么默认是运行tomcat6
测试install：
如果你已经在spring-mvc-conf.xml里注入了控制器，那么安装的时候可能会报错，说找不到这个控制器的错误，
这时候需要修改我们的class输出文件：
右击项目 --> build path --> configure build path -->下图

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/m2path.png)
到这里我们的tomcat就已经是安装成功并整合好spring了

在spring整合mybatis时，遇到了一个很棘手的问题:
查询的时候跑出了 一堆跟下面差不多的异常
Servlet.service() for servlet [springMVC] in context with path [] threw exception [Request processing failed; nested exception is org.apache.ibatis.binding.BindingException: Invalid bound statement (not found): com.ajie.mapper.MemberMapper.selectByExample] with root cause
java.lang.IllegalArgumentException: Mapped Statements collection does not contain value for com.ajie.mapper.MemberMapper.selectByExample
在网上找了一下相关的问题，很多人回答说是mapper生成的xml文件的权限命名可能和实际的不一样，我一想，感觉就是这个问题了，因为我用逆向工程生成的包的结构和当前项目的结构不一样，打开后发现过然不同，只好一个个改回来，再次运行，发现还是这个错误，这就很纳闷了，继续找资料，发现有和配置文件的打包也有关，在
pom.xml中加入：
 	 <resources>
            <resource>
                <directory>src/main/java</directory>
                <includes>
                     <include>**/*.properties</include>
                    <include>**/*.xml</include>
                </includes>
                <filtering>false</filtering>
            </resource>
        </resources> 

加完之后发现又有新的问题了，spring找不到配置了，在看看上面的，加载配置找到是src/main/java（其实这里是为了把mybatis的打包加载进来），但是你配了这个路径，意味着你所有的配置都从这个文件夹里读取，所以在也找不到src/main/resource的配置文件了，那就把resource里的路径也加进去吧
 	 <resources>
            <resource>
                <directory>src/main/java</directory>
                <includes>
                     <include>**/*.properties</include>
                    <include>**/*.xml</include>
                </includes>
                <filtering>false</filtering>
            </resource>
              <resource>
                <directory>src/main/resources</directory>
                <includes>
                     <include>**/*.properties</include>
                    <include>**/*.xml</include>
                </includes>
                <filtering>false</filtering>
            </resource>
        </resources>  -->

 好像好使了，能正常跑起来，再次测试，一切ok
 
 
 JMX实现修改配置不用重启系统：
 一般系统的设计是，在系统启动的时候，通过spring把所有的配置文件读进内存，如果修改了配置文件，那么，必须得重启系统，下面介绍一种可以不需要重启系统实现更新配置。
 大概思路：系统启动时，将配置文件读进缓存中，以后，每次需要读取配置的数据，都是从缓存中读取，如果缓存中没有，则重新将配置文件读入内存。所以，这里需要有个方法，当配置文件修改了，则将缓存中的数据清空，再次读取的时候，发现会是空，则读取重新加载配置文件，吧最新的数据读入，达到更新的作用
 注意：JMX的命名规范必须是先定义一个接口，接口是以被管理的bean的名字+MBean，该接口的方法，就是暴露在jconsole工具的方法。
 
 eclipse修改注释模板：
 修改新建java class时自动生成注释：
 window --> preferences --> java --> code style --> code templates --> code --> new java files --> edit 在${package_declaration}（包）和${typecomment}（public class ...）之间加入你想要的注释，例：
 
 ${filecomment}
${package_declaration}

/**
* @author ajie
*/
${typecomment}
${type_declaration}
在类的前面打上/**回车后自动生成模板注释方法：
window --> preferences --> java --> code style --> code templates --> comments --> Types --> edit 例:
/**
 * @author  ajie
 *
 * ${tags}
 */
 
 关于System.getProperties("user.dir")的坑
 上面获取的路径很奇怪，并不是项目的路径，也不是tomcat的路径，而是你启动tomcat时候所在的路径，比如你是进入了tomcat的bin文件夹下使用./start.sh启动
 tomcat的 那么上面获取的值就是你tomcat下的bin的绝对路径，如果你是在～目录下直接掉漆start.sh启动的 那么上面的值就是～，所以user.dir根本就不知一个绝对的值，可以铜鼓tomcat下面的catalina.sh修改，添加：
 JAVA_OPTS="-Duser.dir=逆向指定的路径"，注意，在随便的地方添加，但不能在有if块里添加，因为你不知到这里的if是否会进入，还有，尽管catalina.sh里已经有了JAVA_OPTS,但这并不影响你多起一个，这不会冲突或替换
 通过修改tomcat的启动脚本我们可以修改user.dir的路径，但是又有个问题了，你修改的是全局的，以为这tomcat容器里的所有项目拿到的user.dir都是你指定的那个，这个一来不符合需求，二来也会带来安全性问题，所以user.dir在项目里能并不建议使用，当然，如果你的一个tomcat运行一个项目，这就特殊对待。如果不是一个项目，最好就是用当前线程的所在的路径加载进来：
 		ClassLoader loaderloader = Thread.currentThread().getContextClassLoader();
		URL url = loader.getResource(xmlFileName);
		InputStream in = url.openStream();
这时候，我们的配置文件只要放在classes文件夹下面就可以加载进去了，如果是maven项目，那么我们只要吧配置文件放在src/main/resource下面，在安装时就会帮我们把配置文件打包到classes文件夹下面了

eclipse项目上传到git：
右击 --> team --> share project --> git --> Use or create repository it parent folder of project -->点击一下项目，下面的Create Repository会变成可点击状态-->点击Create Repository -->勾选项目 finish


使用命令行克隆git后导入eclipse：
首先复制github仓库的链接，在命令窗口中输入：git clone github仓库的地址
稍等片刻导出完成后，在eclipse中项目栏右击，选择import --> projects from git -->existing local repositoty --> add -->brower:找到你的项目导出的地址 -->next后选择import as general project
--> next-->finash，这时候的项目eclipse并不知道是不是java项目，所以看起来会很奇怪，如果你的是maven项目，则右击项目--> configure --> covert to maven project 即可，如果是普通的java项目
则可以：右击--> configure -->convert to faceted form -->勾选java，点击finish即可

maven打包项目源码：使用插件org.apache.maven.plugins
<build>
		<plugins>
			<plugin>
				<groupId>org.apache.maven.plugins</groupId>
				<artifactId>maven-source-plugin</artifactId>
				<executions>
					<execution>
						<id>attach-sources</id>
						<!--很奇怪 这里放开了 如果项目是jar类型的，项目会有红叉，注释了 又打包不成功/ -->
						<goals>
							<goal>jar</goal>
						</goals>
					</execution>
				</executions>
			</plugin>
		</plugins>
	</build>
	
打包某个模块：
	<plugin>
		<artifactId>maven-jar-plugin</artifactId>
		<executions>
			<execution>
				<id>user-module</id>
				<goals>
					<goal>jar</goal>
				</goals>
				<!--打包的后缀 -->
				<phase>package</phase>
				<!--life的多个阶段 ，预打包 -->
				<configuration>
					<!-- 打包好的文件存放位置和命名 -->
					<outputDirectory>target/user</outputDirectory>
					<classifier>user-module</classifier>
					<includes>
						<!--引入需要打包的文件的路径-->
						<include>**/user/**</include>
						<include>**/navigator/**</include>
					</includes>
				</configuration>
			</execution>
			<execution>
				<id>all</id>
				<goals>
					<goal>jar</goal>
				</goals>
				<phase>package</phase>
				<configuration>
					<classifier>all</classifier>
					***-all.jar
					<excludes>
						<!--排除 -->
						<exclude>**/model/**</exclude>
					</excludes>
					<includes>
						<!--引入-->
						<include>**/impl/**</include>
					</includes>
				</configuration>
			</execution>
		</executions>
	</plugin>



ubuntu16.04搭建openvpn
OpenVPN是使用TLS/SSL协议的VPN。也就是说客户端和服务器之间的流量是加密的，所以搭建openvpn需要生成安全证书，具体步骤如下：

    

1
2
$ sudo apt-get update
$ sudo apt-get install openvpn easy-rsa
到此为止，openvpn已经搭建完成，可以使用whereis openvpn查看相关路径
构建CA(以下操作是在root权限下执行，如果是普通用户，需要sudo权限)
进入openvpn路径：
cd /etc/openvpn
mkdir openvpn-ca
root@aliyun:/etc/openvpn# cp -r /usr/share/easy-rsa/ /etc/openvpn/
cd /etc/
root@aliyun:/etc/openvpn# cd easy-rsa/
vi vars
修改：
export KEY_COUNTRY="US"
export KEY_PROVINCE="CA"
export KEY_CITY="SanFrancisco"
export KEY_ORG="Fort-Funston"
export KEY_EMAIL="me@myhost.mydomain"
export KEY_OU="MyOrganizationalUnit"
在上面一段的下面有一个KEY_NAME，把值改为server：
export KEY_NAME="server"
值随意，但不能为空
使生效
root@aliyun:/etc/openvpn/easy-rsa# source vars
NOTE: If you run ./clean-all, I will be doing a rm -rf on /etc/openvpn/easy-rsa/keys
root@aliyun:/etc/openvpn/easy-rsa# 
NOTE不用管
root@aliyun:/etc/openvpn/easy-rsa# ./clean-all 
root@aliyun:/etc/openvpn/easy-rsa# ./build-ca
以下会提示再次输入配置里的内容，直接回车就行了
Generating a 2048 bit RSA private key
...................................+++
...............................................................................................................................+++
writing new private key to 'ca.key'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [CN]:
State or Province Name (full name) [GD]:
Locality Name (eg, city) [Guangzhou]:
Organization Name (eg, company) [myorg]:
Organizational Unit Name (eg, section) [MyOrganizationalUnit]:
Common Name (eg, your name or your server's hostname) [myorg CA]:
Name [server]:
Email Address [xxx@qq.com]:
生成服务端证书、密钥
root@aliyun:/etc/openvpn/easy-rsa# ./build-key-server server(server是生成证书名，可随意取)
下面也一样，一直回车，提示输入密码先不填，留空，遇到y/n，输入y
Generating a 2048 bit RSA private key
..............................................+++
..................................................................................................+++
writing new private key to 'server.key'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [CN]:
State or Province Name (full name) [GD]:
Locality Name (eg, city) [Guangzhou]:
Organization Name (eg, company) [myorg]:
Organizational Unit Name (eg, section) [MyOrganizationalUnit]:
Common Name (eg, your name or your server's hostname) [server]:
Name [server]:
Email Address [xxx@qq.com]:

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:
Using configuration from /etc/openvpn/easy-rsa/openssl-1.0.0.cnf
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
countryName           :PRINTABLE:'CN'
stateOrProvinceName   :PRINTABLE:'GD'
localityName          :PRINTABLE:'Guangzhou'
organizationName      :PRINTABLE:'myorg'
organizationalUnitName:PRINTABLE:'MyOrganizationalUnit'
commonName            :PRINTABLE:'server'
name                  :PRINTABLE:'server'
emailAddress          :IA5STRING:'xxx@qq.com'
Certificate is to be certified until Dec 15 13:10:40 2028 GMT (3650 days)
Sign the certificate? [y/n]:y


1 out of 1 certificate requests certified, commit? [y/n]y
Write out database with 1 new entries
Data Base Updated
root@aliyun:/etc/openvpn/easy-rsa#

生成Diffie-Hellman key
这里需要等到一段时间，也不会很久，十几到即使秒
生成HMAC签名加强TLS认证：
root@aliyun:/etc/openvpn/easy-rsa# openvpn --genkey --secret keys/ta.key
到此为止，服务端的证书已经生成了，可以进入/etc/openvpn/easy-rsa/keys查看（需要root用户，或修改权限）

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/openvpn/server-keys.png)

生成客户端证书、密钥
下面我为一个客户端生成证书，步骤和上面差不多，如果你有多个客户端可以重复这个过程，只要命名不重复就行了
同样一直回车，密码空。
./build-key client1

把上面生成的证书复制到对应的OpenVPN目录：
root@aliyun:/etc/openvpn/easy-rsa/keys# cp ca.crt ca.key server.crt server.key ta.key dh2048.pem /etc/openvpn/
将安装文件里的实例配置复制到openvpn目录：
root@aliyun:/etc/openvpn/easy-rsa/keys# cp  /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz  /etc/openvpn/
解压：
# gunzip -f server.conf.gz
编辑配置文件：（该文件的注释是在前面加;去除注释吧;去掉就行了）
vi server.conf
#这里是证书，如果是其他命名，则需要修改为对应的文件名，如果证书和配置文件不是在同一个目录，则需要用绝对定位
ca ca.crt
cert server.crt
key server.key  # This file should be kept secret

# Diffie hellman parameters.
去掉如下几行的注释：
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 208.67.222.222"
push "dhcp-option DNS 208.67.220.220"
user nobody
group nogroup
tls-auth ta.key 0 # This file is secret
key-direction 0

:wq保存
6 打开IP转发
$ sudo vim /etc/sysctl.conf
去掉这行的注释，如果没有，则添加这行
net.ipv4.ip_forward=1
使生效：
$ sudo sysctl -p
启动OpenVPN服务
sudo systemctl start openvpn@server
查看启动状态：
sudo systemctl status openvpn@server
状态显示绿色的running表示正常启动了，如果有红色报错，则根据错误再排查

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/openvpn/status.png)

查看是否多了一个虚拟网卡tun0:
ifconfig

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/openvpn/tun0.png)

到这里，openvpn已经搭建成功了

下面演示window安装vpn客户端连接服务端
下载openvpn windown版：
https://openvpn.net/community-downloads/  （需翻墙）
window相对简单很多，下载完成后，想普通软件一样安装，
安装完成，进入安装目录，找到\sample-config，吧client.ovpn复制到config目录下
吧服务端生成的客户端证书client1.crt、client1.key、ta.key、ca.crt复制到c:/user/{user}/OpenVpn/config/client目录
编辑client.ovpn
去除注释
comp-lzo
tls-auth ta.key 1
ca ca.crt
cert client1.crt
key client1.key（证书路径，和服务器配置原理一样）
remote my-server 1194 （这个是充电，my-server填写你自己的服务器公网ip）
保存退出
进入安装目录/bin/
找到openvpn-gui.exe,点击运行，
程序会在右下角出现，右击选择client，点击client，如果连接不上，可以右击选择选择setting，如下图，找到你对应的配置文件，重启即可

![image](https://github.com/Mitnick5194/myBlog/blob/master/images/openvpn/config.png)

注：如果是使用外部ifconf路径（非c:/user/{user}/openvpn/config/client目录）则在打开的时候会弹窗提示
There already exist a config file named '%s'. You cannot have multiple config files with the same name, even if they reside in diffrent folders.
如果想要去除弹窗，那么配置文件和证书只能放在c:/user/{user}/OpenVpn/config/client目录了
打开命令窗口，查看ip：
ipconfig
是否有一个和服务器tun0网卡同一网段的地址的ip，如果有，证明搭建成功，可以尝试ping一下，通了，则成功，不通，则查看日志；
![image](https://github.com/Mitnick5194/myBlog/blob/master/images/openvpn/ping.png)
成功了，这里会变成绿色，且显示ip地址
![image](https://github.com/Mitnick5194/myBlog/blob/master/images/openvpn/success.png)
注：
阿里云ecs服务器端口需要自己手动配置打开，可以到阿里云官网控制台进行配置，具体请自行百度google

编写自定义maven 插件
创建一个普通的maven插件，其中artifactId为xxx-maven-plugin(约定俗成),但不能使用maven-xxx-plugin，因为apache规范规定此命名格式为apache所有，如果使用
这种方式命名是侵权的。
创建好项目后，打开pom文件，编译插件开发依赖如下两个包：
<dependency>
			<groupId>org.apache.maven</groupId>
			<artifactId>maven-plugin-api</artifactId>
			<version>3.0</version>
		</dependency>

		<!-- dependencies to annotations -->
		<dependency>
			<groupId>org.apache.maven.plugin-tools</groupId>
			<artifactId>maven-plugin-annotations</artifactId>
			<version>3.4</version>
			<scope>provided</scope>
		</dependency>
编写第一个无参Mojo，这是最简单的Mojo
package com.ajie.custom.maven.plugin.test;

import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.plugin.MojoFailureException;
import org.apache.maven.plugins.annotations.Mojo;

/**
 *
 *
 * @author niezhenjie
 *
 */

@Mojo(name = "hello")
public class Hello extends AbstractMojo {

	public void execute() throws MojoExecutionException, MojoFailureException {
		getLog().info("hello world");

	}

}

每个Mojo必须继承AbstractMojo，声明周期可以通过 @Mojo注解指定；第一个Mojo基本上就算完成了，打开pom文件，在build节点添加：

	<plugins>
		<plugin>
			<groupId>com.ajie</groupId>
			<artifactId>custom-maven-plugin</artifactId>
			<version>1.0.10</version>
		</plugin>
		...
	</plugins>
	...
执行自定义Mojo，在项目的更目录使用命令
mvn groupId:artifactId:version:goal
如：com.ajie:custom-maven-plugin:1.0.10:hello
如果是在eclipse执行，不用带mvn
如不出意料，执行结果会报一下错误：
Plugin com.ajie:custom-maven-plugin:1.0.10 or one of its dependencies could not be resolved: Could not find artifact com.ajie:custom-maven-plugin:jar:1.0.10 in central (http://repo.maven.apache.org/maven2) -> [Help 1]
这是因为我们的pom文件没有指定packaging，在pom中添加
 <packaging>maven-plugin</packaging>
 这里一定要是maven-plugin，不能使用其他，但是保存后发现pom文件在该节点位置报错，这应该是eclipse编译器无法识别问题，不用管，继续执行
 如不出意料，还会报错：
 Plugin com.ajie:custom-maven-plugin:1.0.10 or one of its dependencies could not be resolved: Could not find artifact com.ajie:custom-maven-plugin:jar:1.0.10 in central (http://repo.maven.apache.org/maven2) -> [Help 1]
 提示很明显，仓库里找不到这个插件包，安装一下就可以了
 mvn install
 安装完成后继续执行上述命令
看到控制台成功打印出 hello world，第一个Mojo开发完成
在其他项目里使用自定义的插件
在需要使用的项目的pom文件里添加插件：
<plugin>
				<groupId>com.ajie</groupId>
				<artifactId>custom-maven-plugin</artifactId>
				<version>1.0.10</version>
				<executions>
					<execution>
						<phase>install</phase>
						<goals>
							<goal>hello</goal>
						</goals>
					</execution>
				</executions>

			</plugin>
其中phase是该插件绑定的生命周期，goal是目标Mojo，这里指向的是我们编写的hello Mojo,运行项目
mvn install
如果控制台打印出了hello world，则表示插件引用成功，如果提示错误，可根据错误提示自己调试
缩短命令：
缩短命令有多中方法
方法一：仓库只有一个版本，可以不带版本号，如果仓库有多个版本，也可以不带版本号，默认是使用最新的版本
com.ajie:custom-maven-plugin:hello
方法二：如果命名服务apache规范（xxx.maven-plugin)，则可以使用:
custom:hello
上述demo:
package com.ajie.custom.maven.plugin.test;

import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.plugin.MojoFailureException;
import org.apache.maven.plugins.annotations.Mojo;

/**
 * 最简单的Mojo
 * 
 * Mojo就是 Maven plain Old Java Object。每一个 Mojo 就是 Maven 中的一个执行目标（executable
 * goal），而插件则是对单个或多个相关的 Mojo 做统一分发。一个 Mojo 包含一个简单的 Java 类。插件中多个类似 Mojo
 * 的通用之处可以使用抽象父类来封装
 *
 * @author niezhenjie
 *
 */

@Mojo(name = "hello1")
public class Hello extends AbstractMojo {

	public void execute() throws MojoExecutionException, MojoFailureException {
		//获取抽象父类的日志输出接口，打印日志到控制台
		getLog().info("hello world");

	}

}

pom.xml
<build>
		<plugins>
			<plugin>
				<groupId>com.ajie</groupId>
				<artifactId>custom-maven-plugin</artifactId>
				<version>1.0.10</version>
			</plugin>
		</plugins>
	</build>
注：每次修改了代码，都要执行mvn install安装到仓库才能执行
编写带参Mojo
编写带参数的Mojo其实也很方便，只要再Mojo里定义好属性并提供相应的set方法，使用注解@Paramter(property="xxx",default="xxx")即可
在pom使用configuration节点传入参数，demo如下
package com.ajie.custom.maven.plugin.test;

import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.plugin.MojoFailureException;
import org.apache.maven.plugins.annotations.Mojo;
import org.apache.maven.plugins.annotations.Parameter;

/**
 * 测试传参
 *
 * @author niezhenjie
 *
 */

@Mojo(name = "param")
public class Paramters extends AbstractMojo {

	//property对应pom的节点的属性，defaultValue是默认值，非必传
	@Parameter(property = "name", defaultValue = "ajie")
	private String name;

	@Parameter(property = "greet", defaultValue = "hello")
	private String greet;

	public void execute() throws MojoExecutionException, MojoFailureException {
		getLog().info(name + " say " + greet);

	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getGreet() {
		return greet;
	}

	public void setGreet(String greet) {
		this.greet = greet;
	}

}

pom.xml
<build>
		<plugins>
			<plugin>
				<groupId>com.ajie</groupId>
				<artifactId>custom-maven-plugin</artifactId>
				<version>1.0.10</version>
				<configuration>
					<name>aki</name>
					<greet>hello world</greet>
				</configuration>
			</plugin>
		</plugins>
	</build>
其中，属性支持基本数据类型和复合数据类型，详情请查看官方文档
maven自定义插件官方文档写的很详细，有不懂的可以到官网查看文档说明：
https://maven.apache.org/guides/plugin/guide-java-plugin-development.html

ubuntu项目部署脚本，配置分离
项目的配置文件一般在本机环境，本地环境和生产环境是有所差异的，如果使用传统的打包上传至tomcat目录重启tomcat的方式部署项目，则每次部署都回把
配置文件覆盖掉，需要手动将它改回来，这样的部署方式非常低效且容易出现问题，所以在部署项目的时候一般采用的是配置分离。
配置分离的实现方式有很多种，可以在打包阶段忽略配置文件，也可以配置tomcat读取外部配置，但我这里要跟大家介绍的是使用覆盖的方式达到一种配置分离的
效果，基于shell脚本实现一键部署和快速回滚。
以我的环境为例：
tomcat HOME_PATH：/home/ajie/tomcat
打包项目上传路径：/var/www/${project}/
${project}代表你的项目名，每个项目独占一个文件夹，规范很重要，规范的操作能带来很多便捷的开发和维护
项目配置文件的路径：/var/www/${project}/properties/
部署项目shell脚本：/var/www/${project}/deploy.sh
![image](https://github.com/Mitnick5194/myBlog/blob/master/images/web/path.png)
图中.old文件在第一次部署时是没有的，第一次部署后，会存在，用作版本异常回滚使用，
下面来介绍我们的主角，部署脚本deploy.sh，以一个名为resource的项目为例
#/bin/bash
NAME=resource
UPLOAD_NAME=resource

BASE_PATH=/var/www/$NAME
TOMCAT_HOME=/home/ajie/tomcat
USER_DIR=/var/www/$NAME/$UPLOAD_NAME
TOMCAT_USER_DIR=$TOMCAT_HOME/webapps/$NAME
TOMCAT_WEBAPPS=$TOMCAT_HOME/webapps

#输出java环境变量，使用java代码远程调用命令执行本脚本，如果没有下面的输出，则会包找不到java_home和jre_home错误
# jdk enviroment
export JAVA_HOME=/home/ajie/java/jdk1.7.0_79
export CLASSPATH=.:$JAVA_HOME/lib:$JAVA_HOME/jre/lib:$CLASSPATH
export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH


#OPTION=stop对tomcat只关不开，start只开不关，move不关也不开，空执行传统的功能，关闭后移动再打开
#option 可选项，空|start|stop|move|rollback
#start 不进入关闭块，进入启动快
#stop 不进入启动块，进入关闭块
#move  既不进入启动块，也不进入关闭块
#rollback 版本回滚，关闭启动都执行
#空 既进入启动也进入关闭
OPTION=$1 # start|stop|move|rollback
echo $OPTION

if [ "$OPTION" = "rollback" ] ; then
	#回滚
	echo "mv ${BASE_PATH}/${NAME}.old to ${BASE_PATH}/${NAME}"
	mv  ${BASE_PATH}/${NAME}.old ${BASE_PATH}/${NAME} 

fi
#判断有没有上传文件
if [ ! -d $USER_DIR ] ; then
	#判断有没有war文件
	if [ ! -f ${BASE_PATH}/${NAME}.war ] ; then
		echo upload file  not exit
		exit 1
	else
		#解压
		echo 'unzip\c'
		echo "${USER_DIR}"
		unzip -d ${USER_DIR}/ ${BASE_PATH}/${NAME}.war
		echo 'delete war'
		rm ${BASE_PATH}/${NAME}.war
	fi
fi

#删除旧的备份
if [ -d $BASE_PATH/${NAME}.old ];then
	rm -rf $BASE_PATH/${NAME}.old
	echo deletting ${NAME}.old...
fi

#关闭tomcat 参数除了start和move不停止tomcat，其他情况都停止
if [[ "$OPTION" !=  "start" ]] && [[ "$OPTION" != "move"  ]];then
	$TOMCAT_HOME/bin/shutdown.sh
	echo -e "shutdown tomcat .\c"
	sleep 1 #等待6秒，等tomcat关闭
	echo -e ".\c" 
	sleep 1
	echo -e ".\c"
	sleep 1
	echo -e ".\c"
	sleep 1
	echo -e ".\c"
	sleep 1
	echo -e  "."
	sleep 1
fi
#将原来的项目打包备份，作版本异常回滚使用
if [ -d  $TOMCAT_USER_DIR ];then
	mv  $TOMCAT_USER_DIR $BASE_PATH/${NAME}.old
	echo "moving $TOMCAT_USER_DIR to $BASE_PATH/${NAME}.old"

	
fi

#将配置文件复制到项目中 如果项目中的配置有改变 那么需要手动在/var/www/项目名/properties/下面找到对应的配置进行修改
# 进入配置文件夹
cd $BASE_PATH/properties
echo -e "into dir \c"
pwd
#for file in `ls $BASE_PATH/properties`
for file in `ls`
do
    if test -d $file;then
	     # 文件夹
		 cp -rf $file $USER_DIR/WEB-INF/classes/
	else
		cp -f $file $USER_DIR/WEB-INF/classes/
	fi
	echo "coping $file to $USER_DIR/WEB-INF/classes"
done

#将上传的项目重命名
#将项目移到tomcat下的webapps
mv $BASE_PATH/$UPLOAD_NAME $TOMCAT_WEBAPPS/$NAME
echo "moving $BASE_PATH/$NAME to  $TOMCAT_WEBAPPS/"

#重启tomcat，除了stop和move时不启动tomcat，其他情况都启动
if [[ "$OPTION" != "stop" ]] && [[ "$OPTION" != "move" ]];then
	$TOMCAT_HOME/bin/startup.sh
	echo "done"
fi

脚本的工作流程
1、判断有没有上传待部署的项目，如果上传的是war包，则先解压，没有检测到上传的项目则退出
2、删除上一个回滚备份文件xxx.old
3、关闭tomcat服务器
4、复制tomcat服务器的项目到/var/www/${project}/文件夹下，并命名为/var/www/${project}/${project}.old，做回滚使用
5、将/var/www/${project}/properties/下面的配置复制（覆盖）到/var/www/${project/${上传的项目}下
6、将项目复制到tomcat服务器
7、重启tomcat
如果增加或修改了配置文件，则需要在/var/www/${project}/properties找到对应的文件进行同步修改或添加
脚本可接受一个参数，参数包括：
start|stop|move|rollback
start:在执行完成后启动tomcat
stop: 在执行时关闭了tomcat，执行完成后不启动
move：在执行时不会去关闭tomcat，执行完成后也不会去启动tomcat
rollback：回滚版本

<h1>开发自定义的maven插件，实现打包上传部署一键完成</h1>
在阅读此文章之前，你需要对maven自定义开发有所了解，可以参考xxx TODO和一键部署的脚本XXX //TODO
这篇文章其实就是对上述的两篇文章的一个结合，直接上代码：
package com.ajie.custom.maven.plugin.build;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugin.MojoFailureException;
import org.apache.maven.plugins.annotations.Parameter;
import org.apache.maven.project.MavenProject;

import com.ajie.custom.maven.plugin.vo.Server;

/**
 * 抽象的mojo
 *
 * @author niezhenjie
 *
 */
public abstract class AbstractCustomMojo extends AbstractMojo {

	public static final String MAVEN_HOME = "MAVEN_HOME";
	/** 从配置文件中配置maven home目录 */
	public static final String MAVEN_HOME_KEY = "maven.home";
	/** 文件分隔符 */
	public static final String SEPARATOR = File.separator;
	/** maven命令 */
	public static String MAVEN_CMD = "bin" + SEPARATOR + "mvn";
	static {
		String os = System.getProperty("os.name");
		if (os.startsWith("win") || os.startsWith("Win")) {
			MAVEN_CMD += ".bat";// window系统 bin/mvn.bat
		}
	}

	public static final String TARGET_FOLDER = "target";

	@Parameter(property = "project")
	protected MavenProject project;
	/** 服务器信息，和serverFile二选一，如果两个都配置，最终读取serverFile里的信息 */
	@Parameter
	protected Server server;
	/**
	 * 服务器信息配置文件路径，该配置文件只能读取custom-maven-plugin项目下面的，不能读取待打包项目的路径，
	 * 使用相对classpath路径，和server二选一，如果两个都配置，最终读取server里的信息
	 */
	@Parameter
	protected String serverFile;
	/** user.dir */
	private String userDir;
	/** 打包后的文件目录 */
	private String targetDir;
	/** 打包后的项目路径 */
	private String targetFilePath;
	/** 项目名 */
	private String projectName;
	/** 类型名 jar、war.. */
	private String projectType;

	public String getMavenHome() {
		/*// 启动时通过参数传入
		String home = System.getProperty(MAVEN_HOME_KEY);
		if (!StringUtils.isEmpty(home)) {
			return home;
		}*/
		// pom文件中配置
		String home = project.getProperties().getProperty(MAVEN_HOME_KEY);
		if (null != home) {
			return home;
		}
		// 环境变量
		return System.getenv(MAVEN_HOME);
	}

	public String getMvn() throws MojoFailureException {
		String mavenHome = getMavenHome();
		if (null == mavenHome) {
			getLog().error("缺少maven主目录");
			throw new MojoFailureException("缺少maven主目录");
		}
		if (!mavenHome.endsWith(SEPARATOR)) {
			mavenHome += SEPARATOR;
		}
		return mavenHome + MAVEN_CMD;
	}

	public String getProjectName() {
		if (null != projectName) {
			return projectName;
		}
		projectName = project.getArtifactId();
		return projectName;
	}

	public String getPom() {
		StringBuilder sb = new StringBuilder();
		String userDir = getUserDir();
		sb.append(userDir);
		sb.append("pom.xml");
		return sb.toString();
	}

	public void setProject(MavenProject project) {
		this.project = project;
	}

	public MavenProject getProject() {
		return project;
	}

	public void setServer(Server server) {
		this.server = server;
	}

	/**
	 * 项目目录，结束符为"/" ,因为在eclipse运行，所以user.dir始终指向项目路径
	 * 
	 * @return
	 */
	public String getUserDir() {
		if (null != userDir) {
			return userDir;
		}
		String userDir = System.getProperty("user.dir");
		if (!userDir.endsWith(SEPARATOR)) {
			userDir += SEPARATOR;
		}
		this.userDir = userDir;
		return userDir;
	}

	public String getTargetDir() {
		if (null != targetDir) {
			return targetDir;
		}
		String userDir = getUserDir();
		targetDir = userDir + TARGET_FOLDER;
		return targetDir;
	}

	public String getTargetFilePath() {
		if (null != targetFilePath)
			return targetFilePath;
		targetFilePath = getTargetDir() + SEPARATOR;
		return targetFilePath;
	}

	public String getProjectType() {
		if (null != projectType) {
			return projectType;
		}
		projectType = project.getPackaging();
		return projectType;
	}

	public Server getServer() throws MojoFailureException {
		// 单例，不存在并发，不需要锁
		if (null != server)
			return server;
		if (null == serverFile)
			return server;
		InputStream is = Thread.currentThread().getContextClassLoader()
				.getResourceAsStream(serverFile);
		if (null == is)
			throw new MojoFailureException("找不到配置文件，serverFile=" + serverFile);
		Properties prop = new Properties();
		try {
			prop.load(is);
		} catch (IOException e) {
			throw new MojoFailureException("无法加载配置文件，serverFile=" + serverFile, e);
		}
		String host = prop.getProperty("host");
		String username = prop.getProperty("username");
		String password = prop.getProperty("password");
		String sPort = prop.getProperty("port");
		String sIsupload = prop.getProperty("isupload");
		if (null == host)
			throw new MojoFailureException("主机为空，host=" + host);
		if (null == username)
			throw new MojoFailureException("用户名为空，username=" + username);
		int port = 0;
		try {
			port = Integer.valueOf(sPort);
		} catch (Exception e) {
			getLog().warn("无法解析端口：" + sPort + "，使用默认端口代替port:" + port);
			port = Server.DEFAULT_PORT;
		}
		boolean isUpload = false;
		try {
			isUpload = Boolean.valueOf(sIsupload);
		} catch (Exception e) {
			if ("true".equalsIgnoreCase(sIsupload))
				isUpload = true;
			else if ("false".equalsIgnoreCase(sIsupload))
				isUpload = false;
			else {
				getLog().warn("无法判断是否上传，sIsupload：" + sIsupload + "，默认不上传");
				isUpload = false;
			}

		}
		Server server = new Server();
		server.setHost(host);
		server.setUserName(username);
		server.setPassword(password);
		server.setPort(port);
		server.setIsUpload(isUpload);
		return server;
	}
}



package com.ajie.custom.maven.plugin.build;

import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.plugin.MojoFailureException;
import org.apache.maven.plugins.annotations.Mojo;

import com.ajie.custom.maven.plugin.util.ExecuteUtil;
import com.ajie.custom.maven.plugin.util.UploadUtil;
import com.ajie.custom.maven.plugin.vo.Server;

/*
 * 自定义打包插件，打包完成可以自动上传服务器<br>
 * pom配置：<br>
 * <build>
		<plugins>
			<plugin>
				<groupId>com.ajie</groupId>
				<artifactId>custom-maven-plugin</artifactId>
				<version>1.0.10</version>
				<executions>
					<execution>
						<goals>
							<goal>install</goal>
						</goals>
					</execution>
				</executions>
				<configuration>
					<server>
						<host>www.ajie.top</host>
						<username>ajie</username>
						<password>123</password>
						<port>22</port>
						<isupload>true</isupload>
					</server>
				</configuration>
			</plugin>
		</plugins>
	</build>
 *
 * @author niezhenjie
 *
 */
@Mojo(name = "package")
public class PackageMojo extends AbstractCustomMojo {

	public void execute() throws MojoExecutionException, MojoFailureException {
		getLog().info("start package ...");
		packageProject();
	}

	public void packageProject() throws MojoFailureException {
		String mvn = getMvn();
		String cmd = mvn + " package";
		ExecuteUtil.execute(cmd, getLog());
		getLog().info("package success");
		Server server = null;
		try {
			server = getServer();
		} catch (MojoFailureException e) {
			getLog().error("package success but upload fail", e);
			return;
		}
		if (null == server)
			return;
		if (!server.isUpload())
			return;
		getLog().info("start upload file to server");
		if (getLog().isDebugEnabled()) {
			getLog().debug(server.toString());
		}
		long start = System.currentTimeMillis();
		UploadUtil.upload(getTargetFilePath(), getProjectName() + "." + getProjectType(), server,
				getLog());
		long end = System.currentTimeMillis();
		getLog().info("upload success, time consuming: " + (end - start) / 1000 + "s");
		getLog().info("exec remote deploy script");
		start = System.currentTimeMillis();
		ExecuteUtil.execute(getServer(), getProjectName(), getLog());
		end = System.currentTimeMillis();
		getLog().info(
				"exec remote deploy script success,time consuming: " + (end - start) / 1000 + "s");
		getLog().info("done");
	}

}

package com.ajie.custom.maven.plugin.vo;

/**
 * 服务器信息
 *
 * @author niezhenjie
 *
 */
public class Server {
	/** 默认端口 */
	public static final int DEFAULT_PORT = 22;
	/** 默认上传的根目录 */
	public static final String DEFAULT_UPLOAD_PATH = "/var/www/";
	/** 主机地址 */
	private String host;
	/** 用户名 */
	private String username;
	/** 密码 */
	private String password;
	/** 端口 */
	private int port;
	/** 是否上传 */
	private boolean isupload;
	/** 上传至服务器路径，最终文件会上传至uploadpath+projectName路径 */
	private String uploadBasePath;

	public Server() {

	}

	public String getHost() {
		return host;
	}

	public void setHost(String host) {
		this.host = host;
	}

	public String getUserName() {
		return username;
	}

	public void setUserName(String userName) {
		this.username = userName;
	}

	public String getPassword() {
		return password;
	}

	public void setPassword(String password) {
		this.password = password;
	}

	public int getPort() {
		return port;
	}

	public void setPort(int port) {
		this.port = port;
	}

	public static int getDefaultPort() {
		return DEFAULT_PORT;
	}

	public void setIsUpload(boolean b) {
		isupload = b;
	}

	public boolean isUpload() {
		return isupload;
	}

	public void setUploadBasePath(String uploadpath) {
		this.uploadBasePath = uploadpath;
	}

	/**
	 * 获取上传文件至服务器的路径，路径结束符为/
	 * 
	 * @return
	 */
	public String getUploadBasePath() {
		if (null == uploadBasePath)
			uploadBasePath = DEFAULT_UPLOAD_PATH;
		if (!uploadBasePath.endsWith("/")) {
			uploadBasePath += "/";
		}
		return uploadBasePath;
	}

	@Override
	public String toString() {
		StringBuilder sb = new StringBuilder();
		sb.append("{host:").append(host).append(",");
		sb.append("username:").append(username).append(",");
		sb.append("isupload:").append(isupload).append(",");
		sb.append("uploadBasePath:").append(uploadBasePath).append("}");
		return sb.toString();
	}

}

package com.ajie.custom.maven.plugin.util;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;

import org.apache.maven.plugin.MojoFailureException;
import org.apache.maven.plugin.logging.Log;

import com.ajie.custom.maven.plugin.vo.Server;
import com.jcraft.jsch.ChannelExec;
import com.jcraft.jsch.JSch;
import com.jcraft.jsch.Session;

/**
 * 执行命令
 *
 * @author niezhenjie
 *
 */
public final class ExecuteUtil {

	private ExecuteUtil() {

	}

	/**
	 * 执行mvn命令
	 * 
	 * @param cmd
	 * @param log
	 * @throws MojoFailureException
	 */
	public static void execute(String cmd, Log log) throws MojoFailureException {
		InputStream is = null;
		try {
			Process process = Runtime.getRuntime().exec(cmd);
			is = process.getInputStream();
			BufferedReader reader = new BufferedReader(new InputStreamReader(is));
			String line = null;
			while ((line = reader.readLine()) != null) {
				line = line.replace("[INFO]", ""); // 去除info标记，否则会有两个[INFO]
				log.info(line);
			}
			int exitVal = process.waitFor();
			if (0 != exitVal) {
				// 有错误
				BufferedReader error = new BufferedReader(new InputStreamReader(is));
				line = null;
				while ((line = error.readLine()) != null) {
					log.error(line);
				}
			}
		} catch (IOException e) {
			throw new MojoFailureException("发布失败", e);
		} catch (InterruptedException e) {
			throw new MojoFailureException("发布失败", e);
		} finally {
			if (null != is) {
				try {
					is.close();
				} catch (IOException e) {
					// 忽略
				}
			}
		}
	}

	public static void execute(Server server, String projectName, Log log)
			throws MojoFailureException {
		StringBuilder cmd = new StringBuilder();
		cmd.append(server.getUploadBasePath());
		cmd.append(projectName);
		cmd.append("/");
		cmd.append("deploy.sh");
		ByteArrayOutputStream out = new ByteArrayOutputStream();
		InputStream in = null;
		JSch jsch = new JSch();
		String host = server.getHost();
		String username = server.getUserName();
		String password = server.getPassword();
		int port = server.getPort();
		// 我上传的路径结构时${basePath}/${projectName}/${fileName}
		Session session = null;
		ChannelExec channel = null;
		try {
			session = jsch.getSession(username, host, port);
			session.setConfig("StrictHostKeyChecking", "no");
			session.setPassword(password);
			session.connect(30000);
			channel = (ChannelExec) session.openChannel("exec");
			channel.setInputStream(null);
			channel.setErrStream(out);
			channel.setCommand(cmd.toString());
			in = channel.getInputStream();
			channel.connect();
			byte[] buf = new byte[1024];
			while (true) { // 因为是异步的，数据不一定能及时获取到，所以需要轮询
				while (in.available() > 0) {
					in.read(buf);
					out.write(buf);
				}
				if (channel.isClosed()) { // channel关闭了，但是还有数据在流中，继续读
					if (in.available() > 0)
						continue;
					break;
				}
				Thread.sleep(10);
			}
			BufferedReader reader = new BufferedReader(new InputStreamReader(
					new ByteArrayInputStream(out.toByteArray())));
			if (log.isDebugEnabled()) {
				String line = null;
				while ((line = reader.readLine()) != null) {
					log.info(new String(line.getBytes("utf-8"), "utf-8"));
				}
			}
		} catch (Exception e) {
			log.error("文件上传成功，执行脚本失败", e);
		} finally {
			try {
				if (null != in)
					in.close();
				if (null != channel && channel.isConnected())
					channel.disconnect();
				if (null != session && session.isConnected())
					session.disconnect();
				out = null;
			} catch (Exception e) {
			}
		}

	}
}

package com.ajie.custom.maven.plugin.util;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.rmi.RemoteException;

import org.apache.maven.plugin.MojoFailureException;
import org.apache.maven.plugin.logging.Log;

import com.ajie.custom.maven.plugin.vo.Server;
import com.jcraft.jsch.Channel;
import com.jcraft.jsch.ChannelSftp;
import com.jcraft.jsch.JSch;
import com.jcraft.jsch.Session;
import com.jcraft.jsch.SftpException;

/**
 * 文件上传工具
 *
 * @author niezhenjie
 *
 */
final public class UploadUtil {

	private UploadUtil() {

	}

	/**
	 * 文件上传,上传文件不能使文件夹，可以是war或jar（java io无法读取文件夹）
	 * 
	 * @param src
	 *            需要上传的文件所在的目录
	 * @param procectName
	 *            项目名称，要带后缀，如blog.war
	 * @param server
	 *            服务器信息
	 * @param log
	 * @throws MojoFailureException
	 */
	public static void upload(String src, String fileName, Server server, Log log)
			throws MojoFailureException {
		if (null == src) {
			throw new MojoFailureException("无上传目录,src=" + src);
		}
		if (fileName.indexOf(".") == -1) {
			throw new MojoFailureException("无法上传文件夹,fileName=" + fileName);
		}
		src += fileName;
		FileInputStream in = null;
		OutputStream out = null;
		try {
			File file = new File(src);
			in = new FileInputStream(file);
			JSch jsch = new JSch();
			String host = server.getHost();
			String username = server.getUserName();
			String password = server.getPassword();
			int port = server.getPort();
			String path = server.getUploadBasePath();
			// 我上传的路径结构时${basePath}/${projectName}/${fileName}
			String name = fileName.substring(0, fileName.lastIndexOf("."));
			path += name + "/";
			Session session = jsch.getSession(username, host, port);
			session.setConfig("StrictHostKeyChecking", "no");
			session.setPassword(password);
			session.connect(30000);
			Channel channel = session.openChannel("sftp");
			ChannelSftp sftp = (ChannelSftp) channel;
			sftp.connect(30000);
			String folder = createFolders(path, sftp);
			out = sftp.put(folder + fileName);
			byte[] buf = new byte[1024];
			int n = 0;
			while ((n = in.read(buf)) != -1) {
				out.write(buf, 0, n);
			}
			out.flush();
			out.close();
		} catch (Exception e) {
			log.error("打包成功，上传失败", e);
		} finally {
			try {
				if (null != in)
					in.close();
				if (null != out)
					out.close();
			} catch (IOException e) {
			}
		}
	}

	/**
	 * 切割配置里的目录路径 basePath形式 如：/var/www/或var/www 不管哪种形式，都是绝对路径
	 * 
	 * @return
	 * @throws RemoteException
	 */
	static private String createFolders(String path, ChannelSftp sftp) throws IOException {
		if (path.startsWith("/")) {
			path = path.substring(1);
		}
		String[] folders = path.split("/");
		if (null == folders) {
			folders = new String[0];
		}
		String cd = "";
		// 进入目录，如果目录不存在，则创建目录
		for (int i = 0; i < folders.length; i++) {
			cd += "/" + folders[i];
			boolean currErr = false;// 创建目录过程中出现了错误
			Throwable e = null;
			try {
				sftp.cd(cd);
			} catch (SftpException exce) {
				// 没有则创建
				try {
					sftp.mkdir(cd);
				} catch (SftpException e1) {
					currErr = true;
					e = e1;
					break;
				}
			}
			if (currErr) {
				throw new IOException("无法创建目录 ", e);
			}
		}
		// 结尾加上/如/var/www/
		if (null != path) {
			cd += "/";
		}
		return cd;
	}
}

使用：
将本插件安装到本地仓库，在需要使用的项目的pom文件引入以下插件(使用时将>全部替换成>,<全部替换成<，这里为了是github显示做了处理)
&lt;build&gt;
	&lt;plugins&gt;
		&lt;plugin&gt;
			&lt;groupId&gt;com.ajie&lt;/groupId&gt;
			&lt;artifactId&gt;custom-maven-plugin&lt;/artifactId&gt;
			&lt;version&gt;1.0.10&lt;/version&gt;
			&lt;executions&gt;
				&lt;execution&gt;
					&lt;goals&gt;
						绑定的生命周期
						&lt;goal&gt;install&lt;/goal&gt;
					&lt;/goals&gt;
				&lt;/execution&gt;
			&lt;/executions&gt;
			&lt;configuration&gt;
				&lt;server&gt;
					&lt;host&gt;服务器主机&lt;/host&gt;
					&lt;username&gt;登录的用户名&lt;/username&gt;
					&lt;password&gt;登录密码&lt;/password&gt;
					&lt;port&gt;端口&lt;/port&gt;
					&lt;isupload&gt;是否执行自动上传并部署 true|false defalut false&lt;/isupload&gt;
				&lt;/server&gt;
			&lt;/configuration&gt;
		&lt;/plugin&gt;
	&lt;/plugins&gt;
&lt;/build&gt;
其中，server信息的配置除上述以外，还可以使用
&lt;configuration&gt;
	&lt;serverFile&gt;相对于classpath的路径&lt;/serverFile&gt;	
&lt;/configuration&gt;
但是，需要注意的是，serverFile指向的配置文件不是放在需要运行的项目，而是放在本插件的项目里
运行插件：custom:package（debug模式：custom:package -X）

