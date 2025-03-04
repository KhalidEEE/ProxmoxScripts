#! /bin/bash

#Остановка скрипта при вознкиновение ошибки
set -e

options_path="/etc/bind/options.conf"
enp7s1_path="/etc/net/ifaces/enp7s1"
mgmt_path="/etc/net/ifaces/MGMT"


function setup_dns_hq() {
    printf "search au.team\nnameserver 192.168.11.66\nnameserver 192.168.33.66\n" > "${1}"/resolv.conf
    systemctl restart network
}

function setup_dns_dt() {
    printf "search au.team\nnameserver 192.168.33.66\nnameserver 192.168.11.66\n" > "${1}"/resolv.conf
    systemctl restart network
}

function setup_bind_srv1_hq() {
    apt-get update && apt-get install -y bind bind-utils

    cp -r $options_path $options_path.bak

    sed -i "16s#.*#\tlisten-on { 127.0.0.1; 192.168.11.66; };#" $options_path
    sed -i "17s#.*#\tlisten-on-v6 { any; };#" $options_path
    sed -i "24s#.*#\tforwarders { 77.88.8.8; };#" $options_path
    sed -i "30s#.*#\tallow-query { 192.168.11.0/24; 192.168.33.0/24; };\n#" $options_path
    sed -i "31s#.*#\tallow-transfer { 192.168.33.66; };\n#" $options_path

    chown named:named /etc/bind/options.conf
    chmod 644 /etc/bind/options.conf


    systemctl enable --now bind
    printf "search au.team\nnameserver 192.168.11.66" > /etc/net/ifaces/enp7s1/resolv.conf
    systemctl restart network
    systemctl restart bind
    # systemctl enable --now bind
}

function setup_bind_srv1_dt() {
    apt-get update && apt-get install -y bind bind-utils

    cp -r $options_path $options_path.bak

    sed -i "16s#.*#\tlisten-on { 127.0.0.1; 192.168.33.66; };#" $options_path
    sed -i "17s#.*#\tlisten-on-v6 { none; };#" $options_path
    sed -i "24s#.*#\tforwarders { 77.88.8.8; };#" $options_path
    sed -i "30s#.*#\tallow-query { 192.168.33.0/24; 192.168.11.0/24; };\n#" $options_path
    sed -i "31s#.*#\tallow-transfer { none; };\n#" $options_path


    chown named:named /etc/bind/options.conf
    chmod 644 /etc/bind/options.conf

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
      cp -r $options_path.bak $options_path
      echo "options.conf восстановлен"
    fi
}

function message_select_device() {
    local var=""
    while [ -z "${device}" ]; do
        printf "Выберите устройство:\n 1.SRV1-HQ\n 2.SRV1-DT\n 3.SRV2, SRV3, ADMIN-DT\n 4.SW1-HQ, SW2-HQ, SW3-HQ\n 5.ADMIN-HQ\n 6.Rollback\n 0.Exit\n"
            read -r var
            if [[ ${var} == "1" ]]; then
                setup_bind_srv1_hq && echo "bind на srv1-hq настроен" || { echo "Ошибка при настроке bind на srv1-hq" && rollback; }
            elif [[ ${var} == "2" ]]; then
                setup_bind_srv1_dt && echo "bind на srv1-dt настроен" || { echo "Ошибка при настроке bind на srv1-dt" && rollback; }
            elif [[ ${var} == "3" ]]; then
                setup_dns_dt ${enp7s1_path} && echo "bind настроен" || { echo "Ошибка при настроке bind" && rollback; }
            elif [[ ${var} == "4" ]]; then
                setup_dns_hq ${mgmt_path} && echo "bind настроен" || { echo "Ошибка при настроке bind" && rollback; }
            elif [[ ${var} == "5" ]]; then
                setup_dns_hq ${enp7s1_path} && echo "bind настроен" || { echo "Ошибка при настроке bind" && rollback; }
            elif [[ ${var} == "6" ]]; then
                rollback
            elif [[ ${var} == "0" ]]; then exit
            fi
    done
}

function main() {
    message_select_device
}

main

