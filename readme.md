


## The following sections detail how to set up a new instance of NetBox:

For more information see [https://netboxlabs.com/docs/netbox/](https://netboxlabs.com/docs/netbox/).

For wach actual release see [https://github.com/netbox-community/netbox/releases](https://github.com/netbox-community/netbox/releases)

#### For version 4 Requirements    
|   Position                  |    Comment            |
|-----------------------------|-----------------------|
|   PostgreSQL database       |    14+                |
|   Redis                     |    4.0+               |
|   Python                    |    3.10, 3.11, 3.12   |
|   NetBox components         |                       |
|   Firewall                  |    ufw or other       |
|   HTTP server               |    nginx or apache    |
|   Gunicorn or uWSGI         |    optional           |
|   LDAP authentication       |    optional           |


### 1. Install Requirements packages and download netbox with 
`Install_packages.sh`

### 2. Configure Redis and PostgreSQL:

#### a. Check Redis
`redis-server --version`

#### b. In redis.conf check or paste fields:
                requirepass YourPasswordForRedis
                supervised systemd

`vi /etc/redis/redis.conf`

#### c.  Restart redis
`systemctl restart redis`

#### d.  After configure redis check your connection:
`redis-cli`
                to the Redis server using the following AUTH query and be sure 
                to change the password.
`AUTH YourPasswordForRedis`
                Once authenticated, you should get the output OK
                Now run the PING query below to ensure that your connection is successful
`PING`
                If successful, you should get the output PONG from the Redis server.
`EXIT`


#### e. Check PostgreSQL:
`psql --version`

#### g.   
`su postgres`

`psql`

            Run:
`CREATE DATABASE netbox;`
`CREATE USER netbox WITH PASSWORD 'YourPasswordForPostgres';`
`ALTER DATABASE netbox OWNER TO netbox;`

                    -- the next two commands are needed on PostgreSQL 15 and later

`\connect netbox;`
`GRANT CREATE ON SCHEMA public TO netbox;`
`\l`
`\q`

#### f.

`psql --username netbox --password --host localhost netbox`

            If you correct installed PostgreSQL, you will see:
                Password for user netbox: 
                You are connected to database "netbox" as user "netbox" on host 
                "localhost" (address "127.0.0.1") at port "5432".
                SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384,
                bits: 256, compression: off)

            Run
`netbox=> \conninfo`
`netbox=> \q`


### 3. Open configuration.py with your preferred editor to begin configuring NetBox. 
        NetBox offers many configuration parameters, 
        but only the following four are required for new installations:
        
                ALLOWED_HOSTS
                DATABASES (or DATABASE)
                    User
                    Database name
                    Password
                REDIS     (twoo or more times)
                    Username (optional)
                    Password
                SECRET_KEY (from /opt/netbox/netbox/key.txt)

`vi /opt/netbox/netbox/netbox/configuration.py`


 
### 4. Run the Upgrade Script
    
`/opt/netbox/upgrade.sh`

#### 4.a. - Run database schema migrations (skip with --readonly)

#### 4.b. Note that Python 3.10 or later is required for NetBox v4.0 and later releases.
            If the default Python installation on your server is set to a lesser version,
            pass the path to the supported installation as an environment variable named PYTHON. 
            (Note that the environment variable must be passed after the sudo command.)

`PYTHON=/usr/bin/python3.10 /opt/netbox/upgrade.sh`


### 5. Create a Super User
        
#### a. Run netbox activate with source:

`cd /opt/netbox/venv/bin`
`source ./activate`

#### b. Create a Super User:

`cd /opt/netbox/netbox`
`python3 manage.py migrate`
`python3 manage.py createsuperuser`
`python3 manage.py collectstatic`


#### 5.c. For fix debug with authorisation users:

#### 5.c.1. You should copy  fix_debug_with_authorisation_users.py 
                in /opt/netbox/netbox/
            
`cp fix_debug_with_authorisation_users.py \`
`/opt/netbox/netbox/fix_debug_with_authorisation_users.py`

`python3 /opt/netbox/netbox/manage.py nbshell`

#### 5.c.2. Run fix_debug_with_authorisation_users.py (there is) 
                with python console. 


### 6. Run netbox in testing mode:

#### a. 
`python3 manage.py runserver 0.0.0.0:8000 --insecure`

#### b. Check installation in external browser on address your machine on port 8000


### 7. Running NetBox as a Systemd Service and configure gunicorn with

#### a. Run_netbox_as_systemd.sh

##### b. Configure your installation port in /opt/netbox/gunicorn.py/gunicorn.py (bind = '127.0.0.1:8001')


### 11. Install and configuring Apache or Nginx as a Reverse Proxy

#### Example config in /opt/netbox/contrib/ is nginx.conf and apache.conf

            Or you can take example in netbox_witht_ssl.conf for work on port 80 without ssl (there is)
            Or can take netbox_tht_ssl.conf to configure your server to work with ssl 
            (identity with /opt/netbox/contrib/nginx.conf, there is)

#### Run
`cp /opt/netbox/contrib/nginx.conf /etc/nginx/sites-available/netbox`
`rm /etc/nginx/sites-enabled/default`
 `ln -s /etc/nginx/sites-available/netbox /etc/nginx/sites-enabled/netbox`

#### Rename your server_name in nginx netbox config file and check your configuration

`vi /etc/nginx/sites-available/netbox`
`nginx -t`
`systemctl restart nginx`






