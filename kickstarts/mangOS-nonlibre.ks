# vim: ft=sh
%include kickstarts/mangOS-common.ks

%packages

#fedora-workstation-repositories
# Google Chrome
# WPS Office
# Nvidia drivers
# AMGGPU Pro drivers?
google-chrome-stable

# Not sure why this is being included anywa.
-@libreoffice

%end

%post

# https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
#dnf config-manager --set-enabled google-chrome
#dnf install -y google-chrome-stable

#selected group: core
#selected group: base-x
#selected group: guest-desktop-agents
#selected group: fonts
#selected group: multimedia
#selected group: hardware-support
#selected group: printing
#selected group: anaconda-tools
#selected group: gnome-desktop
#selected group: networkmanager-submodules
#selected group: workstation-product
#excluding package: 'reiserfs-utils'
#excluding packag`

%end
