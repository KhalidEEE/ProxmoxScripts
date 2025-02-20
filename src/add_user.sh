#! /bin/bash

my_dir="$(dirname "$0")"

source "$my_dir/utils.sh"

#Остановка скрипта при вознкиновение ошибки
set -e

USER_NAME="sshuser"
NEW_PASSWORD="P@ssw0rd"
DOMAIN=".au.team"

device=""
old_hostname="${HOSTNAME}"

device_arr=("sw1-hq" "sw2-hq" "sw3-hq" "admin-hq" "admin-dt" "cli-dt" "cli-hq" "srv1-dt" "srv2-dt" "srv3-dt")

function set_hostname {
    hostnamectl set-hostname "${device}"${DOMAIN};
}

function configure_user {
    useradd $USER_NAME -m -U -s /bin/bash || return 1
    echo $USER_NAME:$NEW_PASSWORD | chpasswd || return 1
    grep ${USER_NAME} /etc/passwd
}

function set_role {
    #Нужна проверка, если запись существует
    usermod -aG wheel $USER_NAME || return 1
    if grep -Ei -q "${USER_NAME}" /etc/sudoers; then
        echo "NOPASSWD уже добавлен"
    else
        echo -e "$USER_NAME ALL=(ALL) NOPASSWD: ALL" | EDITOR="tee -a" visudo >/dev/null || return 1
    fi
}

function rollback() {
    userdel -r "${USER_NAME}"
    hostnamectl set-hostname "${old_hostname}"
}

function message_select_device() {
    local var=""
    while [ -z "${device}" ]; do
        printf "Выберите устройство:\n 1.SW1-HQ\n 2.SW2-HQ\n 3.SW3-HQ\n 4.ADMIN-HQ\n 5.ADMIN-DT\n 6.CLI-DT\n 7.CLI-HQ\n 8.SRV1-DT\n 9.SRV2-DT\n 10.SRV3-DT\n 11.SRV1-HQ\n 0.Exit\n"
            read -r var
            if [[ ${var} == "1" ]]; then device=${device_arr[0]}
            elif [[ ${var} == "2" ]]; then device=${device_arr[1]}
            elif [[ ${var} == "3" ]]; then device=${device_arr[2]}
            elif [[ ${var} == "4" ]]; then device=${device_arr[3]}
            elif [[ ${var} == "5" ]]; then device=${device_arr[4]}
            elif [[ ${var} == "6" ]]; then device=${device_arr[5]}
            elif [[ ${var} == "7" ]]; then device=${device_arr[6]}
            elif [[ ${var} == "8" ]]; then device=${device_arr[7]}
            elif [[ ${var} == "9" ]]; then device=${device_arr[8]}
            elif [[ ${var} == "10" ]]; then device=${device_arr[9]}
            elif [[ ${var} == "11" ]]; then device=${device_arr[10]}
            elif [[ ${var} == "0" ]]; then exit
            else message_select_device
            fi
    done
}


function main_add_user {
    check_sudo
    message_select_device
    set_hostname && echo "Hostname установлен!" || echo "Ошибка установки hostname"
    configure_user && echo "Пользователь создан!" || { echo "Ошибка при создания пользователя" && rollback; }
    set_role && echo "Права админа добавлены!" || { echo "Ошибка при настройки прав" && rollback; }
    echo "Настройка пользователя завершена"
}

main_add_user