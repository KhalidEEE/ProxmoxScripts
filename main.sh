#! /bin/bash

#Остановка скрипта при вознкиновение ошибки
set -e

chmod +x ./show_menu.sh
chmod +x ./HQ-LINE/switching_configuration.sh
chmod +x ./HQ-LINE/setup_dns.sh
chmod +x ./HQ-LINE/setup_time_sync.sh
chmod +x ./HQ-LINE/setup_samba.sh

source ./show_menu.sh
source ./HQ-LINE/switching_configuration.sh
source ./HQ-LINE/setup_dns.sh
source ./HQ-LINE/setup_time_syncs.sh
source ./HQ-LINE/setup_samba.sh

function input_handler {
    main_select_action_message
    local choice
    read choice
    
    case "$choice" in 

        "1")
            ./add_user.sh
            ;;

        "2")
            switching_configuration
            ;;

        "3")
            ./setup_dns.sh
            ;;

        "4")
            ./setup_time_syncs.sh
            ;;

        "5")
            ./setup_samba.sh
            ;;

        "0")
            exit 0
            ;;

    esac
}

while true
do
    input_handler
done

