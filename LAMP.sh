#!/bin/bash
#
install_dir="/usr/local/src"
apr="/usr/local/apr"
aprutil="/usr/local/apr-utill"
apache="/usr/local/apache"
php="/usr/local/php"
cmake="/usr/local/cmake"
mysql="/usr/local/mysql"
datadir="/mydata/data"
aprurl="http://apache.fayea.com/apr/apr-1.5.2.tar.gz"
aprutilurl="http://apache.fayea.com//apr/apr-util-1.5.4.tar.gz"
apacheurl="http://archive.apache.org/dist/httpd/httpd-2.4.18.tar.gz"
cmakeurl="http://www.cmake.org/files/v2.8/cmake-2.8.10.2.tar.gz"
mysqlurl="http://cdn.mysql.com/archives/mysql-5.5/mysql-5.5.28.tar.gz"
phpurl="http://ftp.ntu.edu.tw/php/distributions/php-5.6.9.tar.gz"
downFile() {
  wget --no-check-certificate "$1" -O "$2" 2>&1 | stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ {print substr($0,63,3)}' | whiptail --gauge "$3" 6 80 0 && clear
}
install_apache_check() {
  rpm -q httpd &> /dev/null
  if [ $? -eq 0 ]; then
    local HTTP = $(rpm -qa | grep httpd) &> /dev/null
    for j in ${HTTP[*]}; do
      rpm -e --nodeps $j &> /dev/null
    done
  fi
  rpm -q gcc &> /dev/null
  [ $? -eq 0 ] || yum install -y gcc &> /dev/null  
  rpm -q pcre-devel opnessl-devel &> /dev/null  
  [ $? -eq 0 ] || yum install -y pcre-devel openssl-devel &> /dev/null 
}
install_php_check() {
  rpm -q php &> /dev/null
  if [ $? -eq 0 ]; then 
    local PHP = $(rpm -q php) &> /dev/null
    for i in ${PHP[*]}; do
      rpm -e --nodeps $i &> /dev/null
    done
  fi
  rpm -q gcc-c++ &> /dev/null
  [ $? -eq 0 ] || yum install -y gcc-c++ &> /dev/null
  rpm -q libxml2-devel bzip2-devel libmcrypt libmcrypt-devel libmcrypt libmcrypt-devel mhash mhash-devel &> /dev/null  
  [ $? -eq 0 ] || yum install -y libxml2-devel bzip2-devel libmcrypt libmcrypt-devel libmcrypt libmcrypt-devel mhash mhash-devel &> /dev/null
}
install_mysql_check() {
  rpm -q mysql &> /dev/null
  if [ $? -eq 0 ]; then
    local Mysql=$(rpm -q mysql) 
    for i in ${Mysql[*]}; do
      rpm -e --nodeps $i &> /dev/null
    done
  fi 
    rpm -q gcc-c++ &> /dev/null
    [ $? -eq 0 ] || yum install -y gcc-c++ &> /dev/null
    rpm -q ncurses-devel openssl-devel &> /dev/null
    [ $? -eq 0 ] || yum install -y ncurses-devel openssl-devel &> /dev/null 
}
apr()
{ 
  [ -d $apr ] || mkdir $apr &> /dev/null
  if [ -e $install_dir/apr-1.5.2.tar.gz ]; then
    cd $install_dir
  else
    cd $install_dir
    downFile $aprurl "apr-1.5.2.tar.gz" "DownLoad apr-1.5.2"
  fi
  tar xf apr-1.5.2.tar.gz 
  cd apr-1.5.2
  sed -i 's@$RM "$cfgfile"@#$RM "$cfgfile"@' configure
  ./configure --prefix=/usr/local/apr &> /dev/null
   make &> /dev/null && make install &> /dev/null
 }
