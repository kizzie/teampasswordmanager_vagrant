# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile v. 1.17
# (Changelog: https://teampasswordmanager.com/docs/install-vagrant-virtualbox/#changelog)
#
# Ferran Barba, May 2018
# info@teampasswordmanager.com
# https://teampasswordmanager.com
#
# This Vagrantfile installs a virtual machine with Ubuntu 14.04 and provisions it using provision.sh (in the same folder)

# ***************** CONFIGURATION VARIABLES *****************
# More information: https://teampasswordmanager.com/docs/install-vagrant-virtualbox/#technical-explanation-options

# Operating system
num_bits		= 64 		# Options: 64 (for trusty64) or 32 (for trusty32)

# Server
hostname 		= "teampasswordmanager"
server_cpus 	= "1"   	# Cores
server_memory 	= "1024" 	# In MB
server_swap 	= "2048" 	# Options: false | int (MB) - Guideline: Between one or two times the server_memory

# UTC        for Universal Coordinated Time
# EST        for Eastern Standard Time
# US/Central for American Central
# US/Eastern for American Eastern
server_timezone	= "UTC"

# Mysql
mysql_root_password	= "root" # Mysql user = "root"

# PHP
php_timezone = "UTC" # http://php.net/manual/en/timezones.php

# Team Password Manager Database
tpm_database	= "tpm_database"
tpm_user		= "tpm_user"
tpm_password 	= "tpm_password"

# ***************** END CONFIGURATION VARIABLES *****************

VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

	# Ubuntu 14.04 LTS
  config.vm.box = "ubuntu/xenial" + (num_bits == 32 ? "32" : "64")

  config.vm.network "private_network", ip: "192.168.50.4"
	# Set port forwarding
	config.vm.network "forwarded_port", guest: 80, host: 8080
	config.vm.network "forwarded_port", guest: 443, host: 8443
	# Example Public (bridged) networking: config.vm.network "public_network", ip: "192.168.0.17"
	# Example Private networking: config.vm.network "private_network", ip: "192.168.22.17"

	# Set hostname
	config.vm.hostname = hostname

	# Virtualbox settings
	config.vm.provider :virtualbox do |vb|
		vb.name = "TeamPasswordManager"

		# Set server cpus
		vb.customize ["modifyvm", :id, "--cpus", server_cpus]

		# Set server memory
		vb.customize ["modifyvm", :id, "--memory", server_memory]

		# Set the timesync threshold to 10 seconds, instead of the default 20 minutes.
		# If the clock gets more than 15 minutes out of sync (due to your laptop going
		# to sleep for instance, then some 3rd party services will reject requests.
		vb.customize ["guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 10000]
	end

	# Prevent "stdin: is not a tty" notice
	config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

	# Shell provisioner
	config.vm.provision "shell", path: "provision.sh", args: [num_bits, hostname, server_swap, server_timezone, mysql_root_password, php_timezone, tpm_database, tpm_user, tpm_password]
end
