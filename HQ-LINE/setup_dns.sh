#! /bin/bash

#Остановка скрипта при вознкиновение ошибки
set -e

FILE_PATH="/etc/bind/options.conf"
ENS_FILE_PATH="/etc/net/ifaces/ens18"

SW_MGMT="MGMT"
ADMIN_MAIN_INTERFACE="enp7s1"


echo_header() {
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    echo -e "${RED}$1${NC}"
    }

    echo_subheader() {
    WHITE='\033[0;37m'
    NC='\033[0m' # No Color
    echo -e "${WHITE}$1${NC}"
    }

function show_select_action_message {
    echo_header $'\n\n#>===================== Выберите устройство =====================<#\n'


    echo_subheader "   1. SRV1-HQ"
    echo_subheader "   2. SRV1-DT"
    echo_subheader "   3. SW-HQ"
    echo_subheader "   4. ADMIN-HQ"
    echo_subheader "   0. exit"


    echo_header $'\n#>=====================================================================<#\n'
}

function input_handler {
        show_select_action_message
        local choice
        read choice
        
        case "$choice" in 

            "1")
                setup_bind_srv1_hq
                return 1
                ;;

            "2")
                setup_bind_srv1_dt
                return 1
                ;;
            "3")
                setup_dns $SW_MGMT
                return 1
                ;;
            "4")
                setup_dns $ADMIN_MAIN_INTERFACE
                return 1
                ;;
            "0")
                exit 0
                ;;

        esac
}


setup_dns () {
    printf "search au.team\nnameserver 192.168.11.66\nnameserver 192.168.33.66\n" > /etc/net/ifaces/"$1"/resolv.conf
    systemctl restart network
}

while [[ -z "${device_name}" ]]
do
    input_handler
done

#Check file exist
if [[ -e "/etc/net/ifaces/enp7s1" ]]; then
    echo enp7s1 found
elif [[ -e $ENS_FILE_PATH ]]; then
    mv /etc/net/ifaces/ens18 /etc/net/ifaces/enp7s1
    echo rename ens18 to enp7s1
else echo "File ens18 not found"
    exit 0
fi

setup_bind_srv1_hq () {
    printf "nameserver 77.88.8.8" > /etc/resolv.conf
    apt-get update && apt-get install -y bind bind-utils

    sed -i "16s#.*#        listen-on { 127.0.0.1; 192.168.11.66; };#" $FILE_PATH
    sed -i "17s#.*#        listen-on-v6 { any; };#" $FILE_PATH
    sed -i "24s#.*#        forwarders { 77.88.8.8; };#" $FILE_PATH
    sed -i "30s#.*#        allow-query { 192.168.11.0/24; 192.168.33.0/24; };#" $FILE_PATH
    sed -i "31s#.*#        allow-transfer { 192.168.33.66; };#" $FILE_PATH

    systemctl enable --now bind

    printf "search au.team\nnameserver 192.168.11.66" > /etc/net/ifaces/enp7s1/resolv.conf

    systemctl restart network
    systemctl restart bind
    # systemctl enable --now bind
}

setup_bind_srv1_dt () {
    printf "nameserver 77.88.8.8" > /etc/resolv.conf
    apt-get update && apt-get install -y bind bind-utils

    sed -i "16s#.*#        listen-on { 127.0.0.1; 192.168.33.66; };#" $FILE_PATH
    sed -i "17s#.*#        listen-on-v6 { none; };#" $FILE_PATH
    sed -i "24s#.*#        forwarders { 77.88.8.8; };#" $FILE_PATH
    sed -i "30s#.*#        allow-query { 192.168.33.0/24; 192.168.11.0/24; };#" $FILE_PATH
    sed -i "31s#.*#        allow-transfer { none; };#" $FILE_PATH

    systemctl enable --now bind

    printf "search au.team\nnameserver 192.168.33.66\nnameserver 192.168.11.66" > /etc/net/ifaces/enp7s1/resolv.conf

    systemctl restart network
    # systemctl restart bind
    systemctl enable --now bind
}


