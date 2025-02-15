#! /bin/bash

#Остановка скрипта при вознкиновение ошибки
set -e

FILE_PATH="/etc/bind/options.conf"
ENS_FILE_PATH="/etc/net/ifaces/ens18"


#Check file exist
if [[ -e "/etc/net/ifaces/enp7s1" ]]; then
    echo enp7s1 found
elif [[ -e $ENS_FILE_PATH ]]; then
    mv /etc/net/ifaces/ens18 /etc/net/ifaces/enp7s1
    echo rename ens18 to enp7s1
else echo "File ens18 not found"
    exit 0
fi

echo "nameserver 77.88.8.8" > /etc/resolv.conf
apt-get update && apt-get install -y bind bind-utils

sed -i "16s#.*#        listen-on { 127.0.0.1; 192.168.11.66; };#" $FILE_PATH
sed -i "17s#.*#        listen-on-v6 { any; };#" $FILE_PATH
sed -i "24s#.*#        forwarders { 77.88.8.8; };#" $FILE_PATH
sed -i "30s#.*#        allow-query { 192.168.11.0/24; 192.168.33.0/24; };#" $FILE_PATH
sed -i "31s#.*#        allow-transfer { 192.168.33.66; };#" $FILE_PATH

systemctl enable --now bind

cat <<EOF > /etc/net/ifaces/enp7s1/resolv.conf
  search au.team
  nameserver 192.168.11.66
EOF

systemctl restart network
systemctl restart bind