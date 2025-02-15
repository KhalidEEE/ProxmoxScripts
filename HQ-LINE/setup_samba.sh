#! /bin/bash

#Остановка скрипта при вознкиновение ошибки
set -e

BIND_PATH="/etc/bind/options.conf"
KDC_PATH="/etc/krb5.conf"

apt-get install task-samba-dc -y

configuring_srv-hq () {

    control bind-chroot disabled

    grep -q KRB5RCACHETYPE /etc/sysconfig/bind || echo 'KRB5RCACHETYPE="none"' >> /etc/sysconfig/bind

    grep -q 'bind-dns' /etc/bind/named.conf || echo 'include "/var/lib/samba/bind-dns/named.conf";' >> /etc/bind/named.conf

    sed -i "8s/^/\n /" $BIND_PATH
    sed -i "9s#.*#        tkey-gssapi-keytab \"/var/lib/samba/bind-dns/dns.keytab\";#" $BIND_PATH
    sed -i "10s#.*#       minimal-responses yes;#" $BIND_PATH
    sed -i "10s/^/\n /" $BIND_PATH
    sed -i '/logging {/a\        category lame-servers { null; };' $BIND_PATH

    systemctl stop bind
    rm -f /etc/samba/smb.conf
    rm -rf /var/lib/samba
    rm -rf /var/cache/samba
    mkdir -p /var/lib/samba/sysvol
    samba-tool domain provision

    systemctl enable --now samba
    systemctl start bind
    cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
}

adding_all_entries_srv-hq () {
    samba-tool dns add 127.0.0.1 au.team r-dt A 192.168.33.89
    samba-tool dns add 127.0.0.1 au.team fw-dt A 192.168.33.90
    samba-tool dns add 127.0.0.1 au.team fw-dt A 192.168.33.1
    samba-tool dns add 127.0.0.1 au.team fw-dt A 192.168.33.65
    samba-tool dns add 127.0.0.1 au.team fw-dt A 192.168.33.81
    samba-tool dns add 127.0.0.1 au.team admin-dt A 192.168.33.82
    samba-tool dns add 127.0.0.1 au.team srv1-dt A 192.168.33.66
    samba-tool dns add 127.0.0.1 au.team srv2-dt A 192.168.33.67
    samba-tool dns add 127.0.0.1 au.team srv3-dt A 192.168.33.68
    samba-tool dns add 127.0.0.1 au.team cli-dt A 192.168.33.2

    samba-tool dns add 127.0.0.1 au.team r-hq A 192.168.11.1
    samba-tool dns add 127.0.0.1 au.team r-hq A 192.168.11.65
    samba-tool dns add 127.0.0.1 au.team r-hq A 192.168.11.81
    samba-tool dns add 127.0.0.1 au.team sw1-hq A 192.168.11.82
    samba-tool dns add 127.0.0.1 au.team sw2-hq A 192.168.11.83
    samba-tool dns add 127.0.0.1 au.team sw3-hq A 192.168.11.84
    samba-tool dns add 127.0.0.1 au.team admin-hq A 192.168.11.85
    samba-tool dns add 127.0.0.1 au.team cli-hq A 192.168.11.2

    samba-tool dns zonecreate 127.0.0.1 11.168.192.in-addr.arpa
    samba-tool dns zonecreate 127.0.0.1 33.168.192.in-addr.arpa
    samba-tool dns zonelist 127.0.0.1

    samba-tool dns add 127.0.0.1 33.168.192.in-addr.arpa 89 PTR r-dt.au.team
    samba-tool dns add 127.0.0.1 33.168.192.in-addr.arpa 90 PTR fw-dt.au.team
    samba-tool dns add 127.0.0.1 33.168.192.in-addr.arpa 1 PTR fw-dt.au.team
    samba-tool dns add 127.0.0.1 33.168.192.in-addr.arpa 65 PTR fw-dt.au.team
    samba-tool dns add 127.0.0.1 33.168.192.in-addr.arpa 81 PTR fw-dt.au.team
    samba-tool dns add 127.0.0.1 33.168.192.in-addr.arpa 82 PTR admin-dt.au.team
    samba-tool dns add 127.0.0.1 33.168.192.in-addr.arpa 66 PTR srv1-dt.au.team
    samba-tool dns add 127.0.0.1 33.168.192.in-addr.arpa 67 PTR srv2-dt.au.team
    samba-tool dns add 127.0.0.1 33.168.192.in-addr.arpa 68 PTR srv3-dt.au.team
    samba-tool dns add 127.0.0.1 33.168.192.in-addr.arpa 2 PTR cli-dt.au.team

    samba-tool dns add 127.0.0.1 11.168.192.in-addr.arpa 1 PTR r-hq.au.team
    samba-tool dns add 127.0.0.1 11.168.192.in-addr.arpa 65 PTR r-hq.au.team
    samba-tool dns add 127.0.0.1 11.168.192.in-addr.arpa 66 PTR srv1-hq.au.team
    samba-tool dns add 127.0.0.1 11.168.192.in-addr.arpa 81 PTR r-hq.au.team
    samba-tool dns add 127.0.0.1 11.168.192.in-addr.arpa 82 PTR sw1-hq.au.team
    samba-tool dns add 127.0.0.1 11.168.192.in-addr.arpa 83 PTR sw2-hq.au.team
    samba-tool dns add 127.0.0.1 11.168.192.in-addr.arpa 84 PTR sw3-hq.au.team
    samba-tool dns add 127.0.0.1 11.168.192.in-addr.arpa 85 PTR admin-hq.au.team
    samba-tool dns add 127.0.0.1 11.168.192.in-addr.arpa 2 PTR cli-hq.au.team

    samba-tool dns add 127.0.0.1 au.team www CNAME srv1-dt.au.team -U administrator
    samba-tool dns add 127.0.0.1 au.team zabbix CNAME srv1-dt.au.team -U administrator
}

