#!/bin/bash
#
# ref'ju:geeks welcome - MultiWAN fake host setup
#  (for some arbitrary Linux box with two NICs)

if [[ $EUID != 0 ]]
then
    echo "Please run as root" >&2
    exit 128
fi

# Common resources
PATH_SCRIPT="$(realpath "$0")"
RESOURCES="${PATH_SCRIPT%/*}/../resources"

if [[ $# -lt 2 ]]
then
    echo "Two arguments expected: <IN_INTERFACE> <OUT_INTERFACE>" >&2
    exit 127
fi

iface="$1"
oface="$2"

# NIC configuration
ip address flush dev "$iface"
ip address add 192.168.10.1/24 dev "$iface"
ip address add 192.168.10.5/24 dev "$iface"

# Kernel configuration
sysctl -q net.ipv4.ip_forward=1
sysctl -q net.ipv4.conf.all.forwarding=1
sysctl -q net.ipv6.conf.all.forwarding=1

# Iptables configuration
iptables -t nat -F
iptables -t filter -F

# shellcheck disable=SC2002
cat "$RESOURCES/iptables/iptables-local-nat" |\
    sed s/'IN_INTERFACE'/"$iface"/g |\
    sed s/'OUT_INTERFACE'/"$oface"/g |\
    iptables-restore
