#!/bin/bash
#本脚本用于检测目标服务器的网络连通性，指定直播流地址的状态是否为200，指定服务器的内存，硬盘，cpu使用率。
#使用脚本前，需要在和该脚本相同目录下创建ip.txt(一行一个ip或者域名),url.txt(一行一个直播流地址，如:http://10.33.0.68/channels/preview/1/flv:500k)
#在检测目标服务器的内存，硬盘和cpu时，需要设置监控机器能无需密码即可登录被监控服务器。设置方法见：http://blog.chinaunix.net/uid-12306154-id-3053425.html 第二条说明
#网络监测部分
function install_init()
{
 #此函数在第一次执行该脚本时执行，如果执行过一次，并添加到crontab中，可将该函数的执行命令删掉。
 yum -y install mail
 yum -y install sendmail-devel
 hostname=`hostname`
 sed -i "s/127.0.0.1/127.0.0.1 $hostname/g"  /etc/hosts
 sed -i "s/::1/::1 $hostname/g"  /etc/hosts
 /etc/init.d/sendmail start
 chkconfig sendmail on
}
function net_test()
{
> temp.txt
for line in `cat ip.txt`
do
ping $line -c 1 >/dev/null  2>&1
result=`echo $?`
systime=`date '+%F %T'`
if [ $result -eq 0 ]
then
echo $line >> temp.txt
else
/usr/bin/printf "$systime Can't reach $line " | /bin/mail -s "net_test" hanxin@tvie.com.cn
/usr/bin/printf "$systime Can't reach $line " | /bin/mail -s "net_test" hanxin_hisen@yeah.net
fi
done
}
#直播流地址监测部分
function live_test()
{
   for line in `cat url.txt`
   do
   status=`curl -I -m 10 -o /dev/null -s -w %{http_code}  $line`
   if [ $status == 200  ]
   then
   echo 'nothing' >/dev/null  2>&1 
   else
   /usr/bin/printf "$systime $line status not 200 ok" | /bin/mail -s "live_test" hanxin@tvie.com.cn
   /usr/bin/printf "$systime $line status not 200 ok" | /bin/mail -s "live_test" hanxin_hisen@yeah.net

   fi
   done
}
#硬盘监测部分
function disk_test()
{    
     for line in `cat temp.txt`
     do
     #disk_use=`ssh root@10.33.0.249 df -lh | awk 'NR==3' | awk '{print $4}'`
     disk_use=`ssh root@$line df -hl | awk 'NR==3' | awk '{print $4}' | awk '{printf substr($1,1,length($1)-1)}'`
     #90为90%
     if [ $disk_use -gt 90 ]
     then
     /usr/bin/printf "$systime $line disk use more than 90 percent" | /bin/mail -s "disk_test" hanxin@tvie.com.cn
     /usr/bin/printf "$systime $line disk use more than 90 percent" | /bin/mail -s "disk_test" hanxin_hisen@yeah.net
     else
     echo 'nothing' >/dev/null  2>&1
     fi
     done
}
#内存监测部分
function mem_test()
{   for line in `cat temp.txt`
    do
    mem_used=`ssh root@$line free | awk 'NR==2' | awk '{print $3}'`
    mem_all=`ssh root@$line free | awk 'NR==2' | awk '{print $2}'`
    #mem_per=`echo "sclae=4; $mem_used / $mem_all" | bc`
    mem_per=`awk 'BEGIN{printf "%.2f%\n", ('$mem_used'/'$mem_all')*100}' | awk -F'.' '{print $1}'`
    if [ $mem_per -gt 80 ]
    then
    /usr/bin/printf "$systime $line mem use more than 80 percent" | /bin/mail -s "mem_test" hanxin@tvie.com.cn
    /usr/bin/printf "$systime $line mem use more than 80 percent" | /bin/mail -s "mem_test" hanxin_hisen@yeah.net
    else
    echo 'nothing' >/dev/null  2>&1
    fi
    done
}
function cpu_test()
{   
    for line in `cat temp.txt`
    do
    temp=`ssh root@$line vmstat 1 3 |tail -1`
    user=`echo $temp |awk '{printf("%s\n",$13)}'`
    system=`echo $temp |awk '{printf("%s\n",$14)}'`
    idle=`echo $temp |awk '{printf("%s\n",$15)}'`
    total=`echo|awk '{print (c1+c2)}' c1=$system c2=$user`
    if [ $total -gt 10 ]
    then
    /usr/bin/printf "$systime $line cpu use more than 10 percent" | /bin/mail -s "cpu_test" hanxin@tvie.com.cn
    /usr/bin/printf "$systime $line cpu use more than 10 percent" | /bin/mail -s "cpu_test" hanxin_hisen@yeah.net
    else
    echo 'nothing' >/dev/null  2>&1
    fi
    done
}
install_init
net_test
disk_test
live_test
cpu_test
