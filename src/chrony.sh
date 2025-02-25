#! /bin/bash

#Остановка скрипта при вознкиновение ошибки
set -e

chrony_path="/etc/chrony.conf"

function setup_srv1_hq() {
    apt-get update && apt-get install -y chrony

    cp -r $chrony_path $chrony_path.bak

    sed -i "3s/^/# /" $chrony_path
    sed -i "4i server ntp2.vniiftri.ru iburst prefer" $chrony_path
    sed -i "5i local stratum 5" $chrony_path
    sed -i "6i allow 192.168.11.0/24" $chrony_path
    sed -i "7i allow 192.168.33.0/24" $chrony_path
    sed -i "8i allow 10.10.10.0/30" $chrony_path
    systemctl restart chronyd

    timedatectl
}

function setup_all() {
    apt-get update && apt-get install -y chrony

    cp -r $chrony_path $chrony_path.bak

    sed -i "3s/^/# /" $chrony_path
    sed -i "4i server 192.168.11.66 iburst prefer" $chrony_path
    systemctl restart chronyd

    timedatectl
}

function rollback() {
    if [[ -e $chrony_path.bak ]]; then
        rm -rf $chrony_path
        mv $chrony_path.bak $chrony_path
    fi
}

function message_select_device() {
    local var=""
    while [ -z "${device}" ]; do
        printf "Выберите устройство:\n 1.SRV1-HQ\n 2.SW1-HQ, SW2-HQ, SRV1-DT, SRV2-DT, SRV3-DT\n 3.Rollback\n 0.Exit\n"
            read -r var
            if [[ ${var} == "1" ]]; then
                setup_srv1_hq && echo "Синхронизация настроена" || { echo "Ошибка при настройке синхронизации" && rollback; }
            elif [[ ${var} == "2" ]]; then
                setup_all && echo "Синхронизация настроена" || { echo "Ошибка при настройке синхронизации" && rollback; }
            elif [[ ${var} == "3" ]]; then rollback || echo "параметры восстановлены"
            elif [[ ${var} == "0" ]]; then exit
            fi
    done
}

function main() {
    message_select_device
}

main