apr_util() 
{
  [ -d $aprutil ] || mkidr $aprutil &> /dev/null
  if [ -e $install_dir/apr-util-1.5.4.tar.gz ]; then
    cd $install_dir
  else
    cd $install_dir
    downFile $aprutilurl "apr-util-1.5.4.tar.gz" "DownLoad apr-util-1.5.4"
  fi
  tar xf apr-util-1.5.4.tar.gz 
  cd apr-util-1.5.4
  ./configure --prefix=/usr/local/apr-util --with-apr=/usr/local/apr 
  make && make install 
}
apache()
{
  [ -d $apache ] || mkdir $apache
  if [ -e $install_dir/httpd-2.4.18.tar.gz ];  then 
    cd $install_dir
  else 
    cd $install_dir
    downFile $apacheurl "httpd-2.4.18.tar.gz" "Download httpd-2.4.18"
  fi
    tar xf httpd-2.4.18.tar.gz 
    cd httpd-2.4.18
    ./configure --prefix=/usr/local/apache --sysconfdir=/etc/httpd --enable-so --enable-ssl --enable-cgi --enable-rewrite --with-zlib --with-proc --with-apr=/usr/local/apr --with-apr-util=/usr/local/apr-util --enable-modules=all --enable-mpms-shared=all --with-mpm=event
  make && make install
  sed -i 's@#ServerName .*@ServerName localhost:80@' /etc/httpd/httpd.conf
  if [ ! -e /etc/profile.d/http.sh ] ; then
    touch /etc/profile.d/http.sh &> /dev/null
    echo "export PATH=/usr/local/apache/bin:$PATH" > /etc/profile.d/httpd.sh 
  fi
  ln -s /usr/local/apache/include /usr/include/httpd 
  #echo "PidFile  \"/var/run/httpd.pid\"" >> /etc/httpd/httpd.conf 
  echo "MANPATH /usr/local/apache/man" >> /etc/man.config 
  [ -e /etc/init.d/httpd ] || cp -pv /root/shell/LAMP/templates/httpd  /etc/init.d/httpd 
  [ -x /etc/init.d/httpd ] || chmod +x /etc/init.d/httpd
  [ -e /var/run/httpd.pid ] || touch /var/run/httpd.pid
  service httpd start
  chkconfig httpd on
}
install_cmake(){
  sleep 5
  [ -d $cmake ]||mkdir $cmake
  if [ -e $install_dir/cmake-2.8.10.2.tar.gz ]; then
    cd $install_dir
  else
    cd $install_dir 
    downFile $cmakeurl "cmake-2.8.10.2.tar.gz" "DownLoad cmake-2.8.10.2"
  fi
    tar xf cmake-2.8.9.tar.gz
  cd cmake-2.8.9
  ./configure --prefix=$cmake 
  make 
  make install
  sleep 10
  if [ ! -e /etc/profile.d/cmake.sh ]; then
    touch /etc/profile.d/cmake.sh
    echo "export PATH=$PATH:/usr/local/cmake/bin" > /etc/profile.d/cmake.sh
    sleep 5
    . /etc/profile.d/cmake.sh
  else
    echo "export PATH=$PATH:/usr/local/cmake/bin" > /etc/profile.d/cmake.sh
    sleep 5
    . /etc/profile.d/cmake.sh
 fi
}
mysql()
{
  [ -d $mysql ] || mkdir $mysql
  id mysql &>/dev/null
  if [ $? -ne 0 ]; then
    groupadd -g 501 mysql
    useradd -g 501 -u 501 -s /sbin/nologin -M mysql
  fi 
  if [ ! -e $datadir ]; then 
    mkdir -pv $datadir
    chown -R mysql.mysql $datadir
  fi
  if [ -e $install_dir/mysql-5.5.28.tar.gz ]; then
    cd $install_dir
  else
    cd $install_dir
    downFile $mysqlurl "mysql-5.5.28.tar.gz" "DownLoad mysql-5.5.28"
  fi  
  tar xf mysql-5.5.28.tar.gz 
  cd mysql-5.5.28 
  cmake -DCMAKE_INSTALL_PREFIX=$mysql -DMYSQL_UNIX_ADDR=/usr/local/mysql/mysql.sock  -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_MEMORY_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DENABLED_LOCAL_INFILE=1 -DMYSQL_DATADIR=$datadir -DMYSQL_USER=mysql -DMYSQL_TCP_PORT=3306 
  make 
  make install
  sleep 10
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
  chown -R mysql.mysql $mysql
  chown -R mysql.mysql $datadir
}
init_mysql(){
  [ -e /etc/my.cnf ] && rm -rf /etc/my.cnf
  cp /root/shell/LAMP/templates/my.cnf /etc/my.cnf
  [ -e /etc/init.d/mysqld ] && rm -rf /etc/init.d/mysqld
  cp $mysql/support-files/mysql.server /etc/init.d/mysqld
  cd $mysql
  scripts/mysql_install_db --user=mysql --datadir=$datadir &> /dev/null
  chown mysql.mysql $datadir/*
  service mysqld start &> /dev/null
  chkconfig mysqld on
}
PHP(){
  [ -d $php ] || mkdir $php
  if [ -e $install_dir/php-5.6.9.tar.gz ]; then
    cd $install_dir
  else
    cd $install_dir
    downFile $phpurl "php-5.6.9.tar.gz" "DownLoad php-5.6.9" 
  fi 
  tar xf php-5.6.9.tar.gz 
  cd php-5.6.9 
  ./configure --prefix=/usr/local/php --with-mysql=mysqlnd --with-openssl --with-mysqli=mysqlnd --enable-mbstring --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --enable-sockets --enable-fpm --with-mcrypt --with-config-file-path=/etc --with-config-file-scan-dir=/etc/php.d 
  make && make install
}
configure_PHP(){
  cd $install_dir/php-5.6.9
  [ -e /etc/php.ini ] || cp php.ini-production /etc/php.ini
  [ -e /etc/rc.d/init.d/php-fpm ] || cp -pv $install_dir/php-5.6.9/sapi/fpm/init.d.php-fpm /etc/rc.d/init.d/php-fpm &> /dev/null
  [ -x  /etc/rc.d/init.d/php-fpm ] || chmod +x /etc/rc.d/init.d/php-fpm
  if [ -e  /etc/profile.d/php.sh ]; then
    echo "export PATH=$PATH:$php/bin" /etc/profile.d/php.sh &> /dev/null
    . /etc/profile.d/php.sh &> /dev/null
  else
    touch /etc/profile.d/php.sh
    echo "export PATH=$PATH:$php/bin" /etc/profile.d/php.sh &> /dev/null
    . /etc/profile.d/php.sh &> /dev/null
  fi 
  if [ ! -e /usr/local/php/etc/php-fpm.conf ]; then
    cp /usr/local/php/etc/php-fpm.conf /usr/local/php/etc/php-fpm.conf.bak &> /dev/null
    cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf &> /dev/null
  fi
    sed -i 's/;pid = .*/pid = run/php-fpm.pid/g' /usr/local/php/etc/php-fpm.conf
    sed -i 's/pm.max_children = .*/pm.max_children = 50/g' /usr/local/php/etc/php-fpm.conf
    sed -i 's/pm.start_servers = .*/pm.start_servers = 5/g' /usr/local/php/etc/php-fpm.conf
    sed -i 's/pm.min_spare_servers = .*/pm.min_spare_servers = 2/g' /usr/local/php/etc/php-fpm.conf
    sed -i 's/pm.max_spare_servers = .*/pm.max_spare_servers = 8/g' /usr/local/php/etc/php-fpm.conf
    service php-fpm restart
    chkconfig php-fpm on
}
 install_apache()
{
  install_apache_check
  apr
  apr_util
  apache
  InstallMainMenu
}
install_mysql()
{
  install_mysql_check
  install_cmake
  mysql
  init_mysql
  InstallMainMenu
}
install_PHP(){
  install_php_check
  PHP
  configure_PHP
  InstallMainMenu 
}
configure_LAMP()
{
  id apache &> /dev/null
  if [ $? -ne 0 ]; then
    groupadd -g 502 apache
    useradd -g 502 -u 502 -s /sbin/nologin -M apache
  fi 
  [ -d /www/root ] || mkdir -pv /www/root
  chown apache.apache /www/root/
  [ -e /www/root/index.php ] || touch /www/root/index.php
  chown apache.apache /www/root/*
  [ -d /www/log ] || mkdir /www/log
  chown apache.apache /www/log/
  if [ -e /etc/httpd/extra/httpd-vhosts.conf ]; then
    rm -rf /etc/httpd/extra/httpd-vhosts.conf
    cp -pv /root/shell/LAMP/templates/httpd-vhosts.conf /etc/httpd/extra/httpd-vhosts.conf
  else
    cp -pv /root/shell/LAMP/templates/httpd-vhosts.conf /etc/httpd/extra/httpd-vhosts.conf
  fi
  #if [ -e /usr/local/php/etc/php-fpm.conf ]; then
    #mv /usr/local/php/etc/php-fpm.conf /usr/local/php/etc/php-fpm.conf.bak
    #cp /root/shell/LAMP/templates/php-fpm.conf /usr/local/php/etc/php-fpm.conf
  #else
    #cp /root/shell/LAMP/templates/php-fpm.conf /usr/local/php/etc/php-fpm.conf
  #fi 
  service php-fpm restart
  service httpd restart
}  
InstallMainMenu(){
  OPTION=$(whiptail --title "Install Main Menu" --menu "please choice function menu option" 15 60 5\
  "1" "Install Apache Application" \
  "2" "Install Mysql Database" \
  "3" "Install PHP Application" \
  "4" "Configure LAMP Function" \
  "5" "Quit" 3>&1 1>&2 2>&3)
  status=$?
  if [ $status == "0" ]; then
    case $OPTION in
    1)
      echo "you choice was first menu:"
      install_apache
     ;;
    2)
      echo "you choice was second menu:"
      install_mysql 
     ;;
    3)
      echo "you choice was third menu:"
      install_PHP
     ;;
    4)
     echo "you choice was fourth menu:"
     configure_LAMP
     ;;
    5)
     Quit
     ;;
    esac
  else
    exit 4
  fi
}
InstallMainMenu
