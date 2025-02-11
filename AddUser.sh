#! /bin/bash

USER_NAME="sshuser"
NEW_PASSWORD="P@ssw0rd"

device_name=""
DOMAIN=".au.team"

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
elif [[ $(hostname --ip-address) == "10.0.2.15" ]]; then
    device_name="TEST"
fi

#Если строка пустая
if [[ -z $(device_name) ]]; then
    exit 0
fi

echo "Set hostname"
hostnamectl set-hostname ${device_name}${DOMAIN};

echo "Creating user"
useradd $USER_NAME -m -U -s /bin/bash

echo "Set password"
echo $USER_NAME:$NEW_PASSWORD | chpasswd

echo "Set admin role"
usermod -aG wheel $USER_NAME
echo -e "$USER_NAME ALL=(ALL) NOPASSWD: ALL" | EDITOR="tee -a" visudo >/dev/null


#sudo userdel -r username