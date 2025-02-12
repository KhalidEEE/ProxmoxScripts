#! /bin/bash

#Остановка скрипта при вознкиновение ошибки
set -e

ENS_FILE_PATH="/etc/net/ifaces/ens18"

device_name="sw1-hq"
device_ip_address=""
device_gateway=""


declare -A data_dict
data_dict["sw1-hq"]="192.168.11.82/29 192.168.11.81"
data_dict["sw2-hq"]="192.168.11.83/29 192.168.11.81"
data_dict["sw3-hq"]="192.168.11.84/29 192.168.11.81"
data_dict["admin-hq"]="192.168.11.85/29 192.168.11.81"
data_dict["srv1-hq"]="192.168.11.66/28 192.168.11.65"

case $(hostname -f) in 

    "sw1-hq.au.team")
        device_name="sw1-hq"
        ;;

    "sw2-hq.au.team")
        device_name="sw2-hq"
        ;;

    "sw3-hq.au.team")
        device_name="sw3-hq"
        ;;

    "admin-hq.au.team")
        device_name="admin-hq"
        ;;

    "srv1-hq.au.team")
        device_name="srv1-hq"
        ;;

esac

read -r device_ip_address device_gateway <<< "${data_dict[$device_name]}"
echo "IP: $device_ip_address"
echo "Gateway: $device_gateway"

#Check file exist
if [[ -e $ENS_FILE_PATH ]]; then
    echo "File exist"
else echo "File ens18 not found"
    exit 0
fi

# Нужна проверка на наличие файла
# Rename ens & change params
mv /etc/net/ifaces/ens18 /etc/net/ifaces/enp7s1
sed -i "s/BOOTPROTO=dhcp/BOOTPROTO=static/g" /etc/net/ifaces/enp7s1/options

# Нужна проверка на наличие файла
mkdir /etc/net/ifaces/enp7s2
printf "TYPE=eth\nBOOTPROTO=static" >> /etc/net/ifaces/enp7s2/options

# Копируем парамтеры из enp7s2
if [[ $device_name == "sw1-hq" || $device_name == "sw3-hq" ]]; then
    cp -r /etc/net/ifaces/enp7s2 /etc/net/ifaces/enp7s3
elif [[ $device_name == "sw2-hq" ]]; then
    cp -r /etc/net/ifaces/enp7s2 /etc/net/ifaces/enp7s3 &&
    cp -r /etc/net/ifaces/enp7s2 /etc/net/ifaces/enp7s4
fi

systemctl restart network

ovs-vsctl add-br "${device_name^^}"

mkdir /etc/net/ifaces/MGMT
printf "TYPE=ovsport\nBOOTPROTO=static\nCONFIG_IPV4=yes\nBRIDGE=%s\nVID=330" "${device_name^^}" >> /etc/net/ifaces/MGMT/options

printf "%s" "${device_ip_address}" > /etc/net/ifaces/MGMT/ipv4address
printf "default via %s" "${device_gateway}" > /etc/net/ifaces/MGMT/ipv4route
sed -i "s/OVS_REMOVE=yes/OVS_REMOVE=no/g" /etc/net/ifaces/default/options
systemctl restart network

case $device_name in 

    sw1-hq)
        ovs-vsctl add-port SW1-HQ enp7s1 trunk=110,220,330
        ovs-vsctl add-port SW1-HQ enp7s2 trunk=110,220,330
        ovs-vsctl add-port SW1-HQ enp7s3 trunk=110,220,330
        ;;

    sw2-hq)
        ovs-vsctl add-port SW2-HQ ens19 trunk=110,220,330
        ovs-vsctl add-port SW2-HQ ens20 trunk=110,220,330
        ovs-vsctl add-port SW2-HQ ens21 tag=220
        ovs-vsctl add-port SW2-HQ ens22 tag=110
        ;;

    sw3-hq)
        ovs-vsctl add-port SW3-HQ ens19 trunk=110,220,330
        ovs-vsctl add-port SW3-HQ ens20 trunk=110,220,330
        ovs-vsctl add-port SW3-HQ ens21 tag=330
        ;;

    admin-hq)
        echo
        ;;

    srv1-hq)
        echo
        ;;

esac

modprobe 8021q
printf "8021q" >> /etc/modules