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

4. Examine the file `http/ks.cfg`.  This file configures the new VM to have a static IP address of `192.168.56.15`, with a gateway of `192.168.56.1`.  To verify this will work on your host desktop, run this command on your host:

   `VBoxManage list hostonlyifs | grep "IPAddress"`  (for Linux or MacOS)
   `VBoxManage list hostonlyifs | findstr "IPAddress"`  (for Windows)
   
If you see `192.168.56.1` in the output, the default settings shown above will work fine for you.  If you don't see any output at all, then use the VirtualBox user interface to create a new hostonly network, and then run the above command again.  If you see one or more IP addresses, but do not see `192.168.56.1`, then choose one of them, and update `http/ks.cfg` and replace `192.168.56.1` with the selected address, and replace `192.168.56.15` with a valid IP address from your selected hostonly network; also, replace all other occurrences within this entire repository of `192.168.56.1` and `192.168.56.15` with these same values.  (This means: search for all files containing the strings `192.168.56.1` or `192.156.56.15`, and edit those files to replace these strings with your new IP addresses).

5. Run the command `/path/to/packer build centos7.json` (being careful replace `/path/to` with the actual path to your `packer` installation, from step 1 above). After some time it should create a Vagrant box image based on the minimal CentOS 7.5 distribution.

# Start and Provision the ArkCase CE Vagrant VM

First, decide whether you want to include the ArkCase web application in the Vagrant VM.  To quickly try ArkCase without having to build from source and install the ArkCase webapp locally, then take the first option below to deploy ArkCase within the Vagrant VM.  To develop with the ArkCase source code and build and deploy the ArkCase webapp locally, take the second option below to deploy all other services (Solr, ActiveMQ, Alfresco, etc.), excluding the ArkCase webapp.

## Option 1: Deploy the ArkCase Webapp in the Vagrant VM (self-contained image)

1. Select the ArkCase version to deploy, by following this link, https://github.com/ArkCase/ArkCase/releases, to see the list of supported ArkCase versions.  

2. Update the file `vagrant/Vagrantfile` in this repository, ensuring that the path to the box image is the same image that you just built in Step 5.  The value should already be correct, if you built according to these instructions, but make sure anyway.

3. Use the commands below to create the Vagrant box.  These commands use Asible to provision all the ArkCase services; it will take some time.

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