add_user_srv-hq () {
    samba-tool group add group1
    samba-tool group add group2
    samba-tool group add group3

    for i in {1..10}; do
    samba-tool user add user$i P@ssw0rd;
    samba-tool user setexpiry user$i --noexpiry;
    samba-tool group addmembers "group1" user$i;
    done

    for i in {11..20}; do
    samba-tool user add user$i P@ssw0rd;
    samba-tool user setexpiry user$i --noexpiry;
    samba-tool group addmembers "group2" user$i;
    done

    for i in {21..30}; do
    samba-tool user add user$i P@ssw0rd;
    samba-tool user setexpiry user$i --noexpiry;
    samba-tool group addmembers "group3" user$i;
    done

    samba-tool ou add 'OU=CLI'
    samba-tool ou add 'OU=ADMIN'
}

move_clients_srv-hq () {
    samba-tool computer move ADMIN-DT 'OU=ADMIN,DC=au,DC=team'
    samba-tool computer move ADMIN-HQ 'OU=ADMIN,DC=au,DC=team'
    samba-tool computer move CLI-DT 'OU=CLI,DC=au,DC=team'
    samba-tool computer move CLI-HQ 'OU=CLI,DC=au,DC=team'
}

shared_folder_srv-hq () {
    mkdir /opt/data
    chmod 777 /opt/data

    # Нужно задать параметры в /etc/samba/smb.conf:

    systemctl restart samba
}

configuring_srv-dt () {
    for service in smb nmb krb5kdc slapd bind; do 
    systemctl disable $service; 
    systemctl stop $service; 
    done

    grep -q KRB5RCACHETYPE /etc/sysconfig/bind || echo 'KRB5RCACHETYPE="none"' >> /etc/sysconfig/bind
    grep -q 'bind-dns' /etc/bind/named.conf || echo 'include "/var/lib/samba/bind-dns/named.conf";' >> /etc/bind/named.conf

    sed -i "8s/^/\n /" $BIND_PATH
    sed -i "9s#.*#        tkey-gssapi-keytab \"/var/lib/samba/bind-dns/dns.keytab\";#" $BIND_PATH
    sed -i "10s#.*#       minimal-responses yes;#" $BIND_PATH
    sed -i "10s/^/\n /" $BIND_PATH
    sed -i '/logging {/a\        category lame-servers { null; };' $BIND_PATH

    sed -i '/logging {/a\ default_realm = AU.TEAM' $KDC_PATH
    sed -i "11s/^/ dns_lookup_realm = false/" $KDC_PATH
    

    kinit administrator@AU.TEAM

    rm -f /etc/samba/smb.conf
    rm -rf /var/lib/samba
    rm -rf /var/cache/samba
    mkdir -p /var/lib/samba/sysvol

    samba-tool domain join au.team DC -Uadministrator --realm=au.team --dns-backend=BIND9_DLZ

    systemctl enable --now samba
    systemctl enable --now bind 

    samba-tool drs replicate srv1-dt.au.team srv1-hq.au.team dc=au,dc=team -Uadministrator
    samba-tool drs replicate srv1-hq.au.team srv1-dt.au.team dc=au,dc=team -Uadministrator
}