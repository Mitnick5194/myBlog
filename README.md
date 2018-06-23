#随手写的博客 当做是记录吧

1.ubuntu免密码登录远程服务器
机器1：个人电脑 Ubuntu14.01lts系统
机器2： 阿里云服务器 ubuntu16.04lts系统
步骤1：在我的机器上生成ssh密钥对
命令：ssh-keygen -t rsa
在这过程中会提示输入密码， 密码可以不输入 直接enter 接着会提示密钥对的保存路径 也可以不输入 使用默认的路径 ～/.ssh/目录（是当前用户的home路径）
进入～/.ssh/， ls -l 可以看到刚才生成的密钥对，如下所示
id_rsa	id_rsa.pub  known_hosts
其中 id_rsa是密钥，一定要保存好，切勿泄露，id_rsa.pub是公钥，需要放到远程机器上的
步骤2：上传公钥到远程服务器上
使用命令
scp ~/.ssh/id_rsa.pub 用户名@服务器ip:~/.ssh/authorized_keys
scp是linux下跨机器复制命令，详细用法请自行google， 这个命令需要注意的是，ssh需要使用默认的端口 如果不是默认的端口，则不能使用该命令进行远程拷贝
上面的命令是把 本机的id_rsa.pub里面的内容赋值到远程服务器的~/.ssh/authorized_keys文件里，注意 如果authorized_keys文件本来有内容 ， 则会被覆盖
所以，如果怕被覆盖，可以使用其他名字上传 如：scp ~/.ssh/id_rsa.pub 用户名@服务器ip:~/.ssh/abcde 这样，我们的公钥就会保存在acbde的文件里，然后
使用密码登录上远程服务器，进入~/.ssh/文件夹，使用命令cat abcde>>authorized_keys 注意，这里一定要使用>> 不能使用单个> 单个也会覆盖，两个表示追加。
到这里基本完成了，尝试使用命令登录ssh xxx@xxx.xxx.xxx.xxx -p xx 如果没有提示输入密码，那么就算是操作成功了
