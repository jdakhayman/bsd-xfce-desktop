#!/bin/csh
#
# Install Script: Primary Desktop version 0.1.0 ( Last changed on 08/29/15_1:58pm)
#
# This is my Primary script for personal use in my home and my office.
#
# It is based on FreeBSD 10.2-RELEASE and using both ports and pre-built binaries.
#
# This script uses Xfce 4.12 as the Desktop Enviroment
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
/dev/gpt/swap0          none            swap    sw              0       0\
proc                    /proc           procfs  rw              0       0\
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
powerd_flags="-a hiadaptive -b adaptive"\
\
# Networking startup and hostname.\
hostname="fletcher-1.lan"\
background_dhclient="YES" \
network_interfaces="em0"\
ifconfig_em0="DHCP"\
\
# Stuff to startup, or to keep from starting\
# Disable syslogs to remote devices.\
syslogd_flags="-ss"\
# Start ntp and sync the clock.\
ntpd_enable="YES"\
ntpd_sync_on_start="YES"\
# Services needed by the desktop.\
dbus_enable="YES"\
mixer_enable="YES"\
# Disable line printer daemon. Dont need it.\
lpd_enable="NO"\
# This script is for a desktop. Dont need this.\
sendmail_enable="NONE"\
sendmail_submit_enable="NO"\
sendmail_outbound_enable="NO"\
sendmail_msp_queue_enable="NO"\
# Remember to do file checks, but in the back ground please.\
fsck_y_enable="YES"\
background_fsck="YES"\
# Clear out the /tmp folder on reboots.\
clear_tmp_enable="YES"\
# Secondary Programs.\
' > /etc/rc.conf

# Setup /boot/loader.conf
echo 'Setup /boot/loader.conf'
cat << EOF >> /boot/loader.conf
#Boot-time drivers
linux_load="YES"
nvidia_load="YES"
# Boot-time kernel tuning
kern.vty=vt
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
#Required for chrome
kern.ipc.shm_allow_removed=1
# Disable PC Speaker
hw.syscons.bell=0
EOF

#####################
#  PKGNG            #
#####################
# Bootstrapping / installing pkgng on FreeBSD unattended and 
# without answering Yes.
echo 'Bootstrapping / installing pkgng on FreeBSD unattended and without answering Yes.'
env ASSUME_ALWAYS_YES=YES pkg bootstrap

# Update pkgng repo on local system
echo 'Update pkgng repo on local system'
pkg update -f

# Setup pkgng pkg.conf to answer yes always when installing packages.
echo 'Setup pkgng pkg.conf to answer yes always when installing packages.'
cp /usr/local/etc/pkg.conf.sample /usr/local/etc/pkg.conf

sed -i.bak -e 's|#ASSUME_ALWAYS_YES = false;|ASSUME_ALWAYS_YES = true;|' /usr/local/etc/pkg.conf

# Load linux kernel module so packages that want it on install dont complain.
echo 'Loading linux kernel module'
kldload linux

# Install packages for desktop use.
pkg install xorg-server xf86-input-keyboard xf86-input-mouse xinit xauth nvidia-driver nvidia-xconfig slim slim-themes xfce xfce4-weather-plugin xfce4-power-manager xfce4-mixer ristretto xscreensaver firefox filezilla zathura-pdf-poppler cdrtools

####################
#  Ports Stuff     #
####################
# Fetch portstree, extract, and update
echo 'Fetch ports tree so we can build the few ports that are not available as packages or the options dont suit me.'
portsnap fetch extract update

# Install what few ports that are not available as packages.
# Install automount
echo 'Installing automout'
make -C /usr/ports/sysutils/automount/ install clean disclean

# Install mplayer
echo 'Installing Mplayer media player'
make -C /usr/ports/multimedia/mplayer/ install clean disclean

# Insatll lame mp3 encoder
echo 'Installing Lame mp3 Encoder'
make -C /usr/ports/audio/lame/ install clean distclean

# Rehash so shell will see new binarys that have been installed
echo ' Rehashing so the shell will see the new binaries'
rehash 

###########################
# Reverse auto yes for pkg# 
###########################
echo 'Reverse always yes for pkgng from intial package install so I dont have to later cause I will forget.'
sed -i.bak -e 's|ASSUME_ALWAYS_YES = true;|ASSUME_ALWAYS_YES = false;|' /usr/local/etc/pkg.conf


####################
#  Xorg            # 
####################
# Load nvidia kernel module
echo 'Loading nvidia kernel module'
kldload nvidia
# Use the nvidia-xconfig utility to make and setup the inital xorg config file.
# I know, it's a cheat.
echo 'Use the nvidia-xconfig utility to make and setup the inital xorg config file.'
nvidia-xconfig

####################
#Slim Setup        #
####################
# Setup Slim by coping the sample file over.
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
echo 'Download some cool backgrounds and icon images and place them in the proper directories.'
fetch -o /usr/local/share/backgrounds/xfce/a_1600x900.jpg  http://www.broadstreetchurchofchrist.org/images/a_1600x900.jpg

fetch -o /usr/local/share/pixmaps/Freebsd-logo.png http://www.broadstreetchurchofchrist.org/images/Freebsd-logo.png


#######################
#  Add user and keys  #
#######################
adduser

echo 'Copying ssh keys into .ssh so I can sftp into NAS and download my'
echo 'home directory'

mkdir /usr/home/jda/.ssh
chmod 700 /usr/home/jda/.ssh
chown jda:jda /usr/home/jda/.ssh

cp /media/id_rsa /usr/home/jda/.ssh
chmod 600 /usr/home/jda/.ssh/id_rsa
chown jda:jda /usr/home/jda/.ssh/id_rsa

cp /media/janderson.ppk /usr/home/jda/.ssh
chmod 600 /usr/home/jda/.ssh/janderson.ppk
chown jda:jda /usr/home/jda/.ssh/janderson.ppk

echo 'Log off; Then back on as your new user and downlod your home directory; Reboot'
