#!/bin/bash
#
[ -e /etc/rc.d/init.d/functions ] && . /etc/rc.d/init.d/functions 
function check_install_packet() {
  for i in httpd tcl tcl-devel libart_lgpl libart_lgpl-devel libtool-ltdl libtool-ltdl-devel expect openssl-devel cyrus* db*-devel; do
   rpm -qa | grep $i >/dev/null 2>&1
   [ $? -eq 0 ] && echo "$i was installed" || {
     echo "$i not is install" 
     yum install -y $i >/dev/null 2>&1
     [ $? -eq 0 ] && action "$i is install" /bin/ture || action "$i is install" /bin/false
   }  
 done
   if [ `yum grouplist Development Tools | wc -l` -ne 0 -a `yum grouplist Server Platform Development | wc -l` -ne 0 ]; then
     echo "the Development packets group was installed"
   else 
     echo "the Development packets group not is install"
     yum groupinstall -y "Development Tools" "Server Platform Development" >/dev/null 2>&1
     [ $? -eq 0 ] || action "the Development Tools packet install" /bin/ture || action "the Development Tools packet install" /bin/false
   fi   
   for j in tree nmap sysstat lrzsz dos2unix telnet; do 
     rpm -qa | grep $j >/dev/null 2>&1
     [ $? -eq 0 ] && echo "$j was install" || {
      echo "$j not is install"
      yum install -y $i >/dev/null 2>&1
      [ $? -eq 0 ] && action "$j is install" /bin/ture || action "$j is install" /bin/false
     }
   done
     /etc/init.d/mysqld start >/dev/null 2>&1
     [ $? -eq 0 ] && echo "mysql was installed" || echo "mysql is not install" 
     /etc/init.d/postfix start >/dev/null 2>&1
     [ $? -eq 0 ] && echo "posfix was installed" || echo "postfix is not install"     
}
function Main(){
  check_install_packet  
}
Main
