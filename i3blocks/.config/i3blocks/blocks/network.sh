#!/usr/bin/env bash

iface="${BLOCK_INSTANCE}"
iface="${IFACE:-$iface}"
unit="${UNIT:-MB}"

function default_interface {
    ip route | awk '/^default via/ {print $5; exit}'
}

function check_proc_net_dev {
    if [ ! -f "/proc/net/dev" ]; then
        echo "/proc/net/dev not found"
        exit 33
    fi
}

function list_interfaces {
    check_proc_net_dev
    echo "Interfaces in /proc/net/dev:"
    grep -o "^[^:]\\+:" /proc/net/dev | tr -d " :"
}

check_proc_net_dev

iface="${iface:-$(default_interface)}"
while [ -z "$iface" ]; do
    echo No default interface
    sleep 1
    iface=$(default_interface)
done

case "$unit" in
    Kb|Kbit|Kbits)   bytes_per_unit=$((1024 / 8));;
    KB|KByte|KBytes) bytes_per_unit=$((1024));;
    Mb|Mbit|Mbits)   bytes_per_unit=$((1024 * 1024 / 8));;
    MB|MByte|MBytes) bytes_per_unit=$((1024 * 1024));;
    Gb|Gbit|Gbits)   bytes_per_unit=$((1024 * 1024 * 1024 / 8));;
    GB|GByte|GBytes) bytes_per_unit=$((1024 * 1024 * 1024));;
    Tb|Tbit|Tbits)   bytes_per_unit=$((1024 * 1024 * 1024 * 1024 / 8));;
    TB|TByte|TBytes) bytes_per_unit=$((1024 * 1024 * 1024 * 1024));;
    *) echo Bad unit "$unit" && exit 1;;
esac

scalar=$bytes_per_unit
init_line=$(cat /proc/net/dev | grep "^[ ]*$iface:")
if [ -z "$init_line" ]; then
    echo Interface not found in /proc/net/dev: "$iface"
    exit 1
fi

init_received=$(($(awk '{print $2}' <<< $init_line)/$scalar))
init_sent=$(($(awk '{print $10}' <<< $init_line)/$scalar))
ip=$(ip a show $iface | rg inet | awk 'NR==1 {print $2}' | cut -d/ -f1)

printf "<span bgcolor='#ef6c00'> %s </span><span bgcolor='#ffcc80' color='#000000'> rx %1.0f %s/s tx %1.0f %s/s </span><span bgcolor='#aed581' color='#000000'> %s </span>" $iface $init_received $unit $init_sent $unit $ip