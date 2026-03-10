#!/bin/bash

set -eu



# For download acluall version see https://github.com/netbox-community/netbox/releases
version=4.4.8


Nginx_config="/etc/nginx/sites-available/netbox.conf"
Redis_config="/etc/redis/redis.conf"
Netbox_core_path="/opt/netbox-$version/netbox/netbox"
Example_configs="/opt/netbox-$version/contrib"

Listened_address="0.0.0.0"
Listened_port="443"
Proxy_path_address="127.0.0.1"
Proxy_path_port="8001"
Name_server="netbox.example.com"
Ssl_certificate_address="/etc/ssl/certs/netbox.crt"
Ssl_certificate_key_address="/etc/ssl/private/netbox.key"
Client_max_body_size="25m"

Space="\ \ \ \ "

Password_Redis=""

Database_name_Postgres="netbox"
User_name_Postgres="netbox"
Password_Postgres=""

Allowed_hosts_Netbox="*"


function Read_Varriable {

    local -n Target_buf=$2
    local Message="$1"
    local User_input

    read -p "$Message: " User_input

    if [ -n "$User_input" ]
    then
        Target_buf="$User_input"
    fi
}
function Read_Password {

    local -n Target_buf=$2
    local Message="$1"
    local User_input
    local Check

    echo -n "$Message: " 
    read -s User_input
    echo

    if [ -n "$User_input" ]
    then
        echo -n "Re-enter your password: " 
        read -s Check
        echo
        if [ -n "$Check" ]
        then
            if [ "$User_input" = "$Check" ];
            then
                Target_buf="$User_input"
                return 0
            else
                echo "Passwords do not match! You will exited!"
                return 1
            fi
        else
            echo "You didn't enter your password! You will exited!"
            return 1
        fi
    else
        echo "You didn't enter your password! You will exited!"
        return 1
    fi

}

function Start_message_echo {

    local Message="$1"
    
    echo
    echo "--------------------"
    echo "$Message ..."
    echo

}
function End_message_echo {

    local Message="$1"
    
    echo
    echo "$Message"
    echo "--------------------"
    echo

}



Start_message_echo "Start installing"



# Read name, address, paroles and ports
Read_Varriable "Enter yor server name, default (empty value) - $Name_server" Name_server
Read_Varriable "Enter address of server, default (empty value) - $Proxy_path_address" Proxy_path_address
Read_Varriable "Enter port to work netbox, default (empty value) - $Proxy_path_port" Proxy_path_port
Read_Varriable "Enter port to work netbox, default (empty value) - $Allowed_hosts_Netbox - All hosts. \
    For example - 'netbox.example.com', 'netbox.internal.local'" \
    Allowed_hosts_Netbox

Read_Password "Enter password for Redis-server" Password_Redis
if [ $? -ne 0 ]
then
    echo "Error reading password. Exiting."
    exit 1
fi

Read_Varriable "Enter database postgresql name, default (empty value) - $Database_name_Postgres" Database_name_Postgres
Read_Varriable "Enter postgresql user name, default (empty value) - $User_name_Postgres" User_name_Postgres

Read_Password "Enter password for Postgresql" Password_Postgres
if [ $? -ne 0 ]
then
    echo "Error reading password. Exiting."
    exit 1
fi



# Install packages
apt update -y > /dev/null


Start_message_echo "Start installing Wget,redis-server, postgresql and curl"
apt install -y wget curl redis-server postgresql -y > /dev/null
End_message_echo "Wget,redis-server, postgresql and curl were installed!"


Start_message_echo "Start installing Puthon libraries!"
apt install -y python3 python3-pip python3-venv python3-dev build-essential libxml2-dev libxslt1-dev libffi-dev libpq-dev \
libssl-dev zlib1g-dev -y  > /dev/null
End_message_echo "Python libraries were installed!"


Start_message_echo "Start installing nginx, ufw and openssl"
apt install nginx ufw openssl -y  > /dev/null
End_message_echo "Nginx, ufw and openssl were installed!"


Start_message_echo "Start nginx, redis and postgres!"

systemctl start redis-server > /dev/null
systemctl start postgresql > /dev/null
systemctl start nginx > /dev/null

systemctl enable redis-server > /dev/null
systemctl enable postgresql > /dev/null
systemctl enable nginx > /dev/null

End_message_echo "Nginx, redis and postgresql were enabled in systemd!"



Start_message_echo "Configure brandmauer"

ufw enable > /dev/null
ufw allow 443 > /dev/null
ufw allow 80 > /dev/null

End_message_echo "Brandmauer was configured!"



Start_message_echo "Start downloading Netbox from github"

# wget https://github.com/netbox-community/netbox/archive/refs/tags/v$version.tar.gz
# tar -xzf v$version.tar.gz -C /opt
# rm v$version.tar.gz*

# rm -rf /opt/netbox
# ln -s /opt/netbox-$version/ /opt/netbox

End_message_echo "End downloading Netbox from github!"



Start_message_echo "Create user for Netbox"

