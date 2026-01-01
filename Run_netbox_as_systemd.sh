#!/bin/bash

    # Running NetBox as a Systemd Service and configure gunicorn
    cp /opt/netbox/contrib/gunicorn.py /opt/netbox/gunicorn.py
    
    # Configure your installation port in
    #     gunicorn.py
    #     bind = '127.0.0.1:8001'

    cp -v /opt/netbox/contrib/*.service /etc/systemd/system/
    systemctl daemon-reload

    systemctl start netbox 
    systemctl start netbox-rq
    systemctl enable --now netbox 
    systemctl enable --now netboxnetbox-rq
    
    systemctl status netbox.service

