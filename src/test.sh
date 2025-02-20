device=""
device_ip=""

declare -A ip_dict
ip_dict["sw1-hq"]="192.168.11.82/29"
ip_dict["sw2-hq"]="192.168.11.83/29"
ip_dict["sw3-hq"]="192.168.11.84/29"

function message_select_device() {
    local var=""
    while [ -z "${device}" ]; do
        printf "Выберите устройство:\n 1.SW1-HQ\n 2.SW2-HQ\n 3.SW3-HQ\n 0.Exit\n"
            read -r var
            if [[ ${var} == "1" ]]; then device="sw1-hq"
            elif [[ ${var} == "2" ]]; then device="sw2-hq"
            elif [[ ${var} == "3" ]]; then device="sw3-hq"
            elif [[ ${var} == "0" ]]; then exit
            else message_select_device
            fi
        device_ip=${ip_dict[$device]}
    done
}

message_select_device

echo $device_ip