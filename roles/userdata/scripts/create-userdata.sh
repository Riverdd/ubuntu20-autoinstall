for PART_ID in $(./megaclisas-status | grep SSD | awk '{print $1}')
do
    DISK_ID=$(echo $PART_ID | cut -c 1-4)
    DISK_PATH=$(./megaclisas-status | grep $DISK_ID | grep RAID | awk -F '|' '{print $8}')
    if [ -n $DISK_PATH ]
    then
        SYS_DISK=$DISK_PATH
    fi
done

SN=$(dmidecode -s system-serial-number | grep -v ^#)
PXE_MAC=$(ip a | grep -B1 192.168 | grep ether | awk -F ' ' '{print $2}')
cat > ./user-data-$SN << EOF
  version: 1
  user-data:
    timezone: Asia/Shanghai
    disable_root: false
  identity:
    hostname: ubuntu-server
    password: "\$6\$exDY1mhS4KUYCE/2\$zmn9ToZwTKLhCw.b4/b.ZRTIZM30JZ4QrOQ2aOXJ8yk96xpcCof0kxKwuX1kqLG/ygbJ1f8wxED22bTL4F46P0"
    username: ubuntu
  ssh:
    allow-pw: true
    install-server: true
  storage:
    config:
    - grub_device: true
      id: disk1
      path:$SYS_DISK
      ptable: gpt
      type: disk
      wipe: superblock-recursive
    - device: disk1
      flag: bios_grub
      id: partition-0
      number: 1
      size: 1048576
      type: partition
    - device: disk1
      id: partition-1
      number: 2
      size: -1
      type: partition
      wipe: superblock
    - fstype: ext4
      id: format-0
      type: format
      volume: partition-1
    - device: format-0
      id: mount-0
      path: /
      type: mount
EOF
