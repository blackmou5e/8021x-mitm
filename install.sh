#!/bin/bash

#adding repo for nic firmare
echo 'deb http://mirror.yandex.ru/debian/ stretch main non-free' >> /etc/apt/sources.list

#installing tools for 802.1x auth
apt update
apt install wpasupplicant firmware-realtek debhelper screen tcpdump sudo
usermod -a -G sudo sniff

#installing custom kernel for apropriate bridge-networking in 802.1x enviroment
dpkg -i kernel-amd64/linux-compiler-gcc-6-x86_4.11.3-10_amd64.deb
dpkg -i kernel-amd64/linux-kbuild-4.11_4.11.3-10_amd64.deb
dpkg -i kernel-amd64/linux-headers-4.11.3-common_4.11.3-10_all.deb
dpkg -i kernel-amd64/linux-headers-4.11.3-amd64-desktop_4.11.3-10_amd64.deb
dpkg -i kernel-amd64/linux-image-4.11.3-amd64-desktop_4.11.3-10_amd64.deb

#configuring wpa_supplicant for wired 802.1x
cat > /etc/wpa_supplicant/wired.conf << EOF
ctrl_interface=/var/run/wpa_supplicant
eapol_version=1
ap_scan=0
network={
eapol_flags=0
key_mgmt=IEEE8021X
eap=TLS
identity=
ca_cert=
client_cert=
private_key=
private_key_passwd=
}
EOF

#moving certs to userless work-direcrory
mkdir /etc/wpa_supplicant/certs
chmod 777 /etc/wpa_supplicant/certs
cp CERTS/* /etc/wpa_supplicant/certs/


#adding pre-up condition for nic 802.1x
iface=$(find /sys/class/net -mindepth 1 -maxdepth 1 | xargs -r readlink -f | grep pci | xargs -r -n 1 basename)

cat > /etc/network/interfaces << EOF
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

auto $iface
iface $iface inet dhcp
allow-hotplug $iface
	pre-up wpa_supplicant -c /etc/wpa_supplicant/wired.conf -i $iface -D wired -B > /var/log/ifup_wpa1.log 2> /var/log/ifup_wpa2.log
iface $iface inet6 auto
EOF

#moving bridge_init to userless directory
cp bridge_init.sh /usr/local/sbin
chmod 775 /usr/local/sbin/bridge_init.sh

#adding crontab for rebuilding bridge once per minute
cat > /etc/cron.d/bridge_init << EOF
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
* * * * * root /usr/local/sbin/bridge_init.sh
EOF
crontab /etc/cron.d/bridge_init
invoke-rc.d cron reload

#moving tcpdump script to user folder, and mkdir for logs
cp start_tcpdump.sh /home/sniff/ 
mkdir /home/sniff/dump_logs
