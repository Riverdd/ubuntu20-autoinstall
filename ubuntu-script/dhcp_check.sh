#!/bin/bash

if test $# -ne 1; then
        echo "Usage: $0 < skip hosts file >"
        exit 1
fi

skip_hosts_file="$1"

while true; do
        find_hosts=$(fping -g 192.168.100.10 192.168.100.250 |& grep alive | awk '{print $1}')
        for find_host in $find_hosts; do
                grep $find_host $skip_hosts_file >& /dev/null
                if test $? -ne 0; then
                        echo "Find new dhcp ipaddr: $find_host"
                fi
        done
        sleep 3
        echo "======================================="
done

