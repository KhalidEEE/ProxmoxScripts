#! /bin/bash

#Остановка скрипта при вознкиновение ошибки
set -e

BIND_PATH="/etc/bind/options.conf"
KDC_PATH="/etc/krb5.conf"
SMB_PATH="/etc/samba/smb.conf"

admin_passwd="P@ssw0rd"

function install_dependency() {
    if ! rpm -q task-samba-dc &>/dev/null; then
        apt-get update && apt-get install task-samba-dc -y
    fi
}

configuring_srv-hq () {

    control bind-chroot disabled

    grep -q KRB5RCACHETYPE /etc/sysconfig/bind || echo 'KRB5RCACHETYPE="none"' >> /etc/sysconfig/bind

    grep -q 'bind-dns' /etc/bind/named.conf || echo 'include "/var/lib/samba/bind-dns/named.conf";' >> /etc/bind/named.conf

    sed -i "8s/^/\n /" $BIND_PATH
    sed -i "9s#.*# \ttkey-gssapi-keytab \"/var/lib/samba/bind-dns/dns.keytab\";#" $BIND_PATH
    sed -i "10s#.*#\tminimal-responses yes;\n#" $BIND_PATH
    sed -i "10s/^/\n /" $BIND_PATH
    sed -i '/logging {/a\\tcategory lame-servers { null; };' $BIND_PATH

    chown named:named ${BIND_PATH}
    chmod 644 ${BIND_PATH}

    systemctl stop bind
    rm -f /etc/samba/smb.conf
    rm -rf /var/lib/samba
    rm -rf /var/cache/samba
    mkdir -p /var/lib/samba/sysvol


    samba-tool domain provision \
      --realm=AU.TEAM \
      --domain=AU \
      --server-role=dc \
      --dns-backend=BIND9_DLZ \
      --adminpass="${admin_passwd}"


    systemctl enable --now samba
    systemctl start bind
    cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
}

