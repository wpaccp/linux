#!/bin/bash
#
[ -e /etc/rc.d/init.d/functions ] && . /etc/rc.d/init.d/functions
install_dir="/usr/local"
mysql="/usr/local/mysql"
datadir="/mydata/data"
function install_epel() {
  rpm -qa | grep epel >/dev/null 2>&1
  [ $? -ne 0 ] && rpm -ivh ~/postfix/files/epel-release-6-8.noarch.rpm
  ping -c 1 114.114.114.114
  yum repolist >/dev/null 2>&1 
  [ $? -eq 0 ] && action "epel was installed" /bin/true || exit 1
  for i in  httpd tcl tcl-devel libart_lgpl libart_lgpl-devel libtool-ltdl libtool-ltdl-devel expect openssl-devel cyrus* db*-devel; do
    rpm -qa | grep $i >/dev/null 2>&1
    [ $? -ne 0 ] && yum install -y $i || echo "$i was installed"
  done 
  [ `ps -C sendmail --no-heading | wc -l` -ne 0 ] && pkill sendmail || echo "sendmail service not running"
  [ `chkconfig --list sendmail | wc -l` -ne 0 ] && chkconfig sendmail off || echo "chkconfig sendmail not close"
  if [ `yum grouplist Development Tools | wc -l` -ne 0 -a `yum grouplist Server Platform Development | wc -l` -ne 0 ]; then
    yum groupinstall -y "Development Tools" "Server Platform Development" >/dev/null 2>&1
    [ $? -eq 0 ] || action "the Development Tools packet install" /bin/ture || action "the Development Tools packet install" /bin/false
  else
      echo "the packet was exists"  
  fi 
  rpm -q tree nmap sysstat lrzsz dos2unix telnet >/dev/null 2>&1
  [ $? -eq 0 ] || yum install tree nmap sysstat lrzsz dos2unix telnet -y    
}

