#! /bin/bash

function check_var_on_null() {
    if [[ -z "$1" ]]; then
        return 1
    fi
}

function check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        echo "Запустите скрипт от root!" >&2w
        exit 1
    fi
}

function check_file_exist() {
    if [[ -e $1 ]]; then
        return 0
    else echo "File $1 not found"
        retunr 1
    fi
}