adding_all_entries_srv-hq () {
    samba-tool dns add 127.0.0.1 au.team r-dt A 192.168.33.89 -U Administrator --password=${admin_passwd} || true
    samba-tool dns add 127.0.0.1 au.team fw-dt A 192.168.33.90 -U Administrator --password=${admin_passwd} || true
    samba-tool dns add 127.0.0.1 au.team fw-dt A 192.168.33.1 -U Administrator --password=${admin_passwd} || true
    samba-tool dns add 127.0.0.1 au.team fw-dt A 192.168.33.65 -U Administrator --password=${admin_passwd} || true
    samba-tool dns add 127.0.0.1 au.team fw-dt A 192.168.33.81 -U Administrator --password=${admin_passwd} || true
    samba-tool dns add 127.0.0.1 au.team admin-dt A 192.168.33.82 -U Administrator --password=${admin_passwd} || true
    samba-tool dns add 127.0.0.1 au.team srv1-dt A 192.168.33.66 -U Administrator --password=${admin_passwd} || true
    samba-tool dns add 127.0.0.1 au.team srv2-dt A 192.168.33.67 -U Administrator --password=${admin_passwd} || true
    samba-tool dns add 127.0.0.1 au.team srv3-dt A 192.168.33.68 -U Administrator --password=${admin_passwd} || true
    samba-tool dns add 127.0.0.1 au.team cli-dt A 192.168.33.2 -U Administrator --password=${admin_passwd} || true

    samba-tool dns add 127.0.0.1 au.team r-hq A 192.168.11.1 -U Administrator --password=${admin_passwd} || true
    samba-tool dns add 127.0.0.1 au.team r-hq A 192.168.11.65 -U Administrator --password=${admin_passwd} || true
    samba-tool dns add 127.0.0.1 au.team r-hq A 192.168.11.81 -U Administrator --password=${admin_passwd} || true
    samba-tool dns add 127.0.0.1 au.team sw1-hq A 192.168.11.82 -U Administrator --password=${admin_passwd} || true
    samba-tool dns add 127.0.0.1 au.team sw2-hq A 192.168.11.83 -U Administrator --password=${admin_passwd} || true
    samba-tool dns add 127.0.0.1 au.team sw3-hq A 192.168.11.84 -U Administrator --password=${admin_passwd} || true
    samba-tool dns add 127.0.0.1 au.team admin-hq A 192.168.11.85 -U Administrator --password=${admin_passwd}|| true
    samba-tool dns add 127.0.0.1 au.team cli-hq A 192.168.11.2 -U Administrator --password=${admin_passwd} || true

    samba-tool dns zonecreate 127.0.0.1 11.168.192.in-addr.arpa -U Administrator --password=${admin_passwd} || true
    samba-tool dns zonecreate 127.0.0.1 33.168.192.in-addr.arpa -U Administrator --password=${admin_passwd} || true
    samba-tool dns zonelist 127.0.0.1 -U Administrator --password=${admin_passwd} || true

    samba-tool dns add 127.0.0.1 33.168.192.in-addr.arpa 89 PTR r-dt.au.team -U Administrator --password=${admin_passwd}|| true
    samba-tool dns add 127.0.0.1 33.168.192.in-addr.arpa 90 PTR fw-dt.au.team U Administrator --password=${admin_passwd}|| true
    samba-tool dns add 127.0.0.1 33.168.192.in-addr.arpa 1 PTR fw-dt.au.team -U Administrator --password=${admin_passwd}|| true
    samba-tool dns add 127.0.0.1 33.168.192.in-addr.arpa 65 PTR fw-dt.au.team -U Administrator --password=${admin_passwd}|| true
    samba-tool dns add 127.0.0.1 33.168.192.in-addr.arpa 81 PTR fw-dt.au.team -U Administrator --password=${admin_passwd}|| true
    samba-tool dns add 127.0.0.1 33.168.192.in-addr.arpa 82 PTR admin-dt.au.team -U Administrator --password=${admin_passwd}|| true
    samba-tool dns add 127.0.0.1 33.168.192.in-addr.arpa 66 PTR srv1-dt.au.team -U Administrator --password=${admin_passwd}|| true
    samba-tool dns add 127.0.0.1 33.168.192.in-addr.arpa 67 PTR srv2-dt.au.team -U Administrator --password=${admin_passwd}|| true
    samba-tool dns add 127.0.0.1 33.168.192.in-addr.arpa 68 PTR srv3-dt.au.team -U Administrator --password=${admin_passwd}|| true
    samba-tool dns add 127.0.0.1 33.168.192.in-addr.arpa 2 PTR cli-dt.au.team -U Administrator --password=${admin_passwd}|| true

    samba-tool dns add 127.0.0.1 11.168.192.in-addr.arpa 1 PTR r-hq.au.team -U Administrator --password=${admin_passwd}|| true
    samba-tool dns add 127.0.0.1 11.168.192.in-addr.arpa 65 PTR r-hq.au.team -U Administrator --password=${admin_passwd}|| true
    samba-tool dns add 127.0.0.1 11.168.192.in-addr.arpa 66 PTR srv1-hq.au.team -U Administrator --password=${admin_passwd}|| true
    samba-tool dns add 127.0.0.1 11.168.192.in-addr.arpa 81 PTR r-hq.au.team -U Administrator --password=${admin_passwd}|| true
    samba-tool dns add 127.0.0.1 11.168.192.in-addr.arpa 82 PTR sw1-hq.au.team -U Administrator --password=${admin_passwd}|| true
    samba-tool dns add 127.0.0.1 11.168.192.in-addr.arpa 83 PTR sw2-hq.au.team -U Administrator --password=${admin_passwd}|| true
    samba-tool dns add 127.0.0.1 11.168.192.in-addr.arpa 84 PTR sw3-hq.au.team -U Administrator --password=${admin_passwd}|| true
    samba-tool dns add 127.0.0.1 11.168.192.in-addr.arpa 85 PTR admin-hq.au.team -U Administrator --password=${admin_passwd}|| true
    samba-tool dns add 127.0.0.1 11.168.192.in-addr.arpa 2 PTR cli-hq.au.team -U Administrator --password=${admin_passwd}|| true

    samba-tool dns add 127.0.0.1 au.team www CNAME srv1-dt.au.team -U Administrator --password=${admin_passwd}|| true
    samba-tool dns add 127.0.0.1 au.team zabbix CNAME srv1-dt.au.team -U Administrator --password=${admin_passwd}|| true

#    samba-tool dns query 127.0.0.1 33.168.192.in-addr.arpa @ PTR -U Administrator --password='P@ssw0rd'
}

add_user_srv-hq () {
    samba-tool group add group1
    samba-tool group add group2
    samba-tool group add group3

    for i in {1..3}; do
    samba-tool user add user$i As121213@@;
    samba-tool user setexpiry user$i --noexpiry;
    samba-tool group addmembers "group1" user$i;
    done

    for i in {4..7}; do
    samba-tool user add user$i As121213@@;
    samba-tool user setexpiry user$i --noexpiry;
    samba-tool group addmembers "group2" user$i;
    done

    for i in {8..10}; do
    samba-tool user add user$i As121213@@;
    samba-tool user setexpiry user$i --noexpiry;
    samba-tool group addmembers "group3" user$i;
    done

    samba-tool ou add 'OU=CLI'
    samba-tool ou add 'OU=ADMIN'
}

move_clients_srv-hq () {
    samba-tool computer move ADMIN-DT 'OU=ADMIN,DC=au,DC=team' -U Administrator --password=${admin_passwd}
    samba-tool computer move ADMIN-HQ 'OU=ADMIN,DC=au,DC=team' -U Administrator --password=${admin_passwd}
    samba-tool computer move CLI-DT 'OU=CLI,DC=au,DC=team' -U Administrator --password=${admin_passwd}
    samba-tool computer move CLI-HQ 'OU=CLI,DC=au,DC=team' -U Administrator --password=${admin_passwd}
}

