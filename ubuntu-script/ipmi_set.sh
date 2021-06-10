#!/bin/bash

if test $# -ne 2; then
        echo "Usage: $0 < hosts file > < on/off/status/reset/pxe >"
        exit 1
fi

hosts_file="$1"
power_set="$2"
ipmi_user="root"
ipmi_pass="admin"

while read line; do
        echo "---------------------------------------------------------------------------------"
        echo $line | grep "#"
        if test $? -eq 0; then
                echo "Skip host: $line"
                continue
        fi

        cmd_prefix="ipmitool -U $ipmi_user -P $ipmi_pass -H $line -I lanplus -N 3 -R 1"

        if [[ $power_set == "pxe" ]]; then
                cmd1="$cmd_prefix chassis bootdev pxe"
                echo "Running: $cmd1 ..."
                $cmd1

                cmd2="$cmd_prefix chassis power reset"
                echo "Running: $cmd2 ..."
                $cmd2
                sleep 1
        elif [[ $power_set == "status" ]]; then
                cmd="$cmd_prefix chassis power status"
                echo "Running: $cmd ..."
                $cmd
        else
                cmd="$cmd_prefix chassis power $power_set"
                echo "Running: $cmd ..."
                $cmd
                sleep 1
        fi
done < $hosts_file

