#!/usr/bin/env bash

# provision.sh v. 1.18
# (Changelog: https://teampasswordmanager.com/docs/install-vagrant-virtualbox/#changelog)
#
# Ferran Barba, May 2018
# info@teampasswordmanager.com
# https://teampasswordmanager.com
# Updated / Edited - Kat, May 2019
#
# Vagrant shell provisioning file to install the required software to execute Team Password Manager
#
# It installs:
#	- Some linux utilities: curl, unzip, acl, htop, ntp, software-properties-common
#	- Apache 2
#	- MySQL Server 5.7
#	- PHP 7
#	- Ioncube Loader v. 10.1.0
#	- Team Password Manager (latest version)
#	- Firewall (http/s, ssh, ntp, ping)
#	- fail2ban

# Parameters from the Vagrantfile

PARAM_NUM_BITS=$1
PARAM_HOSTNAME=$2
PARAM_SERVER_SWAP=$3
PARAM_SERVER_TIMEZONE=$4
PARAM_MYSQL_ROOT_PASSWORD=$5
PARAM_PHP_TIMEZONE=$6
PARAM_TPM_DATABASE=$7
PARAM_TPM_USER=$8
PARAM_TPM_PASSWORD=$9

# Let's go

echo "* TPM PROVISION BEGIN $(date)"
echo "**********************************************"

echo "* Parameters:"
echo "*   Bits: $PARAM_NUM_BITS"
echo "*   Hostname: $PARAM_HOSTNAME"
echo "*   Server swap: $PARAM_SERVER_SWAP"
echo "*   Server timezone: $PARAM_SERVER_TIMEZONE"
echo "*   PHP timezone: $PARAM_PHP_TIMEZONE"

# ***************** BASE INSTALLATION *****************

# Timezone and locale
echo "**********************************************"
echo "* Setting Timezone to $PARAM_SERVER_TIMEZONE and Locale to C.UTF-8"

sudo ln -sf /usr/share/zoneinfo/$PARAM_SERVER_TIMEZONE /etc/localtime
sudo locale-gen C.UTF-8
export LANG=C.UTF-8

echo "export LANG=C.UTF-8" >> /home/vagrant/.bashrc

# Update
echo "* Updating repositories"
sudo apt-get update

# Some utilities
echo "* Installing some utilities"
sudo apt-get install -qq curl unzip software-properties-common acl htop

# ntp (needed for 2FA). ntp uses port 123/UDP. Show status: ntpq -p
echo "* Installing ntp"
sudo apt-get install -qq ntp

# Set up swap
shopt -s nocasematch
if [[ ! -z $PARAM_SERVER_SWAP && ! $PARAM_SERVER_SWAP =~ false && $PARAM_SERVER_SWAP =~ ^[0-9]*$ ]]; then
	echo "* Setting up Swap ($PARAM_SERVER_SWAP MB)"

	# Create the Swap file
	sudo fallocate -l "$PARAM_SERVER_SWAP"M /swapfile

	# Set the correct Swap permissions
	sudo chmod 600 /swapfile

	# Setup Swap space
	sudo mkswap /swapfile

    # Enable Swap space
    sudo swapon /swapfile

	# Make the Swap file permanent
	echo "/swapfile   none    swap    sw    0   0"

	# Add some swap settings:
	# vm.swappiness=10: Means that there wont be a Swap file until memory hits 90% useage
	# vm.vfs_cache_pressure=50: read http://rudd-o.com/linux-and-free-software/tales-from-responsivenessland-why-linux-feels-slow-and-how-to-fix-that
	printf "vm.swappiness=10\nvm.vfs_cache_pressure=50" | tee -a /etc/sysctl.conf && sysctl -p
fi
shopt -u nocasematch

# ***************** REQUIRED SOFTWARE: APACHE, PHP, MYSQL *****************

# Apache (html files in /var/www/html)
echo "**********************************************"
echo "* Installing and configuring Apache"
sudo apt-get install -qq apache2

# ServerName
echo "ServerName $PARAM_HOSTNAME" | sudo tee /etc/apache2/conf-available/fqdn.conf && sudo a2enconf fqdn

# SSL
sudo make-ssl-cert generate-default-snakeoil --force-overwrite
sudo a2enmod ssl
sudo a2ensite default-ssl.conf
sudo service apache2 restart

# MYSQL Server
echo "**********************************************"
echo "* Installing and configuring MySQL Server"

export DEBIAN_FRONTEND="noninteractive"

# Set username and password to 'root'
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $PARAM_MYSQL_ROOT_PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PARAM_MYSQL_ROOT_PASSWORD"

# Install MySQL Server
sudo apt-get install -qq mysql-server-5.7

# Create database and user for Team Password Manager
MYSQL=`which mysql`
Q1="CREATE DATABASE $PARAM_TPM_DATABASE CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
Q2="GRANT ALL PRIVILEGES ON $PARAM_TPM_DATABASE.* to '$PARAM_TPM_USER' IDENTIFIED BY '$PARAM_TPM_PASSWORD';"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"
$MYSQL -uroot -p$PARAM_MYSQL_ROOT_PASSWORD -e "$SQL"

