#!/bin/sh

yum -y install epel-release

yum -y upgrade

yum -y group install "Development Tools"

yum -y install deltarpm ansible bzip2 tar kernel-devel kernel-devel-`uname -a | awk '{ print $3 }'`

echo "Mounting guest additions"
mount -t iso9660 -o loop VBoxGuestAdditions_`cat .vbox_version`.iso /mnt
cd /mnt
echo "Building guest additions"
./VBoxLinuxAdditions.run

# Add vagrant user to sudoers.
echo "vagrant        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

# sshd no dns... helps "vagrant ssh" work a little faster
echo "UseDNS no" >> /etc/ssh/sshd_config

# vagrant known public key
mkdir /home/vagrant/.ssh
chmod 0700 /home/vagrant/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key" >> /home/vagrant/.ssh/authorized_keys
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh/

