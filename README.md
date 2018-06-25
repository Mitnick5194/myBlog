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

好 ,执行.startup.sh 再来，当我准备松口气时，发现还是too young too simple , 这次可恶的403页面没有出现了，但是密码正确硬是说我不正确，当时我就想拿起我这三块钱的拖鞋砸烂这三百块的电脑。绝望之际，我也不知为什么，就是很突然的想查看一下tomcat的进程，ps -ef | grep tomcat , 不看不知道，一看吓一跳，怎么会有两个进程的，难不成刚才直接运行了.startup.sh 而没有先执行shutdown.sh，就起来了两个了？但是为什么不会出现端口冲突呢，又是一个纳闷现象，管不了那么多了，先kill了两个tomcat进程在说，再次启动，噗，thanks godness!!!



