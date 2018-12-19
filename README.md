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
安装: make install (如果有错误 有可能是全选问题 试试使用sudo make install执行)
安装后的文件默认放在/usr/local/nginx/下面
3.测试：
sudo ./nginx -v 显示版本
sudo ./nginx -t 测试
sudo ./nginx -s reload 重新载入配置文件
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

到此,nginx已经成功配置了ssl，重启服务：
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
吧服务端生成的客户端证书client1.crt、client1.key、ta.key、ca.crt复制到config目录
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
打开命令窗口，查看ip：
ipconfig
是否有一个和服务器tun0网卡同一网段的地址的ip，如果有，证明搭建成功，可以尝试ping一下，通了，则成功，不通，则查看日志；
![image](https://github.com/Mitnick5194/myBlog/blob/master/images/openvpn/ping.png)
成功了，这里会变成绿色，且显示ip地址
![image](https://github.com/Mitnick5194/myBlog/blob/master/images/openvpn/success.png)
注：
阿里云ecs服务器端口需要自己手动配置打开，可以到阿里云官网控制台进行配置，具体请自行百度google

搭建nginx+https