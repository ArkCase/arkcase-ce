# Introduction

This project is to build and maintain a Vagrant base box (VirtualBox provider) with a minimal CentOS distribution, and then install ArkCase Community Edition (ArkCase CE) via Ansible packages.

# Prerequisites

Your host desktop must have:

* Ansible 2.7.1 or higher (<https://www.ansible.com/>)
* Packer (<https://www.packer.io>)
* VirtualBox (<https://www.virtualbox.org/>).  

# Create the Base CentOS Image

This image will be a plain CentOS minimal install, with a few changes so it will work with Vagrant and Ansible.  Our goal is to do the least amount of work possible for the box to work with Vagrant and Ansible.

1. Download Hashicorp's excellent Packer tool from <https://www.packer.io>. Install packer in the appropriate manner for your particular operating system.

2. Clone this repository, if you haven't already done so, then open a command line terminal window and cd (change directory) to the `packer` folder of this repository. 

3. Examine the file `centos7.json`.  This file sets the new VM to have 8G RAM (do not lessen this value, but you can make it higher if you want) and 128G disk space (again, you can choose  higher value, but do not choose a lower one).  

4. Examine the file `http/ks.cfg`.  This file configures the new VM to have a static IP address of 192.168.56.15, with a gateway of 192.168.56.1.  To verify this will work on your host desktop, run this command on your host:

   `VBoxManage list hostonlyifs | grep "IPAddress"`  (for Linux or MacOS)
   `VBoxManage list hostonlyifs | findstr "IPAddress"`  (for Windows)
   
If you see `192.168.56.1` in the output, the default settings shown above will work fine for you.  If you don't see any output at all, then use the VirtualBox user interface to create a new hostonly network, and then run the above command again.  If you see one or more IP addresses, but do not see `192.168.56.1`, then choose one of them, and update `http/ks.cfg` and replace `192.168.56.1` with the selected address, and replace `192.168.56.15` with a valid IP address from your selected hostonly network; also, replace all other occurrences within this entire repository of `192.168.56.1` and `192.168.56.15` with these same values.

5. Run the command `/path/to/packer build centos7.json` (being careful to use the full path to Hashicorp Packer, to avoid accidentally calling other utilities that may also be named "packer").  After some time it should create a Vagrant box image based on the minimal CentOS 7.5 distribution.

# Start and Provision the ArkCase CE Vagrant VM

1. Update the file `vagrant/Vagrantfile` in this repository, ensuring that the path to the box image is the same image that you just built in Step 5.  The value should already be correct, if you built according to these instructions, but make sure anyway.

2. Install the Vagrant hosts-updater plugin, and start the box.  This will call a set of Ansible roles to provision all the ArkCase services; it will take some time.

```bash
cd /path/to/this/repository/vagrant
vagrant plugin install vagrant-hostsupdater
export VAGRANT_DEFAULT_PROVIDER=virtualbox # for Linux or MacOS
set VAGRANT_DEFAULT_PROVIDER=virtualbox # for Windows
vagrant up
```

You may see errors from file downloads timing out; if you see these errors, just run `vagrant provision` and Vagrant will try again; usually it will work the second time.  If you see any other errors please raise a GitHub issue.


