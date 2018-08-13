# Introduction

This project is to build and maintain a Vagrant base box (VirtualBox provider) with a minimal CentOS distribution, and then install ArkCase Community Edition (ArkCase CE) via Ansible packages.

# Create the Base CentOS Image

This image will be a plain CentOS minimal install, with a few changes so it will work with Vagrant and Ansible.  Our goal is to do the least amount of work possible for the box to work with Vagrant and Ansible.

1. Download desired CentOS minimal ISO (https://www.centos.org/download)

2. Run `box-builder/scripts/build-vm.sh`.  The VM must have at least 8G RAM, at least 128G disk space, and at least 2 CPUs.  Example: ` ./build-vm.sh -n "ArkCase CE" -i /path/to/CentOS-7-x86_64-Minimal-1804.iso -m 8192 -s 131072 -c 2`

3. So far I didn't find a way to automate the CentOS installation.  Start the new VM through the VirtualBox UI and install CentOS in the normal way.
    * Make sure the host name is `acm-arkcase`
    * Make sure both network interfaces are enabled (configured to start automatically)
    * For the disk space partitioning, make sure /opt has its own partition, with a sizable amount of space.  Based on a 128G disk, something like this: 
        1. /opt: 64 GiB
        2. /home: 23 GiB
        3. /boot: 1024 MiB
        4. /: 32 GiB
        5. swap: 8064 MiB
    * Root password: standard Armedia STIG password
    * User: name "ArkCase User", userid arkuser, password arkuser
    * When prompted, click Reboot button to complete the installation
    
4. Login as root

5. Install Ansible: `yum -y install ansible`

6. Vagrant support
    * Set the SSH `UseDNS` option to `no`: 
        1. Edit the file `/etc/ssh/sshd_config`
        2. Add the line `UseDNS no`
        3. Save and close the file
    * Create a user with id `vagrant`, password `vagrant`
    * Grant the `vagrant` user passwordless sudo: `echo "vagrant ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers`
    * Add the recognized Vagrant public key to ~/vagrant/.ssh/authorized_keys:

    ```bash
    mkdir /home/vagrant/.ssh
    chmod 0700 /home/vagrant/.ssh
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key" >> /home/vagrant/.ssh/authorized_keys
    chmod 0600 /home/vagrant/.ssh/authorized_keys
    ```

7. VirtualBox Guest Additions
    * From VirtualBox menu, select Devices / Insert Guest Additions CD Image ...
    * In the virtual machine, as root user: 
    
    ```bash
    mount /dev/cdrom /mnt
    cd /mnt
    ./VBoxLinuxAdditions.run
    ```
    
    Most likely you will have to install some kernel packages, development tools, and support packages; be guided by the error messages, until `./VboxLinuxAddtions.run` works.
    
8. Cleanup
    * yum clean all ; rm -rf /var/cache/yum
    
9. Create the Core Base Box
    * `vagrant package --base "The name of the VirtualBox VM" --output arkcase-ce.box`
    
    
# Provision an ArkCase CE Virtualbox VM

```bash
cd vagrant
VAGRANT_DEFAULT_PROVIDER=virtualbox vagrant up
```

Note, you may have to edit the `Vagrantfile` to correct the path to the arkcase-ce.box file, which you should have just created in the above steps.
