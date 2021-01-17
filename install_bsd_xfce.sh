#!/bin/sh
#
# This is my Primary script for personal use in my home and my office.
#
# It is based on FreeBSD Lasterst releng and using both ports and Project pre-built binaries.
#
# This script uses Xfce lastest version as the Desktop Enviroment.
#
# It is, as it stands now, very customized to my personal needs
# and has gone though several versions even before I started to
# number it. It's beginning purpose was for a rapid
# reinstall of a gui or rapid deployment on multiple machines in a
# small office.
#
# But as I worked on it, this script became more custom for my setup.
# Alter it as needed to fit your needs.
#
#
# As can be seen I have opted for a full desktop in xfce along with a few
# extra things that I prefer.
#
# This is not considered a light-weight install, but dependent on 
# the stuff you install you can keep your package count below 400.              
# That's not to bad imho.
#
#####################
# Location and lang #
#####################
# Setup language for all users made on system
# Skel/login_conf
echo 'Setup language for all users made on system Skel/login_conf'

cat << EOF >> /usr/share/skel/dot.login_conf
me:\
   :charset=UTF-8:\
   :lang=en_US.UTF-8:
EOF

#################################################
# Base system setup. fstab, rc, loader, sysctl, #
#################################################
# Clear out default  fstab and replace with custom fstab
echo 'Clear out default  fstab and replace with custom fstab'
cp /dev/null /etc/fstab
echo '\
# Device                Mountpoint      FStype  Options         Dump    Pass#\
/dev/ada0p2             none            swap    sw              0       0\
' > /etc/fstab

# Setup /etc/rc.conf
echo 'Clear out default rc.conf and replace with custom rc.conf'
cp /dev/null /etc/rc.conf

# Change this to match your machine setup.
echo 'Write Johns machine specific custom rc.conf to file.'
echo '\
# File System and CPU\
zfs_enable="YES"\
powerd_enable="YES"\
powerd_flags="-a hiadaptive -b adaptive -n adaptive"\
performance_cx_lowest="Cmax"\
economy_cx_lowest="Cmax"\
\
# Networking startup and hostname.\
hostname="fletcher-2.lan"\
background_dhclient="YES" \
wlans_iwn0="wlan0"\
ifconfig_wlan0="WPA DHCP"\
create_args_wlans0="country US regdomain FCC"\
\
# Stuff to startup, or to keep from starting\
# Disable syslogs to remote devices.\
syslogd_flags="-ss"\
# Start ntp and sync the clock.\
ntpdate_enable="YES"\
ntpd_enable="YES"\
ntpd_sync_on_start="YES"\
# Services needed by the desktop.\
dbus_enable="YES"\
mixer_enable="YES"\
moused_enable="YES"\
moused_flags="-VH"\
# Disable line printer daemon. Dont need it.\
lpd_enable="NO"\
# This script is for a desktop. Dont want this.\
sendmail_enable="NONE"\
sendmail_submit_enable="NO"\
sendmail_outbound_enable="NO"\
sendmail_msp_queue_enable="NO"\
# Remember to do file checks, but in the back ground please.\
fsck_y_enable="YES"\
background_fsck="YES"\
# Clear out the /tmp folder on reboots.\
clear_tmp_enable="YES"\
Xorgclear_tmp_enable="YES"\
# Secondary Programs.\
' > /etc/rc.conf

# Setup /boot/loader.conf
cat << EOF >> /boot/loader.conf
#Boot-time drivers
i915kms_load="YES"
acpi_ibm_load="YES"                                                                                                                                                                                                  
acpi_video_load="YES"
# Boot-time kernel tuning for memory and power consumption.
drm.i915.enable_rc6=7
kern.ipc.shmseg=1024
kern.ipc.shmmni=1024
kern.maxproc=10000 
EOF

# Setup /etc/sysctl.conf
echo 'Setup /etc/sysctl.conf'
cat << EOF >> /etc/sysctl.conf
# Enhance shared memory X11 interface
# grep memory /var/run/dmesg.boot
kern.ipc.shmmax=35148267520
# kern.ipc.shmmax / 4096
kern.ipc.shmall=8581120
# Enhance desktop responsiveness under high CPU use (200/224)
kern.sched.preempt_thresh=224
# Bump up maximum number of open files
kern.maxfiles=200000
# Disable PC Speaker
hw.syscons.bell=0
EOF

#####################
#  PKGNG            #
#####################
# In FreeBSD 10.2 the pkg repo is set to quarterly. I prefer to stay on latest.
# See https://forums.freebsd.org/threads/52843/ 
echo 'In FreeBSD 10.2 and forward the pkg repo is set to quarterly. I prefer to stay on latest.'
echo 'Make directory for the new file as descrbed in /etc/pkg/FreeBSD.conf'

mkdir -p /usr/local/etc/pkg/repos

echo 'Write file.'
cat << EOF >>  /usr/local/etc/pkg/repos/FreeBSD.conf
FreeBSD:{
  url: "pkg+http://pkg.FreeBSD.org/\${ABI}/latest"
}
EOF

# Set enviroment varible to allow bootstrapping / installing pkgng  
# on FreeBSD unattended and without answering Yes.
echo 'Bootstrapping / installing pkgng on FreeBSD unattended and without answering Yes.'
env ASSUME_ALWAYS_YES=YES pkg bootstrap


# Update pkgng repo on local system
echo 'Update pkgng repo on local system'
pkg update -f

# Load linux kernel module so packages that want it on install dont complain.
echo 'Loading linux kernel module'
kldload linux

# Install packages for desktop use.
pkg install xorg-server xf86-video-intel xf86-input-keyboard xf86-input-mouse xinit xauth slim slim-themes xfce xfce4-weather-plugin xfce4-power-manager xfce4-mixer ristretto xscreensaver firefox filezilla zathura-pdf-poppler

####################
#Slim Setup        #
####################
# Setup Slim by copying the sample file over.
echo 'Copy slim config file from default.'
cp /usr/local/etc/slim.conf.sample /usr/local/etc/slim.conf

# Set slim to use ttys to start itself instead of using rc.conf slim_enable="YES"
echo 'Set slim to use ttys to start itself instead of using rc.conf'
sed -i.bak -e 's|ttyv8	"/usr/local/bin/xdm -nodaemon"	xterm	off secure|ttyv8   "/usr/local/bin/slim"   	xterm   on  secure|' /etc/ttys

# This is only for me. I would remove this sed statment for a community machine.
sed -i.bak -e 's|#default_user        simone|default_user        jda|' -e 's|#auto_login          no|auto_login          yes|' -e 's|current_theme       default|current_theme       fbsd|' /usr/local/etc/slim.conf

#####################
# Setup xfce to start 
#####################
# This will make the .xinitrc file copy to every users folder upon creation. This is okay due to
# no other DE or WM are allowed on the system.
# Skel/dot.xinitrc
echo 'Make xfce xinitrc file copy to every user upon creation.'
cp /usr/local/etc/xdg/xfce4/xinitrc /usr/share/skel/dot.xinitrc


# Download some cool backgrounds and icon images and place them in the proper directories.
# echo 'Download some cool backgrounds and icon images and place them in the proper directories.'
# fetch -o /usr/local/share/backgrounds/xfce/a_1600x900.jpg  https://ander-son.net/images/a_1600x900.jpg

# fetch -o /usr/local/share/pixmaps/Freebsd-logo.png https://ander-son.net/images/Freebsd-logo.png
