#! /bin/bash

#Остановка скрипта при вознкиновение ошибки
set -e

ENS_FILE_PATH="/etc/net/ifaces/ens18"

# enp7s
NETWORK_INTERFACE_1="/etc/net/ifaces/enp7s1"
NETWORK_INTERFACE_2="/etc/net/ifaces/enp7s2"
NETWORK_INTERFACE_3="/etc/net/ifaces/enp7s3"
NETWORK_INTERFACE_4="/etc/net/ifaces/enp7s4"


device_name=""
device_ip_address=""
device_gateway=""

# declare -A data_dict
# data_dict["sw1-hq"]="192.168.11.82/29 192.168.11.81"
# data_dict["sw2-hq"]="192.168.11.83/29 192.168.11.81"
# data_dict["sw3-hq"]="192.168.11.84/29 192.168.11.81"


function select_sw_handler {
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
            "0")
                exit 0
                ;;
        esac
}

function switching_configuration {

    while [[ -z "${device_name}" ]]
    do
        show_select_switch_device_message
        input_handler
    done
    echo "Выбрано: $device_name"
    
    # device_name="$1"
    # if [[ -z "${device_name}" ]]; then
    #     echo "Ошибка при выборе устройства"
    # fi

    # read -r device_ip_address device_gateway <<< "${data_dict[$device_name]}"
    # echo "IP: $device_ip_address"
    # echo "Gateway: $device_gateway"

    # #Check file exist
    # if [[ -e $ENS_FILE_PATH ]]; then
    #     echo "File exist"
    # else echo "File ens18 not found"
    #     exit 0
    # fi

    # # Нужна проверка на наличие файла
    # # Rename ens & change params
    # mv /etc/net/ifaces/ens18 /etc/net/ifaces/enp7s1
    # sed -i "s/BOOTPROTO=dhcp/BOOTPROTO=static/g" "${NETWORK_INTERFACE_1}"/options

    # # Нужна проверка на наличие файла
    # mkdir "${NETWORK_INTERFACE_2}"
    # printf "TYPE=eth\nBOOTPROTO=static" >> "${NETWORK_INTERFACE_2}"/options

    # # Копируем парамтеры из enp7s2
    # if [[ $device_name == "sw1-hq" || $device_name == "sw3-hq" ]]; then
    #     cp -r "${NETWORK_INTERFACE_2}" "${NETWORK_INTERFACE_3}"
    # elif [[ $device_name == "sw2-hq" ]]; then
    #     cp -r "${NETWORK_INTERFACE_2}" "${NETWORK_INTERFACE_3}" &&
    #     cp -r "${NETWORK_INTERFACE_2}" "${NETWORK_INTERFACE_4}"
    # fi

    # systemctl restart network

    # ovs-vsctl add-br "${device_name^^}"

    # mkdir /etc/net/ifaces/MGMT
    # printf "TYPE=ovsport\nBOOTPROTO=static\nCONFIG_IPV4=yes\nBRIDGE=%s\nVID=330" "${device_name^^}" >> /etc/net/ifaces/MGMT/options

    # printf "%s" "${device_ip_address}" > /etc/net/ifaces/MGMT/ipv4address
    # printf "default via %s" "${device_gateway}" > /etc/net/ifaces/MGMT/ipv4route
    # sed -i "s/OVS_REMOVE=yes/OVS_REMOVE=no/g" /etc/net/ifaces/default/options
    # systemctl restart network

    # case $device_name in 

    #     sw1-hq)
    #         ovs-vsctl add-port SW1-HQ enp7s1 trunk=110,220,330
    #         ovs-vsctl add-port SW1-HQ enp7s2 trunk=110,220,330
    #         ovs-vsctl add-port SW1-HQ enp7s3 trunk=110,220,330

    #         ovs-vsctl set bridge SW1-HQ stp_enable=true
    #         ovs−vsctl set bridge SW1-HQ other_config:stp-priority=16384
    #         ;;

    #     sw2-hq)
    #         ovs-vsctl add-port SW2-HQ enp7s1 trunk=110,220,330
    #         ovs-vsctl add-port SW2-HQ enp7s2 trunk=110,220,330
    #         ovs-vsctl add-port SW2-HQ enp7s3 tag=220
    #         ovs-vsctl add-port SW2-HQ enp7s4 tag=110

    #         ovs-vsctl set bridge SW2-HQ stp_enable=true
    #         ovs−vsctl set bridge SW2-HQ other_config:stp-priority=24576
    #         ;;

    #     sw3-hq)
    #         ovs-vsctl add-port SW3-HQ enp7s1 trunk=110,220,330
    #         ovs-vsctl add-port SW3-HQ enp7s2 trunk=110,220,330
    #         ovs-vsctl add-port SW3-HQ enp7s3 tag=330

    #         ovs-vsctl set bridge SW3-HQ stp_enable=true
    #         ovs−vsctl set bridge SW3-HQ other_config:stp-priority=28672
    #         ;;

    #     admin-hq)
    #         echo
    #         ;;

    #     srv1-hq)
    #         echo
    #         ;;

    # esac

    # modprobe 8021q
    # printf "8021q" >> /etc/modules
}