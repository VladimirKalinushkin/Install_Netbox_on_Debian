#!/bin/bash

    # Install nginx and configurate ssl

    apt install nginx ufw openssl -y

    ufw enable
    ufw allow 443
    ufw allow 80

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/netbox.key \
    -out /etc/ssl/certs/netbox.crt

    