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
    while [ -z ${device} ]; do
        printf "Выберите устройство:\n 1.SW1-HQ\n 2.SW2-HQ\n 3.SW3-HQ\n 0.Exit\n"
            read -r var
            if [[ ${var} == "1" ]]; then device="sw1-hq"
            elif [[ ${var} == "2" ]]; then device="sw2-hq"
            elif [[ ${var} == "3" ]]; then device="sw3-hq"
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