#!/bin/bash

#CRON
D=/dev/null
L=/sys/class/net
br=bridge1
brp=$L/$br/bridge

if [ ! -e $L/$br ]; then
	ip link add name $br type bridge
	ip link set $br promisc on
	#ip link set $br multicast on
	#ip link set $br allmulticast on
	echo 0 > /sys/class/net/$br/bridge/stp_state
	echo 20 > /sys/class/net/$br/bridge/forward_delay
	echo 8 > /sys/class/net/$br/bridge/group_fwd_mask
	ip link set $br up
fi

find $L/ -mindepth 1 -maxdepth 1 | xargs -r readlink -f | grep usb | xargs -r -n 1 basename | xargs -r -n 1 -P 0 -I % ip link set % master $br up
