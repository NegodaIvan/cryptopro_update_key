#! /bin/bash
# Скрипт выполняет востановление рабочей версии КриптоПро.
#


if [ -e /etc/opt/cprocsp_36_backup ] ;
then
rm -rf /etc/opt/cprocsp/*
cp -rf /etc/opt/cprocsp_36_backup/* /etc/opt/cprocsp/
chown cpro:cpro /etc/opt/cprocsp/ -R
else
echo "cprocsp_36_backup not found"
fi

if [ -e /var/opt/cprocsp_36_backup ] ;
then
rm -rf /var/opt/cprocsp/*
cp -rf /var/opt/cprocsp_36_backup/* /var/opt/cprocsp/
chown cpro.cpro /var/opt/cprocsp -R
chmod 755 /var/opt/cprocsp -R
else
echo "/var/opt/cprocsp_36_backup not found"
fi

if [ -e /opt/cprocsp_36_backup ] ;
then
rm -rf /opt/cprocsp/*
cp -rf /opt/cprocsp_36_backup/* /opt/cprocsp/
else
echo "/opt/cprocsp_36_backup not found"
fi


if [ -f /etc/hosts_36_backup ] ;
then
cp -rf /etc/hosts_36_backup /etc/hosts
rm -f /etc/hosts_36_backup
else
echo "/etc/hosts_36_backup not found"
fi

if [ -f /etc/sysconfig/iptables_36_backup ];
    then
cp -rf /etc/sysconfig/iptables_36_backup /etc/sysconfig/iptables
rm -f /etc/sysconfig/iptables_36_backup
else echo "/etc/sysconfig/iptable_36_backup не найден"
fi

if [ -f /etc/iptables.rules_36_backup ];
    then
cp -rf /etc/iptables.rules_36_backup /etc/iptables.rules
rm -f /etc/iptables.rules_36_backup
iptables-restore < /etc/iptables.rules 2>&1 > /dev/null
else echo "/etc/iptables.rules не найден"
fi

if [ -f /etc/init.d/iptables ] ;
then
/etc/init.d/iptables restart 2>&1 > /dev/null
else
service iptables restart 2>&1 > /dev/null
fi

rm -f /var/opt/cprocsp/tmp/*
rm -f /var/opt/cprocsp/tmp/.*

pathstun=`dirname $(find /etc/ |grep -m 1 rc.stunnel)`
$pathstun/rc.stunnel stop
for i in `ps afx |grep stunnel_ |grep -v grep|awk {'print $1'}`;
do kill -9 $i;
done
$pathstun/rc.stunnel start
