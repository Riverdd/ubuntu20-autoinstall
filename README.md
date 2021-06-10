# Ubuntu20.04 live pxe autoinstall


## deploy-config

### 部署节点操作系统
Ubuntu18-generic 
理论上支持所有ubuntu操作系统，不同版本配置文件路径可能需要修改，20系列 
网卡配置文件格式需要修改。 

### 部署节点准备工作
1.要求配置好可用apt源 
2.确认PXE用于dhcp的端口 
3.确认镜像与ramdisk下载链接 
4.安装好ansible 

### 部署节点配置
#### 确认并修改group_vars/all.yml中配置（默认无需修改，如有特殊需求按需修改）

APACHE2_DIR: web发布路径;
DHCP_INTERFACE: PXE用于dhcp的端口;
ISO_URL: ubuntu20 live iso下载链接;
RAMDISK_URL: centos7 ramdisk 下载链接;
TFTP_DIR: tftp发布路径

#### 执行命令进行autoinstall配置
ansible-playbook -i inventory/node setup.yml -t deploy-config

#### 确认autoinstall配置完成
1.dhcp端口开启，默认配置ip为192.168.100.20 
2.www正常发布ubuntu20 iso (curl 192.168.100.20) 
3.tftp发布路径及文件存在 


## userdata

### 被部署节点引导安装ramdisk
(脚本使用参考centos) 
1.通过使用autoinstall/ubuntu-script中ipmi脚本来使节点进入PXE完成安装ramdisk 
2.所有节点成功进入ramdisk后通过ssh-key脚本免密认证(user:root, password:helloworld) 
3.使用dhcp脚本获取成功安装节点的ip，写入autoinstall/inventory/node中ram-nodes组 

### 生成各节点user-data
ansible-playbook -i inventory/node setup.yml -t user-data

(user-data步骤主要采集每台节点的系统盘路径以及sn，使用的脚本放在 
autoinstall/roles/userdata/scripts/create-userdata.sh 系统盘路径采集为做了RAID的ssd磁盘， 
被部署的操作系统为非lvm模式安装，生成个节点sn对应的user-data保存在web发布路径下的user-datas。) 

### 检查所有节点user-data是否采集到正确的系统盘路径
到对应的web发布路径user-datas 
grep -rn "path:" 


## Ubuntu20安装

### 修改引导文件
到对应tftp发布路径 
(该路径下pxelinux.cfg中存放3个引导文件，切换引导只需要将对应文件覆盖default文件即可)

cp pxelinux.cfg/default.ubuntu20 pxelinux.cfg/default

### 引导安装Ubuntu20
1.通过使用autoinstall/ubuntu-script中ipmi脚本来使节点进入PXE完成安装Ubuntu20

(安装过程中各节点会通过sn匹配拉取各个节点的user-data-sn文件进行自动化安装)


## hostconfig
这一部分为主机名、网卡配置，以及megacli等其他软件包安装。如有需要可以自行修改role中task内容。

使用前使用autoinstall/ubuntu-script中的excel.txt get_sn.sh serial parse.sh生成节点信息填入inventory/node的nodes组

ansible-playbook -i inventory/node setup.yml -t host-config
