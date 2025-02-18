#! /bin/bash

#Остановка скрипта при вознкиновение ошибки
set -e

source ./show_menu.sh

function input_handler {
    main_select_action_message
    local choice
    read choice
    
    case "$choice" in 

        "1")
            ./add_user.sh
            ;;

        "2")
            ./switching_configuration.sh
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

