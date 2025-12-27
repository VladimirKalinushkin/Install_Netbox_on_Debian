#!/bin/bash


    # install and configure postgresql

    apt update
    apt install wget curl -y
    apt install -y postgresql -y

    psql -V


    su -u postgres psql

    # Run:
    #     CREATE DATABASE netbox;
    #     CREATE USER netbox WITH PASSWORD 'YourPasswordForPostgres';
    #     ALTER DATABASE netbox OWNER TO netbox;
    #     -- the next two commands are needed on PostgreSQL 15 and later
    #     \connect netbox;
    #     GRANT CREATE ON SCHEMA public TO netbox;
    #     \q

       
    # check postgresql

    psql --username netbox --password --host localhost netbox

    #        If you correct installed redis, you will see:
    #        Password for user netbox: 
    #        psql (12.5 (Ubuntu 12.5-0ubuntu0.20.04.1))
    #        SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
    #        Type "help" for help.
    #        If you correct installed redis, you will see:
    #        You are connected to database "netbox" as user "netbox" on host "localhost" (address "127.0.0.1") at port "5432".
    #        SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
    # Run
    #     netbox=> \conninfo
    #     netbox=> \q

    