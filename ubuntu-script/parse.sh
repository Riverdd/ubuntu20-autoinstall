#!/bin/bash

while read line; do
        pxeaddr=$(echo "$line" | awk '{print $1}')
        sn=$(echo "$line" | awk '{print $2}')
        #echo "$pxeaddr, $sn"

        find_line=$(cat excel.txt | grep $sn)
        find_sn=$(echo "$find_line" | awk '{print $1}')
        find_hostname=$(echo "$find_line" | awk '{print $2}')
        find_bzaddr=$(echo "$find_line" | awk '{print $3}')

        echo "$find_bzaddr  $pxeaddr  HOSTNAME=$find_hostname SN=$find_sn BZ_IP=$find_bzaddr" >> output
done < serial

