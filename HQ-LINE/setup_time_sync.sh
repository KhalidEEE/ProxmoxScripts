#! /bin/bash

#Остановка скрипта при вознкиновение ошибки
set -e

CHRONY_PATH="/etc/chrony.conf"

params_srv1_hq () {
    sed -i "3s/^/# /" $CHRONY_PATH
    sed -i "4i server ntp2.vniiftri.ru iburst prefer" $CHRONY_PATH
    sed -i "5i local stratum 5" $CHRONY_PATH
    sed -i "6i allow 192.168.11.0/24" $CHRONY_PATH
    sed -i "7i allow 192.168.33.0/24" $CHRONY_PATH
    sed -i "8i allow 10.10.10.0/30" $CHRONY_PATH
    systemctl restart chronyd
}

params_all () {
    sed -i "3i/^/# /" $CHRONY_PATH
    sed -i "4i server 192.168.11.66 iburst prefer" $CHRONY_PATH
    systemctl restart chronyd
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
    echo_header $'\n\n#>===================== Выберите устройство =====================<#\n'


    echo_subheader "   1. srv1-hq"
    echo_subheader "   2. ANY"
    echo_subheader "   0. exit"


    echo_header $'\n#>=====================================================================<#\n'
}

function input_handler {
    show_select_device_message
    local choice
    read choice
    
    case "$choice" in 

        "1")
            params_srv1_hq
            ;;

        "2")
            params_all
            ;;
        "0")
            exit 0
            ;;

    esac
}

while [[ -z "${device_name}" ]]
do
    input_handler
done