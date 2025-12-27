#!/bin/bash

    # For download acluall version see https://github.com/netbox-community/netbox/releases
    version=4.4.8
    

    apt update


    # Postgres and redis install
    apt install wget curl \
    redis-server \
    postgresql \
    -y

    systemctl enable redis
    systemctl enable postgresql


    # Python libraries install
    apt install -y python3 python3-pip python3-venv python3-dev \
    build-essential libxml2-dev libxslt1-dev libffi-dev libpq-dev \
    libssl-dev zlib1g-dev \
    -y
    

    # Install nginx and configurate ssl
    apt install nginx ufw openssl \
    -y

    systemctl enable nginx

    ufw enable
    ufw allow 443
    ufw allow 80
    ufw allow 8000

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/netbox.key \
    -out /etc/ssl/certs/netbox.crt


    # Download netbox
    wget https://github.com/netbox-community/netbox/archive/refs/tags/v$version.tar.gz
    tar -xzf v$version.tar.gz -C /opt
    rm v$version.tar.gz*
    
    ln -s /opt/netbox-$version/ /opt/netbox

    mkdir /opt/netbox-$version/netbox/media
    adduser --system --group netbox
    chown --recursive netbox /opt/netbox-$version/netbox/media/
    chown --recursive netbox /opt/netbox-$version/netbox/reports/
    chown --recursive netbox /opt/netbox-$version/netbox/scripts/

    cd /opt/netbox/netbox/netbox/
    cp configuration_example.py configuration.py
    ../generate_secret_key.py > key.txt
