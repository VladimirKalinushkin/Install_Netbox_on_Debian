#!/bin/bash

set -eu



# For download acluall version see https://github.com/netbox-community/netbox/releases
version=4.4.8


Example_config_nginx="./Includes/netbox_wth_ssl.conf"
Nginx_config="/etc/nginx/sites-available/netbox.conf"

Redis_config="/etc/redis/redis.conf"


Listened_address="0.0.0.0"
Listened_port="443"
Proxy_pass_address="127.0.0.1"
Proxy_pass_port="8081"
Name_server="netbox.example.com"

Ssl_certificate_address="/etc/ssl/certs/netbox.crt"
Ssl_certificate_key_address="/etc/ssl/private/netbox.key"

Client_max_body_size="25m"


Password_Redis=""

Space="\ \ \ \ "


echo
echo "--------------------"
echo "Start installing!"
echo



# Read name, address, paroles and ports
read -p "Enter yor server name, default (empty value) - netbox.example.com: " Read_buf
if [ -n "$Read_buf" ]
then
    Name_server=$Read_buf
fi

read -p "Enter address of server, default (empty value) - 127.0.0.1: " Read_buf
if [ -n "$Read_buf" ]
then
    Proxy_pass_address=$Read_buf
fi

read -p "Enter port to work netbox, default (empty value) - 8081: " Read_buf
if [ -n "$Read_buf" ]
then
    Proxy_pass_port=$Read_buf
fi

echo -n "Enter password for Redis: " 
read -s Read_buf
echo
if [ -n "$Read_buf" ]
then
    Check=""
    echo -n "Re-enter password for Redis: " 
    read -s Check
    echo
    if [ -n "$Check" ]
    then
        if [ "$Read_buf" = "$Check" ];
        then
            Password_Redis="$Read_buf"
        else
            echo "Passwords do not match! You will be exited!"
            exit 1
        fi
    else
        echo "You didn't enter your password for Redis! You will exited!"
        exit 1
    fi
else
    echo "You didn't enter your password for Redis! You will exited!"
    exit 1
fi



# Install packages
echo "--------------------"
echo "Start apt update!"
apt update -y > /dev/null
echo
echo "--------------------"
echo "Apt was updated!"
echo

# Postgres and redis install
echo "--------------------"
echo "Start installing Wget,redis-server, postgresql and curl!"
apt install -y wget curl \
redis-server \
postgresql \
-y \
 > /dev/null
echo
echo "--------------------"
echo "Wget,redis-server, postgresql and curl were installed!"
echo

# Python libraries install
echo "--------------------"
echo "Start installing Puthon libraries!"
apt install -y python3 python3-pip python3-venv python3-dev \
build-essential libxml2-dev libxslt1-dev libffi-dev libpq-dev \
libssl-dev zlib1g-dev \
-y \
 > /dev/null
echo
echo "--------------------"
echo "Python libraries were installed!"
echo

# Install nginx
echo "--------------------"
echo "Start installing nginx? ufw and openssl!"
apt install nginx ufw openssl \
-y \
 > /dev/null
echo
echo "--------------------"
echo "Nginx, ufw and openssl were installed!"
echo



# Start nginx, redis and postgres
systemctl start redis-server > /dev/null
systemctl start postgresql > /dev/null
systemctl start nginx > /dev/null

systemctl enable redis-server > /dev/null
systemctl enable postgresql > /dev/null
systemctl enable nginx > /dev/null

echo
echo "--------------------"
echo "Nginx, redis and postgresql were enabled in systemd!"
echo



# Configure ufw
ufw enable > /dev/null
ufw allow 443 > /dev/null
ufw allow 80 > /dev/null

echo "Ufw was configured"
echo



# Configure nginx
sed -e \
    "
    1,5{
            /listen /c${Space}listen ${Listened_address}:${Listened_port} ssl;
    }
    /listen /c${Space}listen ${Listened_address}:80 ssl;
    /server_name /c${Space}server_name ${Name_server};
    /proxy_pass /c${Space}${Space}proxy_pass http://${Proxy_pass_address}:${Proxy_pass_port};
    /ssl_certificate /c${Space}ssl_certificate ${Ssl_certificate_address};
    /ssl_certificate_key /c${Space}ssl_certificate_key ${Ssl_certificate_key_address};
    " \
    $Example_config_nginx > $Nginx_config

rm -f /etc/nginx/sites-enabled/netbox.conf
ln -s $Nginx_config /etc/nginx/sites-enabled/netbox.conf
rm -f /etc/nginx/sites-enabled/default

echo
echo "Nginx was configured!"
echo "--------------------"
echo



# Configure redis
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


echo
echo "Redis was configured!"
echo "--------------------"
echo


# Create certificates
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-out $Ssl_certificate_address \
-keyout $Ssl_certificate_key_address \
 > /dev/null

echo
echo "--------------------"
echo "Sertificates were created!"
echo



# Download and configure netbox
echo
echo "--------------------"
echo "Start downloading Netbox from github ..."
echo
wget https://github.com/netbox-community/netbox/archive/refs/tags/v$version.tar.gz
tar -xzf v$version.tar.gz -C /opt
rm v$version.tar.gz*
echo
echo "End downloading Netbox from github!"
echo "--------------------"
echo

ln -s /opt/netbox-$version/ /opt/netbox

mkdir /opt/netbox-$version/netbox/media
adduser --system --group netbox
chown --recursive netbox /opt/netbox-$version/netbox/media/
chown --recursive netbox /opt/netbox-$version/netbox/reports/
chown --recursive netbox /opt/netbox-$version/netbox/scripts/

echo
echo "User netbox was created and configured!"
echo "--------------------"
echo

cd /opt/netbox/netbox/netbox/
cp configuration_example.py configuration.py
../generate_secret_key.py > key.txt

echo
echo "Secret key was generated in /opt/netbox/netbox/netbox/key.txt!"
echo "--------------------"
echo








echo
echo "End installing!"
echo "--------------------"


