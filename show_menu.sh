#! /bin/bash

echo_subheader() {
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color
    echo -e "${CYAN}$1${NC}"
}

echo_header() {
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color
    echo -e "${CYAN}$1${NC}"
}

function main_select_action_message {
    echo "Действие:"
    printf "%10s - базовая настройка пользователей и имен устройств\n" "1"
    printf "%10s - настройка коммутации\n" "2"
    printf "%10s - настройка dns\n" "3"
    printf "%10s - настройка синхронизации времени между сетевыми устройствами по протоколу NTP\n" "4"
    printf "%10s - реализация доменной инфраструктуры SAMBA AD\n" "5"
}

function show_select_switch_device_message {
    echo_header $'\n\n#>===================== Выберите устройство =====================<#\n'


    echo_subheader "   1. SW1-HQ"
    echo_subheader "   2. SW2-HQ"
    echo_subheader "   3. SW3-HQ"
    echo_subheader "   0. exit"


    echo_header $'\n#>=====================================================================<#\n'
}

function user_add_select_device_message {
    echo_header $'\n\n#>===================== Выберите устройство =====================<#\n'


    echo_subheader "   1. SW1-HQ"
    echo_subheader "   2. SW2-HQ"
    echo_subheader "   3. SW3-HQ"
    echo_subheader "   3. ADMIN-HQ"
    echo_subheader "   3. SRV1-HQ"
    echo_subheader "   0. exit"


    echo_header $'\n#>=====================================================================<#\n'
}

function dns_select_action_message {
    echo "Действие:"
    printf "%10s - Реализовать основной DNS сервер компании на SRV1-HQ\n" "1"
    printf "%10s - Сконфигурировать SRV1-DT, как резервный DNS сервер.\n" "2"
    printf "%10s - Настроить устройства на использование внутреннего DNS\n" "3"
}

function dns_show_select_device_internal {
    echo_header $'\n\n#>===================== Выберите устройство =====================<#\n'


    echo_subheader "   1. SW1-HQ"
    echo_subheader "   2. SW2-HQ"
    echo_subheader "   3. SW3-HQ"
    echo_subheader "   4. ADMIN-HQ"
    echo_subheader "   5. SRV2-DT"
    echo_subheader "   6. SRV3-DT"
    echo_subheader "   0. exit"


    echo_header $'\n#>=====================================================================<#\n'
}

function sync_select_device_message {
    echo_header $'\n\n#>===================== Выберите устройство =====================<#\n'


    echo_subheader "   1. SRV1-HQ"
    echo_subheader "   2. SW1-HQ | SW2-HQ | SW3-HQ | SRV1-DT | SRV2-DT | SRV3-DT"
    echo_subheader "   0. exit"


    echo_header $'\n#>=====================================================================<#\n'
}


function samba_select_device_message {
    echo_header $'\n\n#>===================== Выберите устройство =====================<#\n'


    echo_subheader "   1. SRV1-HQ"
    echo_subheader "   2. SRV1-DT"
    echo_subheader "   3. ADMIN-HQ"
    echo_subheader "   4. ADMIN-DT"
    echo_subheader "   5. CLI-HQ"
    echo_subheader "   6. CLI-DT"
    echo_subheader "   0. exit"


    echo_header $'\n#>=====================================================================<#\n'
}
