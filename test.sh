#!/bin/bash

# Список Ip-адресов устройств
TARGET_DEVICES=(
    ""
)

SSH_USER="root"
SSH_PASSWORD="root"

REQUEST_NAME=""

COMMAND="    
    apt update && apt install -y wget bash 

    wget github
    -O /tmp/your_script.sh &&
    chmod +x /tmp/your_script.sh &&
    /tmp/your_script.sh
"

COMMAND1="hostname --ip-address"

IP_ADDRESS=$(hostname --ip-address)

if [[ "$IP_ADDRESS" == "192.168.11.85" ]]; then
  REQUEST_NAME="ADMIN-HQ"

elif [[ "$IP_ADDRESS" == "192.168.11.82" ]]; then
  REQUEST_NAME="sw2-hq"

elif [[ "$IP_ADDRESS" == "192.168.11.83" ]]; then
  REQUEST_NAME="sw3-hq"

elif [[ "$IP_ADDRESS" == "192.168.11.85" ]]; then
  REQUEST_NAME="admin-hq"

elif [[ "$IP_ADDRESS" == "192.168.11.66" ]]; then
  REQUEST_NAME="srv1-hq"
fi


# Проверка на null
if [[ -z "$REQUEST_NAME" ]]; then
  exit 0
fi

sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no $SSH_USER@$IP "$COMMAND1"