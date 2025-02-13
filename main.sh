#! /bin/bash

#Остановка скрипта при вознкиновение ошибки
set -e

echo_header() {
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    echo -e "${RED}$1${NC}"
    }

    echo_subheader() {
    WHITE='\033[0;37m'
    NC='\033[0m' # No Color
    echo -e "${WHITE}$1${NC}"
    }

function show_select_action_message {
    echo_header $'\n\n#>===================== Выберите действие =====================<#\n'


    echo_subheader "   1. Настройка коммутаторов SW-HQ"
    echo_subheader "   2. Добавление пользователей(актуально для HQ ветки, на DT не тестировалась)"
    echo_subheader "   3. Настройка SRV1-HQ"
    echo_subheader "   0. exit"


    echo_header $'\n#>=====================================================================<#\n'
}

while [[ -z "${device_name}" ]]
do
    input_handler
done

function input_handler {
        show_select_action_message
        local choice
        read choice
        
        case "$choice" in 

            "1")
                main_setup_internet
                return 1
                ;;

            "2")
                main_add_user
                return 1
                ;;

            "3")
                echo ""
                return 1
                ;;
            "0")
                exit 0
                ;;

        esac
}

main

