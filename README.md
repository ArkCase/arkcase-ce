# Introduction

This project is to build and maintain a Vagrant base box (VirtualBox provider) with a minimal CentOS distribution, and then install ArkCase Community Edition (ArkCase CE) via Ansible packages.

# Prerequisites

Your host desktop must have:

* Packer (<https://www.packer.io>)
* VirtualBox (<https://www.virtualbox.org/>).  

# If You Just Want to Download a Pre-built ArkCase Virtual Machine and Run ArkCase

In this case, create a text file named `Vagrantfile` (no file extension) in an empty folder.  Edit this file to have the following contents:

```
Vagrant.configure("2") do |config|
  config.vm.box = "arkcase/arkcase-ce"
  config.vm.box_version = "3.3.1"
  config.vm.network "private_network", ip: "192.168.56.15"  
end
```

The above `Vagrantfile` assigns the VM a static IP address of `192.168.56.15`, and assumes your host has the default VirtualBox host IP address of `192.168.56.1`.  To verify this will work on your host desktop, run this command on your host:

   `VBoxManage list hostonlyifs | grep "IPAddress"`  (for Linux or MacOS)
   
   `VBoxManage list hostonlyifs | findstr "IPAddress"`  (for Windows)
   
If you see `192.168.56.1` in the output, the default settings shown above will work fine for you.  If you don't see any output at all, then use the VirtualBox user interface to create a new hostonly network, and then run the above command again.  If you see one or more IP addresses, but do not see `192.168.56.1`, then choose one of them, and update your `Vagrantfile` and replace `192.168.56.15` with a valid, unused IP address from this hostonly network.  

Then run the command `vagrant up` from the same folder where `Vagrantfile` is loaded.  After some time, it should report success.

If the default 192.168.56.15 address did not work for you, and you had to update the static IP address in the manner described above), you must take some extra steps.  From a terminal window, run these command from the same folder as the Vagrantfile, being careful to replace MY-NEW-IP-ADDRESS with the same IP address you assigned in the Vagrantfile.

```bash
agrant ssh -c "sed -i 's|192.168.56.15|MY-NEW-IP-ADRESS|g' /etc/hosts"
```

You should be able to open the web site `https://arcase-ce.local/arkcase` in your browser.  You will have to accept the ArkCase self-signed HTTPS certificate; instructions for how to do this vary by browser and operating system; you may have to search online for how to do this on your system.

The default admin user is `admin@arkcase.org`, password `@rKc@3e`.

You can skip the rest of these instructions.

# If You Want to Create the Base CentOS Image and Install ArkCase Yourself

This image will be a plain CentOS minimal install, updated to work well with Vagrant and Ansible.  

1. Download Hashicorp's excellent Packer tool from <https://www.packer.io>. Install packer in the appropriate manner for your particular operating system.

2. Clone this repository (the one that contains this README file, namely, https://github.com/ArkCase/arkcase-ce), if you haven't already done so, then open a command line terminal window and cd (change directory) to the `packer` folder of this repository. 

3. Examine the file `centos7.json`.  This file sets the new VM to have 8G RAM (do not lessen this value, but you can make it higher if you want) and 128G disk space (again, you can choose  higher value, but do not choose a lower one).

4. Examine the file `http/ks.cfg`.  This file configures the new VM to have a static IP address of `192.168.56.15`, with a gateway of `192.168.56.1`.  To verify this will work on your host desktop, run this command on your host:

   `VBoxManage list hostonlyifs | grep "IPAddress"`  (for Linux or MacOS)
   `VBoxManage list hostonlyifs | findstr "IPAddress"`  (for Windows)
   
If you see `192.168.56.1` in the output, the default settings shown above will work fine for you.  If you don't see any output at all, then use the VirtualBox user interface to create a new hostonly network, and then run the above command again.  If you see one or more IP addresses, but do not see `192.168.56.1`, then choose one of them, and update `http/ks.cfg` and replace `192.168.56.1` with the selected address, and replace `192.168.56.15` with a valid IP address from your selected hostonly network; also, replace all other occurrences within this entire repository of `192.168.56.1` and `192.168.56.15` with these same values.  (This means: search for all files containing the strings `192.168.56.1` or `192.156.56.15`, and edit those files to replace these strings with your new IP addresses).

5. Run the command `/path/to/packer build centos7.json` (being careful replace `/path/to` with the actual path to your `packer` installation, from step 1 above). After some time it should create a Vagrant box image based on the minimal CentOS 7.5 distribution.

# Start and Provision the ArkCase CE Vagrant VM

First, decide whether you want to include the ArkCase web application in the Vagrant VM.  To quickly try ArkCase without having to build from source and install the ArkCase webapp locally, then take the first option below to deploy ArkCase within the Vagrant VM.  To develop with the ArkCase source code and build and deploy the ArkCase webapp locally, take the second option below to deploy all other services (Solr, ActiveMQ, Alfresco, etc.), excluding the ArkCase webapp.

## Option 1: Deploy the ArkCase Webapp in the Vagrant VM (self-contained image)

1. Select the ArkCase version to deploy, by following this link, https://github.com/ArkCase/ArkCase/releases, to see the list of supported ArkCase versions.  As of 2019-03-13, version 3.3.0 is the only supported version.

2. Update the file `vagrant/Vagrantfile` in this repository, ensuring that the path to the box image is the same image that you just built in Step 5.  The value should already be correct, if you built according to these instructions, but make sure anyway.

3. Use the commands below to install the Vagrant hosts-updater plugin and create the Vagrant box.  These commands use Asible to provision all the ArkCase services; it will take some time.

```bash
# replace /path/to/this/repository with the folder where you cloned this repository
cd /path/to/this/repository/vagrant
vagrant plugin install vagrant-hostsupdater
export VAGRANT_DEFAULT_PROVIDER=virtualbox # for Linux or MacOS
set VAGRANT_DEFAULT_PROVIDER=virtualbox # for Windows
# NOTE: Linux/MacOS users, use export
export ARKCASE_WEBAPP_VERSION=[Your desired version]  # example: export ARKCASE_WEBAPP_VERSION=3.3.0
# NOTE: Windows users use set
set ARKCASE_WEBAPP_VERSION=[Your desired version] # example: set ARKCASE_WEBAPP_VERSION=3.3.0
vagrant up
```

You may see errors from file downloads timing out; if you see these errors, just run `vagrant provision` and Vagrant will try again; usually it will work the second time.  If you see any other errors please raise a GitHub issue.

## Option 2: Create the Vagrant VM Without the ArkCase Webapp (for Developers to Build ArkCase from Source Locally)

1. Update the file `vagrant/Vagrantfile` in this repository, ensuring that the path to the box image is the same image that you just built in Step 5.  The value should already be correct, if you built according to these instructions, but make sure anyway.

2. Use the commands below to install the Vagrant hosts-updater plugin and create the Vagrant box.  These commands use Asible to provision all the ArkCase services; it will take some time.

```bash
# replace /path/to/this/repository with the folder where you cloned this repository
cd /path/to/this/repository/vagrant
vagrant plugin install vagrant-hostsupdater
export VAGRANT_DEFAULT_PROVIDER=virtualbox # for Linux or MacOS
set VAGRANT_DEFAULT_PROVIDER=virtualbox # for Windows
vagrant up
```

You may see errors from file downloads timing out; if you see these errors, just run `vagrant provision` and Vagrant will try again; usually it will work the second time.  If you see any other errors please raise a GitHub issue.

