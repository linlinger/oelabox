#!/bin/bash

runby="root"
iam=$(id -un)
if [ "$iam" != "$runby" ]; then
    echo "$0: program must be run by user \"$runby\""
    exit
fi

function check_installed() {
    if [ -n "$(command -v rpm)" ]; then
        rpm -q "$1" &> /dev/null
    elif [ -n "$(command -v dpkg-query)" ]; then
        dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -c "ok installed"
    elif [ -n "$(command -v pacman)" ]; then  # Corrected condition for pacman
        pacman -Q "${1}" &> /dev/null
    else
        echo_info "Unsupported package manager."
        exit 1
    fi
}

function echo_info() {
    echo "* $@"
}

echo_info "Checking if ansible is installed..."
if ! check_installed ansible; then
    echo_info "ansible not installed. Installing now."
    if [ -n "$(command -v dnf)" ]; then
        if ! check_installed epel-release; then
            echo_info "epel-release not installed. Installing now."
            dnf install epel-release -y
        fi
        dnf install ansible -y
    elif [ -n "$(command -v apt)" ]; then
        apt update
        apt install python3-pip
        pip3 install ansible
    elif [ -n "$(command -v pacman)" ]; then
        pacman -S ansible --noconfirm
        echo "Installing Ansible community collections"
        ansible-galaxy collection install community.general
    else
        echo_info "Unsupported package manager."
        exit 1
    fi
fi

echo_info "Running ansible playbook..."
ansible-playbook setup.yml