function install_mysql()
{
  id mysql &>/dev/null
  if [ $? -ne 0 ]; then
    groupadd -r mysql
    useradd -g mysql -r -s /sbin/nologin -M -d /mydata/data mysql
  fi 
  [ -e $datadir ] || mkdir -pv $datadir  
  chown -R mysql:mysql $datadir
  cd $install_dir
  [ -e $install_dir/src/mysql-5.5.20-linux2.6-x86_64.tar.gz ] || {
    #wget $mysqlurl
    cp -pvr ~/postfix/files/mysql-5.5.20-linux2.6-x86_64.tar.gz $install_dir/src
  }
  tar xf src/mysql-5.5.20-linux2.6-x86_64.tar.gz -C $install_dir 
  ln -sv mysql-5.5.20-linux2.6-x86_64 mysql
  cd $mysql
  chown -R mysql:mysql .
  scripts/mysql_install_db --user=mysql --datadir=$datadir >/dev/null 2>&1
  chown -R root  .
  [ -e /etc/my.cnf ] || cp -pvr /usr/local/mysql/support-files/my-large.cnf /etc/my.cnf
  [ -e /etc/my.cnf.ori ] || cp -pvr /etc/my.cnf /etc/my.cnf.ori 
  [ `grep "thread_concurrency" /etc/my.cnf | wc -l` -ne 0 ] && sed -i 's@\(thread_concurrency =\) .*@\1 2@g' /etc/my.cnf
  [ `grep "datadir" /etc/my.cnf | wc -l` -eq 0 ] && sed -i '39a datadir = /mydata/data/' /etc/my.cnf
  [ `grep "/tmp/mysql.sock" /etc/my.cnf | wc -l` -ne 0 ] && sed -i '/mysql.sock/s@tmp@var/lib/mysql@' /etc/my.cnf    
  [ -e /etc/init.d/mysqld ] || cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
  [ -x /etc/init.d/mysqld ] || chmod +x /etc/init.d/mysqld 
  [ `grep "$mysql/man" /etc/man.config | wc -l` -eq 0 ] && sed -i '73a MANPATH                                      /usr/local/mysql/man' /etc/man.config
  [ -e /etc/ld.so.conf.d/mysql.conf ] || touch /etc/ld.so.conf.d/mysql.conf   
  [ `grep "$mysql/lib" /etc/ld.so.conf.d/mysql.conf | wc -l` -eq 0 ] && echo '$mysql/lib' > /etc/ld.so.conf.d/mysql.conf
  ldconfig
  if [ ! -e /etc/profile.d/mysql.sh ]; then
   touch /etc/profile.d/mysql.sh
   echo "export PATH=$PATH:/usr/local/mysql/bin" > /etc/profile.d/mysql.sh
   sleep 5
   . /etc/profile.d/mysql.sh &> /dev/null
 else
   echo "export PATH=$PATH:/usr/local/mysql/bin" > /etc/profile.d/mysql.sh
   sleep 5
   . /etc/profile.d/mysql.sh &> /dev/null
 fi
 [ `ps -C mysqld --no-heading | wc -l` -eq 0 ] && service mysqld start 
 [ `chkconfig --list mysqld | wc -l` -eq 0 ] && chkconfig mysqld on
 [ `mysql -e "select User,Password from mysql.user where Password='wpaccp'"| wc -l` -eq 0 ] && mysqladmin -uroot password 'wpaccp'
}
function install_postfix() {
  [ `ps -C saslauthd --no-heading | wc -l` -eq 0 ] && service saslauthd start 
  [ `chkconfig --list saslauthd | wc -l` -eq 0 ] && chkconfig saslauthd on
  id postfix >/dev/null 2>&1
  [ $? -eq 0 ] || {
  groupadd -g 2525 postfix
  useradd -g postfix -u 2525 -s /sbin/nologin -M postfix
  }
  id postdrop >/dev/null 2>&1 || {
  groupadd -g 2526 postdrop
  useradd -g postdrop -u 2526 -s /sbin/nologin -M postdrop
  }
  [ -e $install_dir/src/postfix-2.10.0.tar.gz ] || cp -pvr ~/postfix/files/postfix-2.10.0.tar.gz $install_dir/src
  cd $install_dir/src 
  tar xf postfix-2.10.0.tar.gz
  cd postfix-2.10.0
  make makefiles 'CCARGS=-DHAS_MYSQL -I/usr/local/mysql/include -DUSE_SASL_AUTH -DUSE_CYRUS_SASL -I/usr/include/sasl  -DUSE_TLS ' 'AUXLIBS=-L/usr/local/mysql/lib -lmysqlclient -lz -lm -L/usr/lib/sasl2 -lsasl2  -lssl -lcrypto'
  [ -e /etc/postfix/main.cf.ori ] || cp -pvr /etc/postfix/main.cf /etc/postfix/main.cf.ori 
  sed -i 's@#\(myhostname =\) .*@\1 mail.wp.com@' /etc/postfix/main.cf
  sed -i 's@#\(myorigin =\) .*@\1 wp.com@' /etc/postfix/main.cf
  sed -i 's@#\(mydomain =\) .*@\1 wp.com@' /etc/postfix/main.cf
  sed -i 's@#\(mydestination =\) .*@\1 $myhostname, localhost.$mydomain, localhost, $mydomain@' /etc/postfix/main.cf
  sed -i 's@#\(mynetworks =\) .*@\1 192.168.100.0/24, 127.0.0.0/8@' /etc/postfix/main.cf
  [ -e /etc/rc.d/init.d/postfix ] || cp -pvr ~/postfix/templates/postfix /etc/rc.d/init.d/postfix 
  [ -x /etc/rc.d/init.d/postfix ] || chmod +x /etc/rc.d/init.d/postfix 
  [ `chkconfig --list postfix | wc -l` -eq 0 ] && {
   	chkconfig --add postfix 
   	chkconfig postfix on 
  }	  
  [ `ps -C postfix --no-heading | wc -l` -eq 0 ] && service postfix start  
}
function Main() {
  install_epel
  install_mysql
  install_postfix
}
Main
 
