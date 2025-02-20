#! /bin/bash

#Остановка скрипта при вознкиновение ошибки
set -e

my_dir="$(dirname "$0")"

source "$my_dir/utils.sh"

# enp7s
enp_path_arr=("/etc/net/ifaces/enp7s1/" "/etc/net/ifaces/enp7s2/" "/etc/net/ifaces/enp7s3/" "/etc/net/ifaces/enp7s4/")
mgmt_path=""


device=""
device_ip=""
device_gateway="192.168.11.81"

interface_settings="BOOTPROTO=static\nTYPE=eth\nCONFIG_WIRELESS=no\nSYSTEMD_BOOTPROTO=static\nCONFIG_IPV4=yes\nDISABLED=no\nNM_CONTROLLED=no\nSYSTEMD_CONTROLLED=no"

declare -A ip_dict
ip_dict["sw1-hq"]="192.168.11.82/29"
ip_dict["sw2-hq"]="192.168.11.83/29"
ip_dict["sw3-hq"]="192.168.11.84/29"


function create_interface() {
    if [[ $device == "sw2-hq" ]]; then
        for (( i = 0; i < 4; i++ )); do
            mkdir "${enp_path_arr[$i]}"
        done
    else
        for (( i = 0; i < 3; i++ )); do
            mkdir "${enp_path_arr[$i]}"
        done
    fi
}

function configure_interface() {
    echo -e "$interface_settings" >> "${enp_path_arr[0]}options"
    printf "TYPE=eth\nBOOTPROTO=static" >> "${enp_path_arr[1]}"options
    if [[ $device == "sw2-hq" ]]; then
            cp -r "${enp_path_arr[1]}options" "${enp_path_arr[2]}"
            cp -r "${enp_path_arr[1]}options" "${enp_path_arr[3]}"
    else
            cp -r "${enp_path_arr[1]}options" "${enp_path_arr[2]}"
    fi
}

function setup_ovs() {
    ovs-vsctl add-br "${device^^}"
    sed -i "s/OVS_REMOVE=yes/OVS_REMOVE=no/g" /etc/net/ifaces/default/options
    case $device in
        "sw1-hq")
            ovs-vsctl add-port SW1-HQ enp7s1 trunk=110,220,330
            ovs-vsctl add-port SW1-HQ enp7s2 trunk=110,220,330
            ovs-vsctl add-port SW1-HQ enp7s3 trunk=110,220,330 ;;
        "sw2-hq")
            ovs-vsctl add-port SW2-HQ enp7s1 trunk=110,220,330
            ovs-vsctl add-port SW2-HQ enp7s2 trunk=110,220,330
            ovs-vsctl add-port SW2-HQ enp7s3 tag=220
            ovs-vsctl add-port SW2-HQ enp7s4 tag=110 ;;
        "sw3-hq")
            ovs-vsctl add-port SW3-HQ enp7s1 trunk=110,220,330
            ovs-vsctl add-port SW3-HQ enp7s2 trunk=110,220,330
            ovs-vsctl add-port SW3-HQ enp7s3 tag=330 ;;
    esac

}

function setup_main_tree_protocol() {
    case $device in
        "sw1-hq")
            ovs-vsctl set bridge SW1-HQ stp_enable=true
            ovs-vsctl set bridge SW1-HQ other_config:stp-priority=16384 ;;
        "sw2-hq")
            ovs-vsctl set bridge SW2-HQ stp_enable=true
            ovs-vsctl set bridge SW2-HQ other_config:stp-priority=24576 ;;
        "sw3-hq")
            ovs-vsctl set bridge SW3-HQ stp_enable=true
            ovs-vsctl set bridge SW3-HQ other_config:stp-priority=28672 ;;
    esac
}

function configure_mgmt() {
    device_ip=${ip_dict[device]}
    mkdir /etc/net/ifaces/MGMT/
    printf "TYPE=ovsport\nBOOTPROTO=static\nCONFIG_IPV4=yes\nBRIDGE=%s\nVID=330" "${device^^}" >> /etc/net/ifaces/MGMT/options
    # device_ip пустой
    echo "${device_ip}" >> /etc/net/ifaces/MGMT/ipv4address
    printf "default via %s" "${device_gateway}" >> /etc/net/ifaces/MGMT/ipv4route
}

function configure_modprobe() {
    local conf_path="/etc/modules"
    modprobe 8021q
    # Проверка не работает
    if ! grep -q "8021q" $conf_path; then
        printf "8021q" >> $conf_path
    fi
}

function rollback() {
    printf "Выберите устройство:\n SW1-HQ\n SW2-HQ\n SW3-HQ\n 0.Exit\n"
    local var=""
    read -r var
    if [[ ${var} == "0" ]]; then exit
    fi

    for (( i = 0; i < 4; i++ )); do
        if [[ -e "${enp_path_arr[$i]}" ]]; then
            rm -rf "${enp_path_arr[$i]}"
        fi
    done

    if [[ -e "${enp_path_arr[$i]}" ]]; then rm -rf /etc/net/ifaces/MGMT/
    fi
    ovs-vsctl del-br "${var^^}"
    exit
}

function message_select_device() {
    local var=""
    while [ -z "${device}" ]; do
        printf "Выберите устройство:\n 1.SW1-HQ\n 2.SW2-HQ\n 3.SW3-HQ\n 4.Rollback\n 0.Exit\n"
            read -r var
            if [[ ${var} == "1" ]]; then device="sw1-hq" device_ip="192.168.11.82/29"
            elif [[ ${var} == "2" ]]; then device="sw2-hq" device_ip="192.168.11.83/29"
            elif [[ ${var} == "3" ]]; then device="sw3-hq" device_ip="192.168.11.84/29"
            elif [[ ${var} == "4" ]]; then rollback
            elif [[ ${var} == "0" ]]; then exit
            fi
    done
}

function main {
    check_sudo
    message_select_device
#    device_ip=${ip_dict[$device]}
#    echo $device_ip
    create_interface || echo "Ошибка при создание интерфейсов"
    configure_interface && echo "Интерфейсы enp7s созданы и настроены" || echo "Ошибка при настройке интерфейсов"
    systemctl restart network
    setup_ovs && echo "ovs настроен" || echo "Ошибка при настройке ovs"
    configure_mgmt && echo "MGMT создан и настроен" || echo "Ошибка при настройке MGMT"
    systemctl restart network
    configure_modprobe && echo "modprobe подключен и настроен" || echo "Ошибка при настройке modprobe"
    setup_main_tree_protocol && echo "Протокол основного дерева настроен" || echo "Ошибка при настройке протокола основного дерева"
    systemctl restart network
}

main