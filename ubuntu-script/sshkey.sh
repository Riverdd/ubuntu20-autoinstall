#!/bin/bash

trap 'onCtrlC' INT

function onCtrlC ()
{
    echo ""
    echo "-----------------------"
    echo "-----   Bye bye   -----"
    echo "-----------------------"
    exit 0
}


username="root"
password="Y0v0le.com"
inv_file=""
tmp_hosts="/tmp/hosts"

print_usage()
{
    echo ""
    echo "Usage: $0 < OPTIONS > "
    echo ""
    echo "Intro: copy ssh key to all specified hosts"
    echo ""
    echo "OPTIONS:"
    echo "  -i < inventory file >   hosts inventory filename"
    echo "  -u < login user >       ssh login username ( default: root )"
    echo "  -p < login password >   ssh login password ( default: Y0v0le.com )"
    echo "  -r < ip address range > automatic parsing ip range, dont's use it with -i"
    echo "                          example: 10.3.10.100,10.3.12.200( subnet range: 16-32 )"
    echo "  -h                      print help (this message) and exit"
    echo ""
    exit 0
}

ip_range_parse()
{
    IPA1=$(echo $1 | awk -F '.' '{print $1}')
    IPA2=$(echo $1 | awk -F '.' '{print $2}')
    IPA3=$(echo $1 | awk -F '.' '{print $3}')
    IPA4=$(echo $1 | awk -F '.' '{print $4}')

    IPB1=$(echo $2 | awk -F '.' '{print $1}')
    IPB2=$(echo $2 | awk -F '.' '{print $2}')
    IPB3=$(echo $2 | awk -F '.' '{print $3}')
    IPB4=$(echo $2 | awk -F '.' '{print $4}')

    echo "" > $tmp_hosts

    if [[ $IPA1 != $IPB1 ]] || [[ $IPA2 != $IPB2 ]]; then
        print_usage
    elif [[ $IPA3 != $IPB3 ]]; then
        for i in $(eval echo {$IPA3..$IPB3})
        do
            if [[ $i == $IPA3 ]]; then
                eval echo "$IPA1.$IPA2.$i.{$IPA4..255}" | xargs -n 1 >> $tmp_hosts
            elif [[ $i == $IPB3 ]]; then
                eval echo "$IPA1.$IPA2.$i.{1..$IPB4}" | xargs -n 1 >> $tmp_hosts
            else
                eval echo "$IPA1.$IPA2.$i.{1..255}" | xargs -n 1 >> $tmp_hosts
            fi
        done
    else
        eval echo "$IPA1.$IPA2.$IPA3.{$IPA4..$IPB4}" | xargs -n 1 >> $tmp_hosts
    fi
}

while getopts "i:u:p:r:h" arg
do
    case $arg in
        i)
            inv_file=$OPTARG
            if ! test -e $inv_file; then
                echo "Cant't find the file: $inv_file"
                exit 1
            fi
            ;;
        u)
            username=$OPTARG
            ;;
        p)
            password=$OPTARG
            ;;
        r)
            start_ip=$(echo $OPTARG | awk -F ',' '{print $1}')
            end_ip=$(echo $OPTARG | awk -F ',' '{print $2}')
            ip_range_parse $start_ip $end_ip
            inv_file=$tmp_hosts
            ;;
        h)
            print_usage
            ;;
    esac
done

if test -z $inv_file; then
    print_usage
fi

which expect >& /dev/null
if test $? -ne 0; then
    yum install -y expect
    if test $? -ne 0; then
        echo "[ERROR]: install cmd expect fail, check your yum configure"
        exit 1
    fi
fi

echo "Checking ssh key file is generated ......"
sshkey_file=~/.ssh/id_rsa.pub
if ! test -e $sshkey_file; then
    expect << EOF
    log_user 0
    set timeout 10
    spawn ssh-keygen -t rsa
    expect {
        -nocase "enter"  {send "\r"; exp_continue}
        eof
    }
EOF
fi

which ansible >& /dev/null
if test $? -eq 0; then
    hosts_list=$(ansible -i $inv_file nodes --list-hosts | awk 'NR>1')
else
    hosts_list=$(cat $inv_file | grep -v ^# | grep -v ^$ | grep -v '\[')
fi

echo "==================================================================="
echo "hosts list: "
echo "$hosts_list"
echo "==================================================================="

# auto sshkey pair
for host in $hosts_list; do
    expect << EOF
    log_user 0
    set timeout 10
    spawn ssh-copy-id -o ConnectTimeout=3 -o StrictHostKeyChecking=no $username@$host
    expect {
        "(yes/no)"                       {send "yes\r"; exp_continue}
        -nocase "password:"              {send "$password\r"; exp_continue}
        -nocase "authentication fail"    {exit 33}
        -nocase "permission denied"      {exit 33}
        -nocase "timed out"              {exit 44}
        -nocase "service not known"      {exit 55}
        eof
    }
    lassign [wait] pid spawnid os_error_flag value
    exit $value
EOF
    expect_retval=$?
    #echo "expect_retval: $expect_retval"

    if test $expect_retval -eq 0; then
        echo "[$host] Copy ssh key OK !!!"
    elif test $expect_retval -eq 33; then
        echo "[$host] Copy ERR: Authentication fail, check your password !!!"
        exit $expect_retval
    elif test $expect_retval -eq 44; then
        echo "[$host] Copy ERR: Connection timed out, check your network !!!"
        exit $expect_retval
    elif test $expect_retval -eq 55; then
        echo "[$host] Copy ERR: Name or service not known!!!"
        exit $expect_retval
    else
        echo "[$host] Copy ERR: Unknown error !!!"
        exit $expect_retval
    fi

    echo ""
done

