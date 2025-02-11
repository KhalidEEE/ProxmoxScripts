#! /bin/bash

user_name="sshuser"
new_password="P@ssw0rd"

echo "Set hostname"
#hostnamectl set-hostname admin-dt.au.team;

echo "Creating user"
useradd $user_name -m -U -s /bin/bash

echo "Set password"
echo $user_name:$new_password | chpasswd

echo "Set admin role"
sudo usermod -aG wheel $user_name
echo -e "\n# Added by script: passwordless sudo for $USERNAME\n$USERNAME ALL=(ALL) NOPASSWD: ALL" | sudo EDITOR="tee -a" visudo >/dev/null


#sudo userdel -r username