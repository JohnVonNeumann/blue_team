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
