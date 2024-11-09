#!/usr/bin/env bash

# this script run procmon to watch syscall for udp, tcp trasmmission.
# output to csv file.
# can view from bkviewer
# files [ Log.csv, Procmon64.exe, ProcmonConfiguration.pmc ]

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    MSYS_NT*)   machine=Git;;
    *)          machine="UNKNOWN:${unameOut}"
esac
echo ${machine}

#WINDOWS c:\Users\##USERNAME##\.bkit
if [[ "${machine}" = "MinGw" || "${machine}" = "Git" || "${machine}" = "Cygwin" ]]; then
    running_directory="$(cd "$(dirname "$0")" && pwd)"
    # echo ${running_directory}
    cd ${running_directory}
    npx vinxi build
fi

#LINUX /home/user/.bkit
if [[ ${machine} = "Linux" ]]; then
    # dark httpd does not support soft link
    running_directory="$(cd "$(dirname "$0")" && pwd)"
    PATH=${running_directory}/../tui_sh_yaml_tools:$PATH

    echo $(pwd)
    cd "${running_directory}"
    npx vinxi build

    # backup of tui_web web for distribution
    cd .output && rm -rf tui_web && mv public tui_web
    tar -cvzf tui_web.tar.gz tui_web/*
    sha256sum ./tui_web.tar.gz > tui_web.tar.gz.sha256
    mv tui_web.tar.gz ../../tui_web.tar.gz
    mv tui_web.tar.gz.sha256 ../../tui_web.tar.gz.sha256

    # install files to tui_web dir
    cd "${running_directory}"/../tui_web
    rm -rf _build _server assets favicon.ico index.html index.html.br index.html.gz index.yaml
    tar zxvf ../tui_web.tar.gz --strip-components 1 -C .
    cp -rf ../tui.sh.yaml index.yaml
    
    cd "${running_directory}"/../tui_web
    # make directories
    #mkdir -p etc var var/stagit var/run var/net

    # make git log stagit
    #cd "${running_directory}"/../tui_web/var/stagit
    #echo "stagit : $(pwd)"
    #stagit-index .. > index.html
    #mkdir tui_web && cp logo.png ./tui_web/ && cp style.css ./tui_web/ && cp favicon.png ./tui_web/ && cd tui_web
    #stagit -u http://127.0.0.1:58080/var/stagit ../..

    cd "${running_directory}"/../tui_web
    # make systeminfo
    ../tui_sh_yaml_tools/neofetch ---backend off --no_config --stdout > ./var/run/system
    date >> ./var/run/system

    # make hardlink for each file
    hardlink /var/log ./var/log || echo ""

    echo "done"
fi
 