TPM-Vagrant for VirtualBox
--------------------------

TPM-Vagrant for VirtualBox Vagrantfile and shell provisioning script to install Team Password Manager in a VirtualBox virtual machine.

TPM-Vagrant installs a Linux Ubuntu 14.04 LTS in a VirtualBox virtual machine with the following components:

- Some linux utilities: curl, unzip, acl, htop, ntp, software-properties-common
- Apache 2 
- MySQL Server 5
- PHP 5.6
- Ioncube Loader
- Team Password Manager (latest version)
- Firewall (http/s, ssh, ntp, ping)
- fail2ban

(See the changelog for changes on these components: http://teampasswordmanager.com/docs/install-vagrant-virtualbox/#changelog)

TPM-Vagrant runs on any system that can execute VirtualBox and Vagrant (OS X, Linux, Windows).

Instructions:

1. Install a recent version of Virtual Box (https://www.virtualbox.org/).
2. Install a recent version of Vagrant (https://www.vagrantup.com/).
3. Create a folder on your computer where you want to place the virtual machine.
4. Decompress the tpm_vagrant zip file and copy the following files to the folder created in the previous step: Vagrantfile and provision.sh
5. Optional: change configuration variables in Vagrantfile. Read this for more information: http://teampasswordmanager.com/docs/install-vagrant-virtualbox/#technical-explanation-options
6. On the command line, go to the folder created in step 3 and execute: vagrant up. This will execute the provisioning process. It will take several minutes to complete.
7. When the process finishes, complete the installation of Team Password Manager by opening this URL on your browser: http://localhost:8080/teampasswordmanager/index.php/install

For more information read: http://teampasswordmanager.com/docs/install-vagrant-virtualbox/

Ferran Barba
info@teampasswordmanager.com
January 2015