# PHP
echo "**********************************************"
echo "* Installing PHP"
sudo add-apt-repository -y ppa:ondrej/php
sudo apt-key update
sudo apt-get update
sudo apt-get install -qq php7.0 php7.0-cli php7.0-mysql php7.0-mcrypt php7.0-mbstring php7.0-ldap php7.0-curl php7.0-gd

# Update php.ini to ensure that always_populate_raw_post_data is uncommented and set to -1 (or On)
# This is to maker sure POST API requests work correctly
sudo sed -i 's/;always_populate_raw_post_data = -1/always_populate_raw_post_data = -1/g' "/etc/php/7.0/apache2/php.ini"
sudo sed -i 's/;always_populate_raw_post_data = On/always_populate_raw_post_data = On/g' "/etc/php/7.0/apache2/php.ini"

# ***************** IONCUBE *****************

# Ioncube Loader
echo "**********************************************"
echo "* Installing Ioncube Loader"
cd /usr/lib/php/20151012
wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
tar -xvf ioncube_loaders_lin_x86-64.tar.gz
mv ioncube/* .
rm ioncube_loaders_lin_x86-64.tar.gz
rm -rf ioncube
echo "zend_extension = /usr/lib/php/20151012/ioncube_loader_lin_7.0.so" | sudo tee /etc/php/7.0/apache2/conf.d/01-ioncube.ini

# Restart Apache
sudo service apache2 restart

# ***************** TEAM PASSWORD MANAGER *****************

# Team Password Manager
echo "**********************************************"
echo "* Downloading and preparing Team Password Manager for installation"

# Get the latest version of Team Password Manager and uncompress it in /var/www/html/teampasswordmanager
LATEST_TPM_VERSION=$(curl --silent https://teampasswordmanager.com/latest-version)
cd /vagrant
sudo wget --quiet https://teampasswordmanager.com/assets/download/teampasswordmanager_"$LATEST_TPM_VERSION".zip
sudo unzip teampasswordmanager_"$LATEST_TPM_VERSION".zip -d /var/www/html
sudo mv /var/www/html/teampasswordmanager_"$LATEST_TPM_VERSION"/ /var/www/html/teampasswordmanager
rm teampasswordmanager_"$LATEST_TPM_VERSION".zip # delete downloaded file

# Make site files have user/group www-data (the user that Apache uses)
sudo chown -R www-data:www-data /var/www

# Make user vagrant member of www-data group and make the www folder writable by www-data group too
# Uncomment this if you want the vagrant user to be able to write to /var/www
#sudo usermod -a -G www-data vagrant
#sudo chmod -R 775 /var/www

# Set database, user and password in config.php
sudo sed -i "s/'database'/'tpm_database'/" /var/www/html/teampasswordmanager/config.php
sudo sed -i "s/'user'/'tpm_user'/" /var/www/html/teampasswordmanager/config.php
sudo sed -i "s/'password'/'tpm_password'/" /var/www/html/teampasswordmanager/config.php

# ***************** FIREWALL AND FAIL2BAN *****************

# Firewall (iptables)
echo "**********************************************"
echo "* Creating a firewall"

# Rules: these rules will allow traffic to the following services and ports:
# HTTP (80), HTTPS (443), SSH (22), NTP (123) and ping.
# All other ports will be blocked.
IPTABLES_RULES="
*filter

#  Allow all loopback (lo0) traffic and drop all traffic to 127/8 that doesn't use lo0
-A INPUT -i lo -j ACCEPT
-A INPUT -d 127.0.0.0/8 -j REJECT

#  Accept all established inbound connections
-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

#  Allow all outbound traffic - you can modify this to only allow certain traffic
-A OUTPUT -j ACCEPT

#  Allow HTTP and HTTPS connections from anywhere (the normal ports for websites and SSL).
-A INPUT -p tcp --dport 80 -j ACCEPT
-A INPUT -p tcp --dport 443 -j ACCEPT

#  Allow SSH connections
-A INPUT -p tcp --dport 22 -j ACCEPT

# Allow NTP
-A INPUT -p udp --sport 123 -j ACCEPT

#  Allow ping
-A INPUT -p icmp --icmp-type echo-request -j ACCEPT

#  Log iptables denied calls
-A INPUT -m limit --limit 5/min -j LOG --log-prefix \"iptables denied: \" --log-level 7

#  Drop all other inbound - default deny unless explicitly allowed policy
-A INPUT -j DROP
-A FORWARD -j DROP

COMMIT
"

echo "$IPTABLES_RULES" | sudo tee /etc/iptables.firewall.rules > /dev/null

# Activate now
sudo /sbin/iptables-restore < /etc/iptables.firewall.rules

# Activate rules every time the server starts
FRAS="#!/bin/sh
/sbin/iptables-restore < /etc/iptables.firewall.rules"

echo "$FRAS" | sudo tee /etc/network/if-pre-up.d/firewall > /dev/null

sudo chmod +x /etc/network/if-pre-up.d/firewall

# fail2ban (prevents dictionary attacks on the server)

echo "* Installing fail2ban"

sudo apt-get install -qq fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local


# ***************** ENDING *****************

# **** End
echo "**********************************************"
echo "* System is installed"
echo "* Open your browser and go to:"
echo "*    http://localhost:8080/teampasswordmanager/index.php/install"
echo "* to finish installing Team Password Manager"
echo "**********************************************"
echo "* TPM PROVISION END $(date)"
