ansible -i ../inventory/node -m shell -a "dmidecode -s system-serial-number | grep -v ^#" nodes
