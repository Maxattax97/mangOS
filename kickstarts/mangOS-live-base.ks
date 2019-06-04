# vim: ft=sh
lang en_US.UTF-8
keyboard us
timezone US/Eastern
authselect select nis
zerombr
clearpart --all
part / --size 6144 --fstype ext4
services --enabled=NetworkManager,ModemManager --disabled==sshd
network --bootproto=dhcp --device=link --activate
rootpw root
#shutdown
eula --agree
firewall --enabled --service=mdns
selinux --enforcing
skipx
user --name=mango --password=mango --plaintext


# Point to the main (non-Rawhide) Fedora repositories.
repo --name=fedora --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=x86_64
repo --name=updates --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f$releasever&arch=x86_64
repo --name=modular --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-modular-$releasever&arch=x86_64
#repo --name=updates-testing --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=updates-testing-f$releasever&arch=x86_64
url --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=x86_64

# Include RPMFusion repositories.
repo --name=rpmfusion-free --mirrorlist=https://mirrors.rpmfusion.org/metalink?repo=free-fedora-$releasever&arch=x86_64
repo --name=rpmfusion-free-updates --mirrorlist=https://mirrors.rpmfusion.org/metalink?repo=free-fedora-updates-released-$releasever&arch=x86_64
repo --name=rpmfusion-nonfree --mirrorlist=https://mirrors.rpmfusion.org/metalink?repo=nonfree-fedora-$releasever&arch=x86_64
repo --name=rpmfusion-nonfree-updates --mirrorlist=https://mirrors.rpmfusion.org/metalink?repo=nonfree-fedora-updates-released-$releasever&arch=x86_64

# Include Google Chrome's Repositories.
repo --name=google --baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64

# Include Copr/external repositories
## Signal Messenger
repo --name=signal-messenger-copr --baseurl=https://copr-be.cloud.fedoraproject.org/results/luminoso/Signal-Desktop/fedora-$releasever-x86_64/
## Albert
repo --name=albert-obs --baseurl=http://download.opensuse.org/repositories/home:/manuelschneid3r/Fedora_Rawhide/

%pre

# Enable fastest mirror for DNF.
echo "fastestmirror=true" >> /etc/dnf/dnf.conf

%end




%packages

@base-x
@guest-desktop-agents
@standard
@core
@networkmanager-submodules
@workstation-product
util-linux-user

# Networking requirements
dhcp-client

kernel
kernel-modules
kernel-modules-extra

# This was added a while ago, I think it falls into the category of
# "Diagnosis/recovery tool useful from a Live OS image".  Leaving this untouched
# for now.
memtest86+

# The point of a live image is to install
anaconda
anaconda-install-env-deps
@anaconda-tools

# Need aajohan-comfortaa-fonts for the SVG rnotes images
aajohan-comfortaa-fonts

# Without this, initramfs generation during live image creation fails: #1242586
dracut-live
syslinux

# anaconda needs the locales available to run for different locales
glibc-all-langpacks

# no longer in @core since 2018-10, but needed for livesys script
initscripts

%end




%post

# turn off firstboot for livecd boots
systemctl --no-reload disable firstboot-text.service
systemctl --no-reload disable firstboot-graphical.service
systemctl stop firstboot-text.service
systemctl stop firstboot-graphical.service

# don't enable the gnome-settings-daemon packagekit plugin
gsettings set org.gnome.software download-updates 'false'

# turn off abrtd on a live image
systemctl --no-reload disable abrtd.service
systemctl stop abrtd.service

# enable tmpfs for /tmp
systemctl enable tmp.mount

%end
