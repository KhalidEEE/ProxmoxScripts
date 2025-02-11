#!/bin/bash

# Список Ip-адресов устройств
# TARGET_DEVICES=(
#     ""
# )

SSH_USER="root"
SSH_PASSWORD="root"

REQUEST_NAME=""

COMMAND="    
    apt-get update && apt-get install -y wget bash 

    wget github
    -O /tmp/your_script.sh &&
    chmod +x /tmp/your_script.sh &&
    /tmp/your_script.sh
"

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

CREATE_USER_COMMAND="
    hostnamectl set-hostname \$REQUEST_NAME.au.team &&
    useradd sshuser -m -U -s /bin/bash &&
    grep sshuser /etc/passwd &&
    echo 'P@ssw0rd' | passwd --stdin sshuser
"

$CREATE_USER_COMMAND

sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no $SSH_USER@$IP "$COMMAND1"