shared_folder_srv-hq () {
    if [[ ! -e /opt/data ]]; then
        mkdir /opt/data
    fi

    chmod 777 /opt/data

    # Нужно задать параметры в /etc/samba/smb.conf:
    cp /etc/samba/smb.conf /etc/samba/smb.conf.backup   
#    printf "[SAMBA]\n%9spath = /opt/data\n%9scomment = \"SAMBA\"\n%9spublic = yes\n%9swritable = yes\n%9sbrowseable = yes\n%9sguest ok = yes" >> /etc/samba/smb.conf
    printf '[SAMBA]\n\tpath = /opt/data\n\tcomment = "SAMBA"\n\tpublic = yes\n\twritable = yes\n\tbrowseable = yes\n\tguest ok = yes\n' >> /etc/samba/smb.conf

    systemctl restart samba
}

create_backup_srv-hq () { 
    mkdir /var/bac/

    printf "[Unit]\nDescription=Backup /opt/data\n\n[Service]\nType=oneshot\nExecStart=/bin/tar -czf \"/var/bac/SAMBA.tar.gz\" /opt/data\n\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/backup.service

    systemctl daemon-reload
    systemctl enable --now backup.service
    printf "[Unit]\nDescription=Backup /opt/data shared folder Timer\n\n[Timer]\nOnCalendar=*-*-* 20:00:00\nPersistent=true\nUnit=backup.service\n\n[Install]\nWantedBy=timers.target" > /etc/systemd/system/backup.timer
    systemctl daemon-reload
    systemctl enable --now backup.timer
}

configuring_srv-dt () {
    for service in smb nmb krb5kdc slapd bind; do 
    systemctl disable $service; 
    systemctl stop $service; 
    done

    grep -q KRB5RCACHETYPE /etc/sysconfig/bind || echo 'KRB5RCACHETYPE="none"' >> /etc/sysconfig/bind
    grep -q 'bind-dns' /etc/bind/named.conf || echo 'include "/var/lib/samba/bind-dns/named.conf";' >> /etc/bind/named.conf

    sed -i "8s/^/\n /" $BIND_PATH
    sed -i "9s#.*# \ttkey-gssapi-keytab \"/var/lib/samba/bind-dns/dns.keytab\";#" $BIND_PATH
    sed -i "10s#.*#\tminimal-responses yes;\n#" $BIND_PATH
    sed -i "10s/^/\n /" $BIND_PATH
    sed -i '/logging {/a\\tcategory lame-servers { null; };' $BIND_PATH

    rm -rf ${KDC_PATH}
    local FILE_PATH="$(dirname "$SCRIPT_DIR")/text3"
    cp -r "${FILE_PATH}" "${KDC_PATH}"

    kinit administrator@AU.TEAM

    rm -f /etc/samba/smb.conf
    rm -rf /var/lib/samba
    rm -rf /var/cache/samba
    mkdir -p /var/lib/samba/sysvol

    samba-tool domain join au.team DC -Uadministrator --password=${admin_passwd} --realm=au.team --dns-backend=BIND9_DLZ

    systemctl enable --now samba
    systemctl enable --now bind 

    samba-tool drs replicate srv1-dt.au.team srv1-hq.au.team dc=au,dc=team -Uadministrator --password=${admin_passwd}
    samba-tool drs replicate srv1-hq.au.team srv1-dt.au.team dc=au,dc=team -Uadministrator --password=${admin_passwd}S
    samba-tool drs replicate srv1-dt.au.team srv1-hq.au.team dc=au,dc=team -U administrator
    samba-tool drs replicate srv1-hq.au.team srv1-dt.au.team dc=au,dc=team -U administrator
}

configuring_admin_and_cli () {
    apt-get update && apt-get install -y gpupdate
    gpupdate-setup enable
}

function rollback_entries_srv_hq () {
    echo
}

function message_select_device() {
    local var=""
    while [ -z "${device}" ]; do
        printf "Выберите устройство:\n 1.SRV1-HQ\n 2.SRV1-DT\n 3.ADMIN-HQ\n 4.Переместить устройства в SRV1-HQ 0.Exit\n"
            read -r var
            if [[ ${var} == "1" ]]; then
                install_dependency
                configuring_srv-hq
                adding_all_entries_srv-hq
                add_user_srv-hq
            elif [[ ${var} == "2" ]]; then
                install_dependency
                onfiguring_srv-dt
            elif [[ ${var} == "3" ]]; then
                install_dependency
                apt-get update && apt-get install -y gpupdate
                gpupdate-setup enable
                apt-get update && apt-get install -y admc
                kinit administrator@AU.TEAM
                #Нужно адаптировать изменения в интрефейсе под консоль
                apt-get install -y gpui
            elif [[ ${var} == "4" ]]; then
                move_clients_srv-hq
            elif [[ ${var} == "0" ]]; then exit
            fi
    done
}

function main() {
    message_select_device
}

main
