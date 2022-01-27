# Introduction

This project provides a Packer build script and an Ansible playbook to install ArkCase Community Edition on a minimal CentOS distribution.

# Prerequisites to Run the Packer Script and Ansible Plays

Your host desktop must have:

* Packer (<https://www.packer.io>)
* VirtualBox (<https://www.virtualbox.org/>)

# Prerequisites to Run ArkCase

Your host desktop must have:

* VirtualBox (<https://www.virtualbox.org/>)
* Vagrant (<https://www.vagrantup.com/>)

# How to Run ArkCase

This section shows how to run ArkCase using the pre-built Vagrant box.

Create a text file named `Vagrantfile` (no file extension) in an empty folder.  Edit this file to have the following contents:

```
Vagrant.configure("2") do |config|
  config.vm.box = "arkcase/arkcase-ce"
  config.vm.box_version = "3.3.1-r1-a"
  config.vm.box_url = "https://app.vagrantup.com/arkcase/boxes/arkcase-ce"
  config.vm.network "private_network", type: "dhcp"
  config.vm.hostname = "arkcase-ce.local"
  # disable the default synced folder
  config.vm.synced_folder '.', '/vagrant', disabled: true
end
```

The above `Vagrantfile` creates a private network with a DHCP-assigned IP address.

Then run the command `vagrant up` from the same folder where `Vagrantfile` is loaded.  After some time, it should report success. If you see a cryptic SSH-related error message during the download, just re-run `vagrant up`; you may have to do this several times; but eventually the download will succeed and the box will start. 

To find the IP address of your new VM, run this command from a terminal window in the same folder as the Vagrantfile:

`vagrant ssh -c ifconfig`

It should be the IP address associated with the second interface.

Next, update your hosts file with an entry like below:

`192.168.56.15 arkcase-ce.local`

Being careful to replace `192.168.56.15` with the correct IP address as output by the command `vagrant ssh -c ifconfig`.  Note, on Linux and Mac OSX, the hosts file is the file `/etc/hosts`; on Windows, it is `C:\Windows\System32\Drivers\etc\hosts` (or `%SystemDrive%\Windows\System32\Drivers\etc\hosts` in case Windows is not installed on the C drive).

Now you should be able to open the web site `https://arkcase-ce.local/arkcase` in your browser.  You will have to accept the ArkCase HTTPS certificate; your browser will show you a warning since ArkCase CE uses its own root certificate. 

The default admin user is `arkcase-admin@arkcase.org`, password `@rKc@3e`.

## Set Up Outgoing Email

When you create a new user, the new user will receive an email including a reset-password link.  This means that outgoing email must be configured correctly: you must configure ArkCase with a known good email account.  

1. Login to ArkCase as the default admin user (arkase-admin@arkcase.org, @rKc@3e)
2. Click the Admin navigator tag in the left-hand list of modules
3. Click the Security / Document Delivery Policy link (NOT the "Email Configuration" link)
4. Leave the `Server Type` as `SMTP`
5. Update the `Server Address`, `Port`, `Encryption`, `Username`, `Password`, and `From` fields to values that work with your email provider.  If you are an Office 365 user, you only need to update `Username`, `Password`, and `From`.
6. Click the `Validate` button to be sure the new settings work.  If they work OK, click the `Save` button.

## How to Add a New User

1. First, be sure to follow the above instructions to configure ArkCase with a working email configuration.
2. Login to ArkCase as the default admin user (arkcase-admin@arkcase.org, @rKc@3e)
3. Click the Admin navigator tab in the left-hand list of modules
4. Click the Security / Organizational Hierarchy link
5. Click the name of the group to which you want to add the new user (for example, to add another administrator, click the ARKCASE_ADMINISTRATOR@ARKCASE.ORG group
6. Click the "Add New Member" icon (the one with the plus sign)
7. Fill out and submit the form

The new user will get an email with a button to reset their password; after which they can login to ArkCase.

Note, no matter what the user's email address is, they must login as `userid@arkcase.org` where `userid` is the user id you entered into the add-user form.  Users are not able to login using their email address.

# How to Create a New VM and Install ArkCase Yourself

You can install ArkCase on CentOS 7, and on RHEL 8.  For RHEL 8, you must have at least a developer support account with Red Hat (developer accounts are free, but you do need a developer account).

## CentOS 7

This image will be a plain CentOS minimal install, updated to work well with Vagrant and Ansible.  

1. Download Hashicorp's excellent Packer tool from <https://www.packer.io>. Install packer in the appropriate manner for your particular operating system.

2. Clone this repository (the one that contains this README file, namely, https://github.com/ArkCase/arkcase-ce), if you haven't already done so, then open a command line terminal window and cd (change directory) to the `packer` folder of this repository. 

3. Examine the file `centos7.json`.  This file sets the new VM to have 8G RAM (do not lessen this value, but you can make it higher if you want) and 128G disk space (again, you can choose  higher value, but do not choose a lower one).

4. Run the command `/path/to/packer build centos7.json` (being careful replace `/path/to` with the actual path to your `packer` installation, from step 1 above). After some time it should create a Vagrant box image based on the minimal CentOS 7.5 distribution.

5. Select the ArkCase version to deploy, by following this link, https://github.com/ArkCase/ArkCase/releases, to see the list of supported ArkCase versions.  

6. Copy the file `vagrant/Vagrantfile.centos7` to `vagrant/Vagrantfile`

7. Use the commands below to create the Vagrant box.  These commands use Asible to provision all the ArkCase services; it will take some time.

```bash
# replace /path/to/this/repository with the folder where you cloned this repository
cd /path/to/this/repository/vagrant
export VAGRANT_DEFAULT_PROVIDER=virtualbox # for Linux or MacOS
set VAGRANT_DEFAULT_PROVIDER=virtualbox # for Windows
# NOTE: Linux/MacOS users, use export
export ARKCASE_WEBAPP_VERSION=[Your desired version]  # example: export ARKCASE_WEBAPP_VERSION=2021.02
# NOTE: Windows users use set
set ARKCASE_WEBAPP_VERSION=[Your desired version] # example: set ARKCASE_WEBAPP_VERSION=2021.02
vagrant up
```

You may see errors from file downloads timing out; if you see these errors, just run `vagrant provision` and Vagrant will try again; usually it will work the second time.  If you see any other errors please raise a GitHub issue.

When `vagrant up` finishes, the end of the output should look something like this:

```
    default: TASK [Reload firewalld] ********************************************************
    default: skipping: [localhost]
    default: 
    default: PLAY RECAP *********************************************************************
    default: localhost                  : ok=794  changed=501  unreachable=0    failed=0    skipped=148  rescued=0    ignored=1  
```

From here, please skip the below RHEL 8 instructions, and continue with the hostname setup section.

## RHEL 8

1. Clone this repository (the one that contains this README file, namely, https://github.com/ArkCase/arkcase-ce), if you haven't already done so, then open a command line terminal window and cd (change directory) to the `vagrant` folder of this repository.

2. Select the ArkCase version to deploy, by following this link, https://github.com/ArkCase/ArkCase/releases, to see the list of supported ArkCase versions.

3. Copy the file `vagrant/Vagrantfile.rhel8` to `vagrant/Vagrantfile`

4. Use the commands below to create the Vagrant box.  These commands use Asible to provision all the ArkCase services; it will take some time.

```bash
export RH_SUBSCRIPTION_MANAGER_USER="YOUR RED HAT USER ID GOES HERE"
export RH_SUBSCRIPTION_MANAGER_PW="YOUR RED HAT USER PASSWORD GOES HERE"
# replace /path/to/this/repository with the folder where you cloned this repository
cd /path/to/this/repository/vagrant
export VAGRANT_DEFAULT_PROVIDER=virtualbox # for Linux or MacOS
set VAGRANT_DEFAULT_PROVIDER=virtualbox # for Windows
# NOTE: Linux/MacOS users, use export
export ARKCASE_WEBAPP_VERSION=[Your desired version]  # example: export ARKCASE_WEBAPP_VERSION=2021.02
# NOTE: Windows users use set
set ARKCASE_WEBAPP_VERSION=[Your desired version] # example: set ARKCASE_WEBAPP_VERSION=2021.02
vagrant up
```

You may see errors from file downloads timing out; if you see these errors, just run `vagrant provision` and Vagrant will try again; usually it will work the second time.  If you see any other errors please raise a GitHub issue.

When `vagrant up` finishes, the end of the output should look something like this:

```
    default: TASK [Reload firewalld] ********************************************************
    default: skipping: [localhost]
    default:
    default: PLAY RECAP *********************************************************************
    default: localhost                  : ok=794  changed=501  unreachable=0    failed=0    skipped=148  rescued=0    ignored=1
```

## Hostname setup

On your host desktop, ensure that the hostname `arkcase-ce.local` is mapped to the correct IP address.

First, run the following command to find your VirtualBox host only network IP range:

```bash
VBoxManage list hostonlyifs | grep "IPAddress"
```

Example output, showing that on this system, the host-only network has IP addresses starting with 172.28.

```
david@david-ubuntu:~/git/arkcase-ce/vagrant$ VBoxManage list hostonlyifs | grep "IPAddress"
IPAddress:       172.28.128.1
```

Next, list the IP addresses assigned to your Vagrant VM:

```bash
vagrant ssh -c "ifconfig | grep inet | grep -v inet6"
```

Example output:

```
david@david-ubuntu:~/git/arkcase-ce/vagrant$ vagrant ssh -c "ifconfig | grep inet | grep -v inet6"
        inet 10.0.2.15  netmask 255.255.255.0  broadcast 10.0.2.255
        inet 172.28.128.5  netmask 255.255.255.0  broadcast 172.28.128.255
        inet 127.0.0.1  netmask 255.0.0.0
Connection to 127.0.0.1 closed.
```

The above output means that arkcase-ce.local should be mapped to `172.28.128.5` since that is the IP address assigned to the VM that starts with the IP address of the VirtualBox host-only network.

Using whichever way is appropriate for your operating system (e.g. on Linux, update `/etc/hosts`, make sure the IP address is mapped correctly.

## Start ArkCase

To start the ArkCase web application, run the following commands, from the same folder where you ran `vagrant up`:

```bash
# the next two commands start arkcase
vagrant ssh -c "sudo systemctl start config-server"
vagrant ssh -c "sudo systemctl start arkcase"

# this command lets you see the ArkCase log output.  First-time startup will take 10 - 15 minutes.
vagrant ssh -c "sudo tail -f /opt/arkcase/log/arkcase/catalina.out"
```

