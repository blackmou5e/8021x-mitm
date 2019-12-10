screen -d -m nice -n -19 tcpdump -n -i bridge1 -s 65535 -G 60 -w dump_logs/dump-%y%m%d-%H%M%S
