#! /bin/bash

#Остановка скрипта при вознкиновение ошибки
set -e

source ./show_menu.sh

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

function sync_input_handler {
    sync_select_device_message
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

while true
do
    sync_input_handler
done