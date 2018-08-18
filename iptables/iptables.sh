#!/bin/bash
IPTABLES=/sbin/iptables
MODPROBE=/sbin/modprobe
INT_NET=192.168.0.0/24

### flush existing rules and set default chain pol to DROP
echo "[+] Flushing exisiting iptables rules..."
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
