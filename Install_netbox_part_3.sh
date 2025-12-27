#!/bin/bash

    # Download and install netbox

    # For download acluall version see https://github.com/netbox-community/netbox/releases
    version=4.4.8
    
    
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

    # Open configuration.py with your preferred editor to begin configuring NetBox. NetBox offers many configuration parameters, 
    #     but only the following four are required for new installations:
    #
    #     ALLOWED_HOSTS
    #     DATABASES (or DATABASE)
    #     REDIS     (twoo or more times)
    #     SECRET_KEY (from /opt/netbox/netbox/key.txt)
    #
 

