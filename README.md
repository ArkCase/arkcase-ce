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

## Temporary Fix for Outgoing Email

When you create a new user, the new user will receive an email including a reset-password link.  This means that outgoing email must be configured correctly: you must configure ArkCase with a known good email account.  In this release of ArkCase you must take some manual steps:

1. Run the command `vagrant ssh` from the same folder as the Vagrantfile, this will start a command session inside the vm.
2. Run the command `sudo su - arkcase -s /bin/bash` to become the ArkCase user.
3. Copy the below text to a working file using the editor of your choice, and replace the `encryption`, `host`, `userFrom`, `port`, `username`, and `password` elements with the correct information for your mail system.  The values for `encryption`, `host`, and `port` are valid for Outlook 365; so if you are using Outlook 365 you only need to update `userFrom`, `username` and `password`:
```
cat <<EOF > /home/arkcase/.arkcase/acm/acm-config-server-repo/arkcase-runtime.yaml
email:
  sender:
    type: "smtp"
    encryption: starttls
    allowAttachments: true
    allowDocuments: true
    host: "smtp.office365.com"
    allowHyperlinks: true
    userFrom: "david.miller@armedia.com"
    port: 587
    username: "dmiller@armedia.com"
    password: ""
    convertDocumentsToPdf: false
EOF
```
4. Copy the updated text above (now including the username, password, and email host information that is valid for your system) to your command terminal from Step 2 above, and press `Enter` key; this will copy the text to the file /home/arkcase/.arkcase/acm/acm-config-server-repo/arkcase-runtime.yaml.
5. Run the command `exit` to exit your session as `arkcase` and return to your session as `vagrant`.
6. Restart ArkCase by running this command: `sudo systemctl stop arkcase ; sudo systemctl start arkcase`

## How to Add a New User

Before adding a new user, you must follow the above instructions to configure ArkCase with a working email configuration.

1. Login to ArkCase as the default admin user (arkcase-admin@arkcase.org, @rKc@3e)
2. Click the Admin navigator tab in the left-hand list of modules
3. Click the Security / Organizational Hierarchy link
4. Click the name of the group to which you want to add the new user (for example, to add another administrator, click the ARKCASE_ADMINISTRATOR@ARKCASE.ORG group
5. Click the "Add New Member" icon (the one with the plus sign)
6. Fill out and submit the form

The new user will get an email with a button to reset their password; after which they can login to ArkCase.

Note, no matter what the user's email address is, they must login as `userid@arkcase.org` where `userid` is the user id you entered into the add-user form.  Users are not able to login using their email address.

# How to Create the Base CentOS Image and Install ArkCase Yourself

This image will be a plain CentOS minimal install, updated to work well with Vagrant and Ansible.  

1. Download Hashicorp's excellent Packer tool from <https://www.packer.io>. Install packer in the appropriate manner for your particular operating system.

2. Clone this repository (the one that contains this README file, namely, https://github.com/ArkCase/arkcase-ce), if you haven't already done so, then open a command line terminal window and cd (change directory) to the `packer` folder of this repository. 

3. Examine the file `centos7.json`.  This file sets the new VM to have 8G RAM (do not lessen this value, but you can make it higher if you want) and 128G disk space (again, you can choose  higher value, but do not choose a lower one).

4. Run the command `/path/to/packer build centos7.json` (being careful replace `/path/to` with the actual path to your `packer` installation, from step 1 above). After some time it should create a Vagrant box image based on the minimal CentOS 7.5 distribution.

# Start and Provision the ArkCase CE Vagrant VM

First, decide whether you want to include the ArkCase web application in the Vagrant VM.  To quickly try ArkCase without having to build from source and install the ArkCase webapp locally, then take the first option below to deploy ArkCase within the Vagrant VM.  To develop with the ArkCase source code and build and deploy the ArkCase webapp locally, take the second option below to deploy all other services (Solr, ActiveMQ, Alfresco, etc.), excluding the ArkCase webapp.

## Option 1: Deploy the ArkCase Webapp in the Vagrant VM (self-contained image)

1. Select the ArkCase version to deploy, by following this link, https://github.com/ArkCase/ArkCase/releases, to see the list of supported ArkCase versions.  

2. Update the file `vagrant/Vagrantfile` in this repository, ensuring that the path to the box image is the same image that you just built in Step 4 of "How to Create the Base CentOS Image and Install ArkCase Yourself" above.  The value should already be correct, if you built according to these instructions, but make sure anyway.

3. Use the commands below to create the Vagrant box.  These commands use Asible to provision all the ArkCase services; it will take some time.

```bash
# replace /path/to/this/repository with the folder where you cloned this repository
cd /path/to/this/repository/vagrant
vagrant plugin install vagrant-hostsupdater
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

4. Ensure that the hostname `arkcase-ce.local` is mapped to the correct IP address.

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

5. Start the ArkCase application

To start the ArkCase web application, run the following command, from the same folder where you ran `vagrant up`:

```bash
# the next two commands start arkcase
vagrant ssh -c "sudo systemctl start config-server"
vagrant ssh -c "sudo systemctl start arkcase"

# this command lets you see the ArkCase log output.  First-time startup will take 10 - 15 minutes.
vagrant ssh -c "sudo tail -f /opt/arkcase/log/arkcase/catalina.out"
```

## Option 2: Create the Vagrant VM Without the ArkCase Webapp (for Developers to Build ArkCase from Source Locally)

1. Update the file `vagrant/Vagrantfile` in this repository, ensuring that the path to the box image is the same image that you just built in Step 5.  The value should already be correct, if you built according to these instructions, but make sure anyway.

2. Use the commands below to create the Vagrant box.  These commands use Asible to provision all the ArkCase services; it will take some time.

```bash
# replace /path/to/this/repository with the folder where you cloned this repository
cd /path/to/this/repository/vagrant
vagrant plugin install vagrant-hostsupdater
export VAGRANT_DEFAULT_PROVIDER=virtualbox # for Linux or MacOS
set VAGRANT_DEFAULT_PROVIDER=virtualbox # for Windows
vagrant up
```

You may see errors from file downloads timing out; if you see these errors, just run `vagrant provision` and Vagrant will try again; usually it will work the second time.  If you see any other errors please raise a GitHub issue.

