#! /bin/bash

#Остановка скрипта при вознкиновение ошибки
set -e

function install_dependency() {
    if ! rpm -q docker-engine &>/dev/null; then
        apt-get update && apt-get install -y docker-engine
    fi
}

function start() {
    systemctl enable --now docker.service
    docker run -d -p 5000:5000 --restart=always --name DockerRegistry registry:2
    docker ps
}

function deployment() {
    cd
    mkdir ~/web_project && cd ~/web_project

    printf "FROM nginx:alpine\nCOPY index.html /usr/share/nginx/html" >> DockerFile
    printf "<html>\n    <body>\n        <center><h1><b>WEB</b></h1></center>\n    </body>\n</html>\n" > index.html
    docker build -t localhost:5000/web:1.0 .

    docker images

    docker push localhost:5000/web:1.0
}

