list=$(less /var/lib/dhcp/dhcpd.leases | grep -B 11 ubuntu-server | grep -B 1 "starts 3 2021/06/09" | grep lease | sort | uniq | awk '{print $2}')
for ip in $list
    do
        fping $ip |& grep alive
    done

