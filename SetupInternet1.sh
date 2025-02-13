#! /bin/bash

#Остановка скрипта при вознкиновение ошибки
set -e

ENS_FILE_PATH="/etc/net/ifaces/ens18"

device_name=""
device_ip_address=""
device_gateway=""


declare -A data_dict
data_dict["sw1-hq"]="192.168.11.82/29 192.168.11.81"
data_dict["sw2-hq"]="192.168.11.83/29 192.168.11.81"
data_dict["sw3-hq"]="192.168.11.84/29 192.168.11.81"
data_dict["admin-hq"]="192.168.11.85/29 192.168.11.81"
data_dict["srv1-hq"]="192.168.11.66/28 192.168.11.65"

echo_info() {
  GREEN='\033[0;32m'
  NC='\033[0m' # No Color
  echo -e "${GREEN}$1${NC}"
}

echo_header() {
  BLUE='\033[0;34m'
  NC='\033[0m' # No Color
  echo -e "${BLUE}$1${NC}"
}

echo_subheader() {
  CYAN='\033[0;36m'
  NC='\033[0m' # No Color
  echo -e "${CYAN}$1${NC}"
}

function show_select_device_message {
    echo_header $'\n\n#>===================== Выберите имя устройства =====================<#\n'

    echo_subheader "   1. SW1-HQ"
    echo_subheader "   2. SW2-HQ"
    echo_subheader "   3. SW3-HQ"
    echo_subheader "   4. ADMIN-HQ"
    echo_subheader "   5. SRV1-HQ"
    echo_subheader "   0. exit"


    echo_header $'\n#>=====================================================================<#\n'
}

function input_handler {
    show_select_device_message
    local choice
    read choice
    
    case "$choice" in 

        "1")
            device_name="sw1-hq"
            ;;

        "2")
            device_name="sw2-hq"
            ;;

        "3")
            device_name="sw3-hq"
            ;;

        "4")
            device_name="admin-hq"
            ;;

        "5")
            device_name="srv1-hq"
            ;;

        "0")
            exit 0
            ;;

    esac

    echo "Выбрано имя: $device_name"
}

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
    *)
        read input
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
        ovs-vsctl add-port SW2-HQ enp7s1 trunk=110,220,330
        ovs-vsctl add-port SW2-HQ enp7s2 trunk=110,220,330
        ovs-vsctl add-port SW2-HQ enp7s3 tag=220
        ovs-vsctl add-port SW2-HQ enp7s4 tag=110
        ;;

    sw3-hq)
        ovs-vsctl add-port SW3-HQ enp7s1 trunk=110,220,330
        ovs-vsctl add-port SW3-HQ enp7s2 trunk=110,220,330
        ovs-vsctl add-port SW3-HQ enp7s3 tag=330
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