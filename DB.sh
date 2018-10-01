#!/bin/bash
echo "使用脚本须知本脚本不能修改主机名否则无法生效，初始主机名最好"
sleep 1 
R(){
expect << EOF
spawn   ssh-keygen
expect "Enter file in which to save the key (/root/.ssh/id_rsa): " {send "\r"}
expect "Enter passphrase (empty for no passphrase):"      {send "\r"}
expect "Enter same passphrase again:"              {send "\r"}
expect "#"              {send "echo 123\r}
EOF
}

M(){
expect << EOF
spawn  ssh-copy-id $o
expect "Are you sure you want to continue connecting (yes/no)?" {send "yes\r"}
expect "s password:"			{send "123456\r"}
expect "#"			{send "echo 123\r"}
EOF
}


Y(){
expect << EOF
set timeout -1
spawn  ssh $o
expect " ~]#"   {send "rm -rf /etc/yum.repos.d/* \r"}
expect " ~]#"   {send "yum-config-manager --add ftp://192.168.4.254/rhel7\r"}
expect " ~]#"   {send "echo gpgcheck=0 >> /etc/yum.repos.d/192.168.4.254_rhel7.repo\r"}
expect " ~]#"   {send "tar -xf ${B}mysql-5.7.17.tar\r"}
expect " ~]#"      {send "yum -y install mysql-community*\r"}
expect " ~]#" {send "touch /123.1\r"} 
EOF
}

NH(){
expect << EOF
set timeout -1
spawn ssh $o
expect " ~]#"      {send "systemctl start mysqld\r"}
expect " ~]#" {send "touch /123.1\r"}
EOF


}

TH(){
expect << EOF
set timeout -1
spawn ssh $o
expect " ~]#"      {send "sed -i '4askip-grant-tables'  /etc/my.cnf\r"}
expect " ~]#" {send "systemctl restart mysqld\r"}
expect " ~]#" {send "mysql\r"}
expect "mysql> " {send "update mysql.user set authentication_string=password('654321') where user='root' and host='localhost';\r"}
expect "mysql> " {send "flush privileges;\r"}
expect "mysql> " {send "quit\r"}
expect " ~]#"      {send "sed -i '5cvalidate_password_length=6' /etc/my.cnf\r"}
expect " ~]#"      {send "sed -i '5avalidate_password_policy=0' /etc/my.cnf\r"}
expect " ~]#" {send "systemctl restart mysqld\r"}
expect " ~]#" {send "systemctl enable mysqld\r"}
expect " ~]#" {send "mysql -uroot -p'654321'\r"}
expect "mysql> " {send "alter user root@localhost identified by '123456';\r"}
expect "mysql>" {send "quit\r"}
expect " ~]#" {send "systemctl enable mysqld\r"}
expect " ~]#" {send "touch /123.1\r"}
EOF

}






[ -d /DB ] || mkdir /DB
H="/root/.ssh/id_rsa.pub"
echo '构建环境中......'
sleep 2
yum repolist &> /dev/null && [ $? != 0 ]&&echo '未检测到yum源，即将退出'&&sleep 1 &&exit 3
rpm -q nmap &> /dev/null

if [ $? -gt  0 ];then
read -p '检测出未安装nmap依赖工具，是否安装（y/n）' tar

if [ $tar == y ];then
yum -y install nmap
[ $? != 0 ]&&echo '本地没有nmap相关包，即将退出'&&sleep 1&&exit 4
else
echo '已取消安装nmap，脚本自动退出'
sleep 1.5
exit 2
fi

fi

rpm -q expect &> /dev/null

if [ $? -gt  0 ];then
read -p '检测出未安装expect依赖工具，是否安装（y/n）' ture

if [ $ture == y ];then
yum -y install expect
[ $? != 0 ]&&echo '本地没有expect相关包，即将退出'&&sleep 1&&exit 4
else
echo '已取消安装expect，脚本自动退出'
sleep 1.5
exit 2
fi

fi
sed -i -n '$d' /DB/mun &>/dev/null
sed -i -n '$d' /DB/ip &>/dev/null
[ -f $H ] || R



read -p '是否需要创建虚拟机？ （yes/no）' wd

if [ $wd == yes ];then
read -p '您需要创建几台虚拟机？' gn
for hgf  in `seq $gn`
do
read -p "请输入您想要创建虚拟机${hgf}的编号 必须是数字！" nhb
[ $nhb -le 9 ]&& echo 0$nhb >> /DB/mun
echo $nhb >> /DB/mun 
done

for we in `seq $gn`
do
read -p "请输入您要为第$we 台虚拟机配置的ip地址192.168.4." bv
echo $bv  >> /DB/ip 
done

for qf in `cat /DB/mun`
do
sleep 1
expect << EOF
set timeout -1
spawn  clone-vm7
expect "Enter VM number:"   {send "${qf}\r"}
expect " ~]#" {send "echo 23\r"}
EOF
virsh start rh7_node$qf
done
sleep 17
for fk in `seq $gn`
do
expect << EOF
set timeout -1
spawn  virsh console rh7_node`sed -n ${fk}p /DB/mun`
expect "rh7_node"   {send "\r"}
expect "localhost login:"   {send "root\r"}
expect "：" {send "123456\r"}
expect "localhost ~]#" {send "nmcli connection modify eth0 ipv4.method manual ipv4.addresses 192.168.4.`sed -n ${fk}p /DB/ip`/24 connection.autoconnect yes\r"}
expect "localhost ~]#" {send "nmcli connection up eth0\r"}
expect "localhost ~]#" {send "hostname `sed -n ${fk}p /DB/mun`\r"}
expect "localhost ~]#" {send "echo `sed -n ${fk}p /DB/mun` > /etc/hostname\r"}
expect "localhost ~]#" {send "poweroff\r"}
expect "localhost ~]#" {send "poweroff\r"}
EOF


done

for h4 in `cat /DB/mun`
do
virsh start rh7_node$h4
done


sed -i -n $d /DB/mun &>/dev/null
sed -i -n $d /DB/ip &>/dev/null
fi



sed -i -n '$d' /DB/sqlip.txt &>/dev/null
echo '环境构建完成'&&sleep 1
read -p '请输入您要构建mysql数据库的数量' method
for i in `seq $method`

do
read -p "请输入您要构建mysql ${i}数据库的ip地址"  A[$i]
echo ${A[$i]}  >> /DB/sqlip.txt
done
read -p '请输入本地mysql服务安装包（绝对路径目录/结尾）'   B
systemctl start sshd
for o in `cat /DB/sqlip.txt`
do
ping -c 2 $o &> /dev/null
[ $? -gt 0 ]&& echo 主机${o}无法建立网络连接 &&continue&&sleep 1
echo "正在主机${o}进行安装数据库服务"&&sleep 1
G=`nmap -n -A $o |awk '/OpenSSH/{print $3}'`
[ $G != ssh ]&&echo 主机${o}没有开启sshd服务&&continue &&sleep 1
M
scp -r ${B}  ${o}:/

Y
NH
TH
done
sed -i -n '$d' /DB/sqlip.txt
