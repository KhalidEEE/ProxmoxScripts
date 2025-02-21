#! /bin/bash

#Остановка скрипта при вознкиновение ошибки
set -e

options_path="/etc/bind/options.conf"
enp7s1_path="/etc/net/ifaces/enp7s1"
mgmt_path="/etc/net/ifaces/MGMT"


function setup_dns() {
    printf "search au.team\nnameserver 192.168.11.66\nnameserver 192.168.33.66\n" > /etc/net/ifaces/"${1}"/resolv.conf
    systemctl restart network
}

function setup_bind_srv1_hq() {
    apt-get update && apt-get install -y bind bind-utils

    cp -r $options_path $options_path.bak

    sed -i "16s#.*#        listen-on { 127.0.0.1; 192.168.11.66; };#" $options_path
    sed -i "17s#.*#        listen-on-v6 { any; };#" $options_path
    sed -i "24s#.*#        forwarders { 77.88.8.8; };#" $options_path
    sed -i "30s#.*#        allow-query { 192.168.11.0/24; 192.168.33.0/24; };#" $options_path
    sed -i "31s#.*#        allow-transfer { 192.168.33.66; };#" $options_path

    systemctl enable --now bind
    printf "search au.team\nnameserver 192.168.11.66" > /etc/net/ifaces/enp7s1/resolv.conf
    systemctl restart network
    systemctl restart bind
    # systemctl enable --now bind
}

function setup_bind_srv1_dt() {
    apt-get update && apt-get install -y bind bind-utils

    cp -r $options_path $options_path.bak

    sed -i "16s#.*#        listen-on { 127.0.0.1; 192.168.33.66; };#" $options_path
    sed -i "17s#.*#        listen-on-v6 { none; };#" $options_path
    sed -i "24s#.*#        forwarders { 77.88.8.8; };#" $options_path
    sed -i "30s#.*#        allow-query { 192.168.33.0/24; 192.168.11.0/24; };#" $options_path
    sed -i "31s#.*#        allow-transfer { none; };#" $options_path

    systemctl enable --now bind
    control bind-slave enabled
    printf "search au.team\nnameserver 192.168.33.66\nnameserver 192.168.11.66" > /etc/net/ifaces/enp7s1/resolv.conf
    systemctl restart network
    # systemctl restart bind
    systemctl enable --now bind
}

function rollback() {
    if [[ -e /etc/net/ifaces/${enp7s1_path}/resolv.conf ]]; then
        rm -rf /etc/net/ifaces/enp7s1/resolv.conf
        echo "resolv.conf удален"
    fi
    if [[ -e /etc/net/ifaces/${mgmt_path}/resolv.conf ]]; then
        rm -rf /etc/net/ifaces/enp7s1/resolv.conf
        echo "resolv.conf удален"
    fi

    if [[ -e $options_path.back ]]; then
      rm -rf $options_path
      mv $options_path.bak $options_path
      echo "options.conf восстановлен"
    fi
}

function message_select_device() {
    local var=""
    while [ -z "${device}" ]; do
        printf "Выберите устройство:\n 1.SRV1-HQ\n 2.SRV1-DT\n 3.SRV2, SRV3, ADMIN-DT\n 4.SW1-HQ, SW2-HQ, SW3-HQ, ADMIN-HQ\n 5.Rollback\n 0.Exit\n"
            read -r var
            if [[ ${var} == "1" ]]; then
                setup_bind_srv1_hq && echo "bind на srv1-hq настроен" || { echo "Ошибка при настроке bind на srv1-hq" && rollback; }
            elif [[ ${var} == "2" ]]; then
                setup_bind_srv1_dt && echo "bind на srv1-dt настроен" || { echo "Ошибка при настроке bind на srv1-dt" && rollback; }
            elif [[ ${var} == "3" ]]; then
                setup_dns ${enp7s1_path} && echo "bind настроен" || { echo "Ошибка при настроке bind" && rollback; }
            elif [[ ${var} == "4" ]]; then
                setup_dns ${mgmt_path} && echo "bind настроен" || { echo "Ошибка при настроке bind" && rollback; }
            elif [[ ${var} == "5" ]]; then
                rollback
            elif [[ ${var} == "0" ]]; then exit
            fi
    done
}

function main() {
    message_select_device
}

