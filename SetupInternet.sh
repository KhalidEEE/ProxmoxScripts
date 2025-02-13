#! /bin/bash

#Остановка скрипта при вознкиновение ошибки
set -e

device_name=""
device_ip_address=""

ENP_FILE_PATH="/etc/net/ifaces/ens18"

SW1_IP_ADDRESS="192.168.11.82" 
SW2_IP_ADDRESS="192.168.11.83" 
SW3_IP_ADDRESS="192.168.11.84" 
ADMIN_HQ_IP_ADDRESS="192.168.11.85" 
SRV1_HQ="192.168.11.66" 

function check_sudo { 
    if [[ $EUID -ne 0 ]]; then
        echo "Запустите скрипт от root!" >&2
        exit 1
    fi
}

function check_ens18_exist {
    #Существует ли файл
    if [[ ! -f "$ENP_FILE_PATH" ]]; then
        return 1
    fi
    return 0
}


function define_device_name {
    if [[ $(hostname --ip-address) == $SW1_IP_ADDRESS || $(hostname -f) == sw1-hq ]]; then
        device_name="sw1-hq"
    elif [[ $(hostname --ip-address) == $SW2_IP_ADDRESS || $(hostname -f) == sw2-hq ]]; then
        device_name="sw2-hq"
    elif [[ $(hostname --ip-address) == $SW3_IP_ADDRESS || $(hostname -f) == sw3-hq ]]; then
        device_name="sw3-hq"
    elif [[ $(hostname --ip-address) == $ADMIN_HQ_IP_ADDRESS || $(hostname -f) == admin-hq ]]; then
        device_name="admin-hq"
    elif [[ $(hostname --ip-address) == $SRV1_HQ || $(hostname -f) == srv1-hq ]]; then
        device_name="srv1-hq"
    else return 1
    fi
    return 0
}

function preparing_enp7s1 {
    #Preparing enp7s1
    #Rename ens18 to enp7s1
    mv /etc/net/ifaces/ens18 /etc/net/ifaces/enp7s1 || return 1
    sed -i "s/BOOTPROTO=dhcp/BOOTPROTO=static/g" /etc/net/ifaces/enp7s1/options || return 1
}

function create_interface {
    #create interface
    if [[ $device_name == "sw1-hq" || $device_name == "sw3-hq" ]]; then
        mkdir /etc/net/ifaces/enp7s{2..3} || return 1
    elif [[ $device_name == "sw2-hq" ]]; then
        mkdir /etc/net/ifaces/enp7s{2..4} || return 1
    else return 1
    fi
}

function configure_interface {
    #set params interface
    if [[ $device_name == "sw1-hq" || $device_name == "sw3-hq" ]]; then
        printf "TYPE=eth\nBOOTPROTO=static" >> /etc/net/ifaces/enp7s2 || return 1
        printf "TYPE=eth\nBOOTPROTO=static" >> /etc/net/ifaces/enp7s3 || return 1
    #printf "TYPE=eth\nBOOTPROTO=static" >> /etc/net/ifaces/enp7s4
    elif [[ $device_name == "sw2-hq" ]]; then
        printf "TYPE=eth\nBOOTPROTO=static" >> /etc/net/ifaces/enp7s2 || return 1
        printf "TYPE=eth\nBOOTPROTO=static" >> /etc/net/ifaces/enp7s3 || return 1
        printf "TYPE=eth\nBOOTPROTO=static" >> /etc/net/ifaces/enp7s4 || return 1
    fi
    systemctl restart network || return 1
    return 0
}

MGMT_SW1_IP="192.168.11.82/29"
MGMT_SW2_IP="192.168.11.83/29"
MGMT_SW3_IP="192.168.11.84/29"
MGMT_ADMIN_HQ_IP="192.168.11.85/29"
MGMT_SRV1_HQ_IP="192.168.11.66/29"

MGMT_GATEWAY="192.168.11.81"

function configure_MGMT {
    local mgmt_ip=""

    case "$device_name" in
        "sw1-hq") mgmt_ip="$MGMT_SW1_IP";;
        "sw2-hq") mgmt_ip="$MGMT_SW2_IP";;
        "sw3-hq") mgmt_ip="$MGMT_SW3_IP";;
        "admin-hq") mgmt_ip="$MGMT_ADMIN_HQ_IP";;
        "srv1-hq") mgmt_ip="$MGMT_SRV1_HQ_IP";;
        *) echo "Неизвестное устройство: $device_name" >&2; return 1;;
    esac

    mkdir -p /etc/net/ifaces/MGMT || return 1
    printf '%s' "TYPE=ovsport\nBOOTPROTO=static\nCONFIG_IPV4=yes\nBRIDGE=${device_name^^}\nVID=330" > /etc/net/ifaces/MGMT/options || return 1 # Используем > для перезаписи, если нужно
    printf "%s" "$mgmt_ip" > /etc/net/ifaces/MGMT/ipv4address || return 1
    printf "default via %s" "$MGMT_GATEWAY" > /etc/net/ifaces/MGMT/ipv4route || return 1
    systemctl restart network || return 1
}


function create_ovs {
    #device_name.ToUpper
    ovs-vsctl add-br ${device_name^^} || return 1
}


function configure_ovs_vsctl {
    if [[ $device_name == "sw1-hq" ]]; then 
        ovs-vsctl add-port SW1-HQ enp7s1 trunk=110,220,330 || return 1
        ovs-vsctl add-port SW1-HQ enp7s2 trunk=110,220,330 || return 1
        ovs-vsctl add-port SW1-HQ enp7s3 trunk=110,220,330 || return 1
    elif [[ $device_name == "sw2-hq" ]]; then
        ovs-vsctl add-port SW1-HQ enp7s1 trunk=110,220,330 || return 1
        ovs-vsctl add-port SW1-HQ enp7s2 trunk=110,220,330 || return 1
        ovs-vsctl add-port SW2-HQ enp7s3 tag=220 || return 1
        ovs-vsctl add-port SW2-HQ enp7s4 tag=110 || return 1
    elif [[ $device_name == "sw3-hq" ]]; then
        ovs-vsctl add-port SW1-HQ enp7s1 trunk=110,220,330 || return 1
        ovs-vsctl add-port SW1-HQ enp7s2 trunk=110,220,330 || return 1
        ovs-vsctl add-port SW3-HQ enp7s3 tag=330 || return 1
    fi
}

function config_kernel_module {
    #Enable kernel module
    modprobe 8021q || return 1
    if ! grep -q "8021q" /etc/modules; then # Проверяем, есть ли модуль в файле
        echo "8021q" >> /etc/modules || return 1
    fi
}


check_sudo
check_ens18_exist
define_device_name && echo "Имя устройства определенно" || echo "Не удалось определить имя устройства"
preparing_enp7s1 && echo "enp7s1 создан" || echo "Не удалось настроить интерфейс enp7s1"
create_interface && echo "enp7s2 и т.д. созданы" || echo "Не удалось создать интрефейсы enp7s.."
configure_interface && echo "enp7s2 и т.д. настроены " || echo "Не удалось настроить интерфейсы enp7s2, s3.."
create_ovs && echo "ovs создан" || echo "Не удалось создать ovs"
configure_MGMT && echo "MGMT создан и настроен" || echo "Не удалось создать MGMT"
configure_ovs_vsctl && echo "ovs настроен" || echo "Не удалось настроить ovs-vsctl для интерфейсов"
config_kernel_module && echo "8021q создано и настроено" || echo "Не удалось включить modprobe 8021q"