# mkdir /opt/netbox-$version/netbox/media
adduser --system --group netbox > /dev/null
chown --recursive netbox /opt/netbox-$version/netbox/media/ > /dev/null
chown --recursive netbox /opt/netbox-$version/netbox/reports/ > /dev/null
chown --recursive netbox /opt/netbox-$version/netbox/scripts/ > /dev/null

End_message_echo "User netbox was created and configured!"



Start_message_echo "Create sertificates"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-out $Ssl_certificate_address \
-keyout $Ssl_certificate_key_address \
 > /dev/null

End_message_echo "Sertificates were created!"



Start_message_echo "Configure nginx"

sed -e \
    "
    1,5{
            /listen /c${Space}listen ${Listened_address}:${Listened_port} ssl;
    }
    /listen /c${Space}listen ${Listened_address}:80;
    /server_name /c${Space}server_name ${Name_server};
    /proxy_pass /c${Space}${Space}proxy_pass http://${Proxy_path_address}:${Proxy_path_port};
    /ssl_certificate /c${Space}ssl_certificate ${Ssl_certificate_address};
    /ssl_certificate_key /c${Space}ssl_certificate_key ${Ssl_certificate_key_address};
    " \
    "$Example_configs/nginx.conf" > "$Nginx_config"

rm -f /etc/nginx/sites-enabled/netbox.conf
ln -s $Nginx_config /etc/nginx/sites-enabled/netbox.conf
rm -f /etc/nginx/sites-enabled/default

systemctl restart nginx

End_message_echo "Nginx was configured!"



Start_message_echo "Configure redis"

cp $Redis_config "$Redis_config.backup"

sed -i "/^#/d" $Redis_config
sed -i "/^$/d" $Redis_config

Count_pat_1=$(sed -n '/requirepass /{=;q;}' $Redis_config)
if [ -n "$Count_pat_1" ];
then
    sed -i " /requirepass /crequirepass ${Password_Redis}" $Redis_config
else
    echo "requirepass $Password_Redis" >> $Redis_config
fi

Count_pat_2=$(sed -n '/supervised /{=;q;}' $Redis_config)
if [ -n "$Count_pat_2" ];
then
    sed -i " /supervised /csupervised systemd" $Redis_config
else
    echo "supervised systemd" >> $Redis_config
fi

systemctl restart redis

End_message_echo "Redis was configured!"



Start_message_echo "Configure postgresql"

# Configure postgresql
# sudo -u postgres psql -c "CREATE DATABASE $Database_name_Postgres;"
# sudo -u postgres psql -c "CREATE USER $User_name_Postgres WITH PASSWORD '$Password_Postgres';"
# sudo -u postgres psql -c "ALTER DATABASE $Database_name_Postgres OWNER TO $User_name_Postgres;"

End_message_echo "Postgresql was configured!"



Start_message_echo "Start configuring Netbox"

cd "$Netbox_core_path"
cp "configuration_example.py" "configuration.py"

Netbox_secret_key=$(../generate_secret_key.py)

sed -i "/^#/d" "configuration.py"
sed -i "/^$/d" "configuration.py"

sed -i "/DATABASES = {/,/}/ {
  /'default': {/,/}/ {
    /'NAME': '[^']*'/ s//\'NAME': '${Database_name_Postgres}'/
    /'USER': '[^']*'/ s//\'USER': '${User_name_Postgres}'/
    /'PASSWORD': '[^']*'/ s//\'PASSWORD': '${Password_Postgres}'/
  }
}" configuration.py
sed -i "
  /'tasks': {/,/}/ {
    /'PASSWORD': '[^']*'/ s//\'PASSWORD': '${Password_Redis}'/
  }
  /'caching': {/,/}/ {
    /'PASSWORD': '[^']*'/ s//\'PASSWORD': '${Password_Redis}'/
  }
" configuration.py
sed -i " /ALLOWED_HOSTS /cALLOWED_HOSTS = [\'${Allowed_hosts_Netbox}\']" configuration.py
sed -i " /SECRET_KEY /cSECRET_KEY = '${Netbox_secret_key}'" configuration.py


/opt/netbox/upgrade.sh

cd /opt/netbox/venv/bin
source ./activate

cd /opt/netbox/netbox
python3 manage.py migrate
python3 manage.py createsuperuser
python3 manage.py collectstatic


End_message_echo "Netbox was configured!"



Start_message_echo "Running NetBox as a Systemd Service and configure gunicorn"

cp "$Example_configs/gunicorn.py" "/opt/netbox-$version/gunicorn.py"

sed -i "/^#/d" "/opt/netbox-$version/gunicorn.py"
sed -i "/^$/d" "/opt/netbox-$version/gunicorn.py"

sed -i " /bind /cbind = \'$Proxy_path_address:$Proxy_path_port\'" "/opt/netbox-$version/gunicorn.py"

cp -v /opt/netbox/contrib/*.service /etc/systemd/system/
systemctl daemon-reload

systemctl start netbox > /dev/null
systemctl start netbox-rq > /dev/null
systemctl enable --now netbox > /dev/null
systemctl enable --now netbox-rq > /dev/null

systemctl status netbox.service
systemctl status netbox-rq

End_message_echo "Netbox was running!"



End_message_echo "End installing!"


