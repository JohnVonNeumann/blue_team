#!/bin/bash
# For options and detailed man pages:
# https://linux.die.net/man/8/iptables
IPTABLES=/sbin/iptables
MODPROBE=/sbin/modprobe
INT_NETS=(10.0.0.0/8 172.16.0.0/16 192.168.0.0/24)
IFACES=(wlo+ enp+) 

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
for INT_NET in $(INT_NETS); do
    for IFACE in $(IFACES); do
        $IPTABLES -A INPUT -i $IFACE -s ! $INT_NET -j LOG --log-prefix "DROP SPOOFED PACKET " --log-ip-options --log-tcp-options
        $IPTABLES -A INPUT -i $IFACE -s ! $INT_NET -j DROP
    done
done

echo "[+] Setting up ACCEPT INPUT rules..."
for INT_NET in $(INT_NETS); do
    # ACCEPT NEW INPUT when it's SSH, this will be edited into
    # something a bit safer with port-knocking later on
    $IPTABLES -A INPUT -i wlo+ -p tcp -s $INT_NET --dport 22 --syn -m state --state NEW -j ACCEPT
    # Only accept pings from within the network I'm existing on
    $IPTABLES -A INPUT -p icmp -s $INT_NET --icmp-type echo-request -j ACCEPT
done

echo "[+] Setting up default logging on INPUT.."
# Trying out comma separating interfaces to reduce code, docs don't say if you can do it so I imagine it won't actually work
$IPTABLES -A INPUT -i ! wlo+,enp+ -j LOG --log-prefix "DROP " --log-ip-options --log-tcp-options

### OUTPUT Rules Chain
echo "[+] Setting up OUTPUT rule chain..."
echo "[+] Setting up OUTPUT state tracking rules..."
$IPTABLES -A OUTPUT -m state --state INVALID -j LOG --log-prefix "DROP INVALID " --log-ip-options --log-tcp-options
$IPTABLES -A OUTPUT -m state --state INVALID -j DROP
$IPTABLES -A OUTPUT -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

# Some of these rules will be changing/should change
# as the overall picture of the host is confirmed
# ie: which prots do I/the service not use 
echo "[+] Setting up ACCEPT rules for conns. outbound..."
echo "[+] Setting up FTP outbound ACCEPT..."
$IPTABLES -A OUTPUT -p tcp --dport 21 --syn -m state --state NEW -j ACCEPT
echo "[+] Setting up SSH outbound ACCEPT..."
$IPTABLES -A OUTPUT -p tcp --dport 22 --syn -m state --state NEW -j ACCEPT
echo "[+] Setting up SMTP outbound ACCEPT..."
$IPTABLES -A OUTPUT -p tcp --dport 25 --syn -m state --state NEW -j ACCEPT
echo "[+] Setting up WHOIS outbound ACCEPT..."
$IPTABLES -A OUTPUT -p tcp --dport 43 --syn -m state --state NEW -j ACCEPT
echo "[+] Setting up HTTP outbound ACCEPT..."
$IPTABLES -A OUTPUT -p tcp --dport 80 --syn -m state --state NEW -j ACCEPT
echo "[+] Setting up HTTPS outbound ACCEPT..."
$IPTABLES -A OUTPUT -p tcp --dport 443 --syn -m state --state NEW -j ACCEPT
echo "[+] Setting up RWHOIS outbound ACCEPT..."
$IPTABLES -A OUTPUT -p tcp --dport 4321 --syn -m state --state NEW -j ACCEPT
echo "[+] Setting up DNS outbound ACCEPT..."
$IPTABLES -A OUTPUT -p tcp --dport 53 --syn -m state --state 
echo "[+] Setting up ICMP outbound ACCEPT..."
$IPTABLES -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT

echo "[+] Setting up OUTPUT LOG rules..."
for IFACE in $(IFACES); do
    $IPTABLES -A OUTPUT -o ! $IFACE -j LOG --log-prefix "DROP " --log-ip-options --log-tcp-options
done
