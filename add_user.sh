#! /bin/bash

#Остановка скрипта при вознкиновение ошибки
set -e

USER_NAME="sshuser"
NEW_PASSWORD="P@ssw0rd"

device_name=""
DOMAIN=".au.team"

function check_sudo { 
    if [[ $EUID -ne 0 ]]; then
        echo "Запустите скрипт от root!" >&2
        exit 1
    fi
}

function select_device_name {
    if [[ $(hostname --ip-address) == "192.168.11.82" ]]; then
        device_name="sw1-hq"
    elif [[ $(hostname --ip-address) == "192.168.11.83" ]]; then
        device_name="sw2-hq"
    elif [[ $(hostname --ip-address) == "192.168.11.84" ]]; then
        device_name="sw3-hq"
    elif [[ $(hostname --ip-address) == "192.168.11.85" ]]; then
        device_name="admin-hq"
    elif [[ $(hostname --ip-address) == "192.168.11.66" ]]; then
        device_name="srv1-hq"
    else return 1
    fi
    return 0
}

function check_device_name_on_null {
    #Если строка пустая
    if [[ -z $device_name ]]; then
        return 1
    fi
}

function set_hostname {
    hostnamectl set-hostname ${device_name}${DOMAIN};
    if [[ $? -ne 0 ]]; then
        echo "Ошибка установки hostname!" >&2
        return 1
    fi
}

function create_user {
    
    if id "$USER_NAME" &>/dev/null; then
        userdel -r $USER_NAME || return 1
    fi
    useradd $USER_NAME -m -U -s /bin/bash || return 1
}

function set_password {
    echo $USER_NAME:$NEW_PASSWORD | chpasswd || return 1
}

function set_admin_role {
    #Нужна проверка, если запись существует
    usermod -aG wheel $USER_NAME || return 1
    echo -e "$USER_NAME ALL=(ALL) NOPASSWD: ALL" | EDITOR="tee -a" visudo >/dev/null || return 1
}


function main_add_user {
    check_sudo
    select_device_name && echo "device_name установлен" || echo "device_name не найден!"
    set_hostname && echo "Hostname установлен!" || echo "Ошибка установки hostname"
    create_user && echo "Пользователь создан!" || echo "Ошибка создания пользователя"
    set_password && echo "Пароль установлен!" || echo "Ошибка установки пароля"
    set_admin_role && echo "Права админа добавлены!" || echo "Ошибка настройки прав"
}

#sudo userdel -r username