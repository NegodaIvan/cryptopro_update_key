#!/bin/bash
#  Скрипт  выполняет обновление сертификатов КриптоПро версий 3.6 4.0
# перед обновлением создается резервная копия данных.
# восстановление из бакапов выполняется в скрипте backtobackup.sh
DIRROOT=$(cd $(dirname $0) && pwd)

check_cmd ()
{
sh -c "$cmd"
out=$?
if [ $out == 0 ] ;
then echo "$cmd - ok"
else
echo "$cmd not work"
exit
fi
}

if [ -f /etc/opt/cprocsp/ready ] ; then
echo This is PTK is ready
exit 1
fi

cd `dirname $0`
LIST=`ls -1 *.tar`
for file in $LIST;do
    tar -xf $file
done
rm -rf *.tar

mydate=`date +%Y%m%d`
#Делаем бэкапы
#
mkdir /etc/opt/cprocsp_36_$mydate
mkdir /var/opt/cprocsp_36_$mydate
mkdir /opt/cprocsp_36_$mydate


cp -rf /etc/opt/cprocsp/* /etc/opt/cprocsp_36_$mydate
cp -rf /var/opt/cprocsp/* /var/opt/cprocsp_36_$mydate
cp -rf /opt/cprocsp/* /opt/cprocsp_36_$mydate

if [ -f /etc/hosts_36_backup ] ; then
echo backup not rewriteble
else
mkdir /etc/opt/cprocsp_36_backup
mkdir /var/opt/cprocsp_36_backup
mkdir /opt/cprocsp_36_backup

cp -rf /etc/opt/cprocsp/* /etc/opt/cprocsp_36_backup
cp -rf /var/opt/cprocsp/* /var/opt/cprocsp_36_backup
cp -rf /opt/cprocsp/* /opt/cprocsp_36_backup
cp -rf /etc/hosts /etc/hosts_36_backup
    if [ -f /etc/sysconfig/iptables ]; then
    cp -rf /etc/sysconfig/iptables /etc/sysconfig/iptables_36_backup
    else
    echo "/etc/sysconfig/iptable не найден"
    fi

    if [ -f /etc/iptables.rules ]; then
    cp -rf /etc/iptables.rules /etc/iptables.rules_36_backup
    else
    echo "/etc/iptables.rules не найден"
    fi
fi

cp -rf /etc/hosts /etc/hosts_bk_$mydate
cp -rf /etc/opt/cprocsp/stunnel_client.conf /etc/opt/cprocsp/stunnel_client.conf_bk_$mydate
cp -rf /etc/opt/cprocsp/stunnel_server.conf /etc/opt/cprocsp/stunnel_server.conf_bk_$mydate

#Нюхаем цпро и задаём переменные


which rpm  > /dev/null
irpm=$?
which apt-get  > /dev/null
idpkg=$?
if [[ $irpm == 0   && $idpkg == 1 ]] ;
then
pktmgr="rpm -qa"
elif [[ $idpkg == 0 ]];
then
pktmgr="dpkg -l"
else
echo "Неизвестный менеджер пакетов"
fi

#if [ `dpkg -l | grep cprocsp-base  |grep 4.0` || `rpm -qa | grep cprocsp-base  |grep 4.0` ] ;
if [[ `$pktmgr | grep cprocsp-base |grep 4.0` ]] ;
then
mservportP=mmask3:7461
mservportO=mmask3:7761
rservport=rmask3:7462
hservport=hmask3:7461
certnew=certnew_4.cer
ipthostm=mmask3
ipthostr=rmask3
ipthosth=hmask3
cproV=4
#elif [ `dpkg -l | grep cprocsp-base  |grep 3.6` || `rpm -qa | grep cprocsp-base  |grep 3.6` ] ;
elif [[ `$pktmgr | grep cprocsp-base |grep 3.6` ]] ;
then
mservportP=mmask2:7451
mservportO=mmask2:7751
rservport=rmask2:7452
hservport=hmask2:7451
certnew=certnew2.cer
ipthostm=mmask2
ipthostr=rmask2
ipthosth=hmask2
cproV=3
elif [ -f /etc/opt/cprocsp/license.ini ]
then
cat /etc/opt/cprocsp/license.ini |grep "DU36C" | grep -v '#'
cprtmp=$?
    if [ $cprtmp == 0 ] ;
    then
mservportP=mmask2:7451
mservportO=mmask2:7751
rservport=rmask2:7452
hservport=hmask2:7451
certnew=certnew2.cer
ipthostm=mmask2
ipthostr=rmask2
ipthosth=hmask2
cproV=3
    else
mservportP=mmask3:7461
mservportO=mmask3:7761
rservport=rmask3:7462
hservport=hmask3:7461
certnew=certnew_4.cer
ipthostm=mmask3
ipthostr=rmask3
ipthosth=hmask3
cproV=4
    fi
else
echo cpro is unknown
exit
fi

#Стопим крипто-про
#pathstun=`dirname $(find /etc/rc.d |grep -m 1 rc.stunnel)`
cmd="dirname $(find /etc/ |grep -v "backup" |grep -v "_" |grep -m 1 rc.stunnel)"
check_cmd
#pathstun=`dirname $(find /etc/ |grep -v "backup" |grep -m 1 rc.stunnel)`
pathstun=`dirname $(find /etc/ |grep -v "backup" |grep -v "_" |grep -m 1 rc.stunnel)`
$pathstun/rc.stunnel stop
for i in `ps afx |grep stunnel_ |grep -v grep |awk {'print $1'}`;
do kill -9 $i;
done

#Удаляем контейнеры и сертификаты

cmd="dirname $(find /opt/cprocsp/bin |grep -m 1 certmgr)"
check_cmd
certmgr=`dirname $(find /opt/cprocsp/bin |grep -m 1 certmgr)`
su - cpro -c "$certmgr/certmgr -delete -all -cert -store umy"
su - cpro -c "$certmgr/certmgr -delete -all -cert -store trustedusers"
su - cpro -c "$certmgr/certmgr -delete -all -cert -store root"
su - cpro -c "$certmgr/certmgr -delete -crl -store CA"
$certmgr/certmgr -delete -cert -all -store root
$certmgr/certmgr -delete -cert -all -store trustedusers

rm -rf /var/opt/cprocsp/users/cpro/stores/*
rm -rf /var/opt/cprocsp/users/cpro/local.ini
rm -rf /var/opt/cprocsp/users/root/stores/*
rm -rf /var/opt/cprocsp/users/root/local.ini
rm -rf /var/opt/cprocsp/users/stores/*
rm -rf /var/opt/cprocsp/keys/cpro/*
rm -rf /var/opt/cprocsp/keys/root/*


if [ -f /etc/hostname ]; then
    if [ `cat /etc/hostname |grep -v localhost` ];
    then
myhostname=`cat /etc/hostname | awk -F- {'print $2'}`
    elif [ -f /etc/sysconfig/network ] ; then
    myhostname=`cat /etc/sysconfig/network |grep HOSTNAME | awk -F- {'print $2'}`
    else
    echo "hostname not found"
    exit 1
    fi
elif [ -f /etc/sysconfig/network ] ; then
myhostname=`cat /etc/sysconfig/network |grep HOSTNAME | awk -F- {'print $2'}`
else
echo "hostname not found"
exit 1
fi
echo $myhostname
############ Сделать првоерку-сравнения хоста из конфига с хостом из контейнера

cmd="dirname $(find $DIRROOT |grep -m 1 $certnew)"
check_cmd
certpath=`dirname $(find $DIRROOT |grep -m 1 $certnew)`

cmd="ls -1 $certpath |grep -v .tar |grep 000"
check_cmd
mycont=`ls -1 $certpath/ |grep -v .tar |grep 000`

########## Устанавливаем контейнеры и сертификаты ##########
cp -rf $certpath/$mycont  /var/opt/cprocsp/keys/cpro/
chown cpro:cpro /var/opt/cprocsp/keys/cpro/*.000 -R
chown cpro:cpro /etc/opt/cprocsp -R
chown cpro:cpro /var/opt/cprocsp/ -R
chmod 755 /var/opt/cprocsp/ -R
chmod 755 /etc/opt/cprocsp -R


#cmd="ls  /var/opt/cprocsp/keys/cpro/ |grep -m 1 $myhostname |awk -F"." {'print \$1'}"
#check_cmd
cprohost=`ls  /var/opt/cprocsp/keys/cpro/ |grep -m 1 000 |awk -F"." {'print $1'}`


echo -e "o\n" |$certmgr/certmgr -inst -store root -file $certpath/$certnew

su - cpro -c "'$certmgr/certmgr' -inst -cert -store uMy -cont '\\\.\HDIMAGE\'$cprohost'\\\'"
su - cpro -c "'$certmgr/certmgr' -export -cert -cont '\\\.\HDIMAGE\'$cprohost'\\\' -dest /etc/opt/cprocsp/$cprohost.cer"
su - cpro -c "'$certmgr/certmgr' -inst -cert -store TrustedUsers -file '$certpath/$ipthostm.cer'"
su - cpro -c "'$certmgr/certmgr' -inst -cert -store TrustedUsers -file '$certpath/$ipthostr.cer'"
su - cpro -c "'$certmgr/certmgr' -inst -cert -store TrustedUsers -file '$certpath/$ipthosth.cer'"

cp -rf /var/opt/cprocsp/users/cpro/stores/my.sto /var/opt/cprocsp/users/stores/ 2>&1 > /dev/null
cp -rf /var/opt/cprocsp/users/cpro/stores/trustedusers.sto /var/opt/cprocsp/users/stores/ 2>&1 > /dev/null
cp -rf /var/opt/cprocsp/users/root/stores/root.sto /var/opt/cprocsp/users/stores/ 2>&1 > /dev/null


############## Если цпро4, меняем бинарник, добавляем crl
if [ $cproV == 4 ] ;
then
#cmd=ls -1 /opt/cprocsp/sbin/
#check_cmd
#threadpath=`dirname $(find /opt/cprocsp/ |grep -v "\." |grep -v "\-" |grep -v "backup" |grep -v "bk" |grep -v "old"  |grep -m 1 stunnel_thread)`
if [ `ls -1 /dev/ |grep mmcblk0p3` ] ;
#isdpp=$?
#if [ $isdpp == 0 ] ;
then
cp -rf /etc/opt/cprocsp/rc.stunnel /etc/opt/cprocsp/rc.stunnel_36_backup
sed 's/cprocsp36/cprocsp/g' /etc/opt/cprocsp/rc.stunnel_36_backup  > /etc/opt/cprocsp/rc.stunnel
else
threadarch=`ls -1 /opt/cprocsp/sbin/`
echo $threadarch
threadpath=/opt/cprocsp/sbin/"$threadarch"
echo "stunnel_thread_path=$threadpath"
mv "$threadpath"/stunnel_thread "$threadpath"/stunnel_thread_remask_36
cp -f $DIRROOT/stunnel_thread "$threadpath"/stunnel_thread
########## Устанавливаем и копируем список отозванных
fi
su - cpro -c "'$certmgr/certmgr' -inst -crl -store mCa -file '$certpath'/certcrl.crl"
cp -rf /var/opt/cprocsp/users/cpro/stores/ca.sto /var/opt/cprocsp/users/stores/ 2>&1 > /dev/null
fi

chown cpro:cpro /var/opt/cprocsp/ -R
chmod 755 /var/opt/cprocsp/ -R

######## Меняем хосты в /etc/hosts/ /etc/opt/cprocsp/stunnel_* ############
cp -rf /etc/hosts /etc/hosts_bk_ant
cp -rf /etc/opt/cprocsp/stunnel_client.conf /etc/opt/cprocsp/stunnel_client.conf_bk_ant
cp -rf /etc/opt/cprocsp/stunnel_server.conf /etc/opt/cprocsp/stunnel_server.conf_bk_ant

#cmd="cat /etc/opt/cprocsp/stunnel_client.conf_bk_ant |grep .cer |grep -v '#' |awk -F/ {'print \$5'}"
#check_cmd
oldcprohost=`cat /etc/opt/cprocsp/stunnel_client.conf_bk_ant |grep .cer |grep -v '#' |awk -F/ {'print $5'}`
sed -r -e '
s/=mask:7741/'=$mservportO'/g
s/=mask:7441/'=$mservportP'/g
s/=mdm:7441/'=$mservportP'/g
s/=rmask:7442/'=$rservport'/g
s/=hmask:7441/'=$hservport'/g
s/=mcomm:7741/'=$mservportO'/g
s/=mcomm:7441/'=$mservportP'/g
s/=rcomm:7442/'=$rservport'/g
s/=hcomm:7441/'=$hservport'/g


s/= mask:7741/'=$mservportO'/g
s/= mask:7441/'=$mservportP'/g
s/= mdm:7441/'=$mservportP'/g
s/= rmask:7442/'=$rservport'/g
s/= hmask:7441/'=$hservport'/g
s/= mcomm:7741/'=$mservportO'/g
s/= mcomm:7441/'=$mservportP'/g
s/= rcomm:7442/'=$rservport'/g
s/= hcomm:7441/'=$hservport'/g

s/'$oldcprohost'/'$cprohost.cer'/g
' /etc/opt/cprocsp/stunnel_client.conf_bk_ant > /etc/opt/cprocsp/stunnel_client.conf

sed 's/'$oldcprohost'/'$cprohost.cer'/g' /etc/opt/cprocsp/stunnel_server.conf_bk_ant > /etc/opt/cprocsp/stunnel_server.conf



#if [ `grep mmask3 /etc/hosts` ];
#then echo mmask3 has been already
if [ `grep $ipthostm /etc/hosts` ];
then echo $ipthostm has been already
else


####### заменяем хосты в iptables
if [ -f /etc/sysconfig/iptables ]; then
    cp -rf /etc/sysconfig/iptables /etc/sysconfig/iptables_bk_ant
    cp -rf /etc/sysconfig/iptables /etc/sysconfig/iptables_bk_$mydate
    sed -r -e '
    s/ mask / '$ipthostm' /g
    s/ mdm / '$ipthostm' /g
    s/ hmask / '$ipthosth' /g
    s/ rmask / '$ipthostr' /g

    ' /etc/sysconfig/iptables_bk_ant > /etc/sysconfig/iptables
iptables-restore /etc/sysconfig/iptables 2>&1 > /dev/null
else
echo "/etc/sysconfig/iptable не найден"
fi
if [ -f /etc/iptables.rules ]; then
    cp -rf /etc/iptables.rules /etc/iptables.rules_bk_ant
    cp -rf /etc/iptables.rules /etc/iptables.rules_bk_$mydate
    sed -r -e '
    s/ mask / '$ipthostm' /g
    s/ mdm / '$ipthostm' /g
    s/ hmask / '$ipthosth' /g
    s/ rmask / '$ipthostr' /g

    ' /etc/iptables.rules_bk_ant > /etc/iptables.rules
iptables-restore < /etc/iptables.rules 2>&1 > /dev/null
else
    echo "/etc/iptables.rules не найден"
fi

if [[ -f /etc/init.d/iptables ]] ;
then
/etc/init.d/iptables restart 2>&1 > /dev/null
fi
service iptables restart 2>&1 > /dev/null

### Запускаем cpro
$pathstun/rc.stunnel start 2>&1 > /dev/null


## Проверяем, дипп это или нет, если дипп, то делаем операции - чисто для диппов
#mount /dev/mmcblk0p3 /mnt/flash
if [ `ls -1 /dev/ |grep mmcblk0p3` ] ;
#isdpp=$?
#if [ $isdpp == 0 ] ;
then

### Рестартуем iptables
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -F INPUT
iptables -F FORWARD
iptables -F OUTPUT
iptables -t nat -F POSTROUTING
iptables -t nat -F PREROUTING
iptables -t nat -F OUTPUT
iptables -t nat -F INPUT
. /etc/sysconfig/iptables
iptables -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
iptables -P INPUT DROP
iptables -A INPUT -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT
iptables -P FORWARD DROP


############ копируем на флешку, если всё прошло

#echo $ipthostm
#touch $DIRROOT/nc2.log
#nc $ipthostm 7440 > $DIRROOT/nc2.log &
#sleep 5
#tmpnc=`cat $DIRROOT/nc2.log |awk {'print $2'}`
#echo $tmpnc
#if [ `echo $tmpnc |grep ready` ];
#then
#rm -rf /mnt/flash/var/opt/cprocsp
#cp -rf /var/opt/cprocsp /mnt/flash/var/opt/
#cp -rf /var/opt/cprocsp_36_backup /mnt/flash/var/opt/
#chown cpro.cpro /mnt/flash/var/opt/cprocsp -R
#chmod 755 /mnt/flash/var/opt/cprocsp -R
#chown cpro.cpro /mnt/flash/var/opt/cprocsp_36_backup -R
#chmod 755 /mnt/flash/var/opt/cprocsp_36_backup -R

#rm -rf /mnt/flash/etc/opt/cprocsp
#cp -rf /etc/opt/cprocsp /mnt/flash/etc/opt/
#cp -rf /etc/opt/cprocsp_36_backup /mnt/flash/etc/opt/
#chown cpro:cpro /mnt/flash/etc/opt/cprocsp/ -R
#chown cpro:cpro /mnt/flash/etc/opt/cprocsp_36_backup/ -R

#cp -rf /etc/hosts /mnt/flash/etc/
#cp -rf /etc/hosts_36_backup /mnt/flash/etc/

#cp -rf /etc/sysconfig/iptables /mnt/flash/etc/sysconfig/
#cp -rf /etc/sysconfig/iptables_36_backup /mnt/flash/etc/sysconfig/

#rm -f /mnt/flash/var/opt/cprocsp/tmp/*
#rm -f /mnt/flash/var/opt/cprocsp/tmp/.*

#else echo cpro is not work;
#fi
#umount /mnt/flash
#else echo "this is not dpp"
#fi
