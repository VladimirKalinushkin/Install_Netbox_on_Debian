#!/bin/bash

    # install and configure redis

    apt install redis-server -y

    systemctl enable redis 


    # In /etc/redis/redis.conf check fields:
    #     requirepass YourPasswordForRedis
    #     supervised systemd

    systemctl restart redis 

    # After configure redis check your connection:
    #    redis-cli
    #        to the Redis server using the following AUTH query and be sure to change the password.
    #    AUTH YourPasswordForRedis
    #        Once authenticated, you should get the output OK
    #        Now run the PING query below to ensure that your connection is successful
    #    PING
    #        If successful, you should get the output PONG from the Redis server.
