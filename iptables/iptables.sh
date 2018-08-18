#!/bin/bash
# For options and detailed man pages:
# https://linux.die.net/man/8/iptables
IPTABLES=/sbin/iptables
MODPROBE=/sbin/modprobe
INT_NET=192.168.0.0/24

### flush existing rules and set default chain pol to DROP
echo "[+] Flushing existing iptables rules..."
$IPTABLES -F
$IPTABLES -F -t nat
$IPTABLES -X # delete chains
echo "[+] DROPPING traffic on all chains..."
$IPTABLES -P INPUT DROP
$IPTABLES -P OUTPUT DROP
$IPTABLES -P FORWARD DROP
echo "[+] Loading connection-tracking modules..."
$MODPROBE ip_conntrack
$MODPROBE iptable_nat
$MODPROBE ip_conntrack_ftp
$MODPROBE ip_nat_ftp

### INPUT rule chains 
echo "[+] Setting up INPUT chain..."
echo "[+] Setting up STATE tracking INPUT rules..."
$IPTABLES -A INPUT -m state --state INVALID -j LOG --log-prefix "DROP INVALID " --log-ip-options --log-tcp-options
$IPTABLES -A INPUT -m state --state INVALID -j DROP
$IPTABLES -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A INPUT -m state --state NEW -j LOG --log-prefix "DROP ATTEMPTED CONNECTION " --log-ip-options --log-tcp-options
$IPTABLES -A INPUT -m state --state NEW -j DROP

echo "[+] Setting up anti-spoofing rules..."
$IPTABLES -A INPUT -i wlo+ -s ! $INT_NET -j LOG --log-prefix "DROP SPOOFED PACKET " --log-ip-options --log-tcp-options
$IPTABLES -A INPUT -i wlo+ -s ! $INT_NET -j DROP
$IPTABLES -A INPUT -i enp+ -s ! $INT_NET -j LOG --log-prefix "DROP SPOOFED PACKET " --log-ip-options --log-tcp-options
$IPTABLES -A INPUT -i enp+ -s $INT_NET -j DROP

echo "[+] Setting up ACCEPT INPUT rules..."
# ACCEPT NEW INPUT when it's SSH, this will be edited into
# something a bit safer with port-knocking later on
$IPTABLES -A INPUT -i wlo+ -p tcp -s $INT_NET --dport 22 --syn -m state --state NEW -j ACCEPT
# Only accept pings from within the network I'm existing on
$IPTABLES -A INPUT -p icmp -s $INT_NET --icmp-type echo-request -j ACCEPT

echo "[+] Setting up default logging on INPUT.."
# Trying out comma separating interfaces to reduce code, docs don't say if you can do it so I imagine it won't actually work
$IPTABLES -A INPUT -i ! wlo+,enp+ -j LOG --log-prefix "DROP " --log-ip-options --log-tcp-options
