#!/bin/bash


# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PLAIN='\033[0m'

# Date
DATE=`date '+%Y-%m-%d %H:%M:%S'`

# check root
[[ $EUID -ne 0 ]] && echo -e "${RED}Error:${PLAIN} This script must be run as root!" && exit 1

# install wget, fio and virt-what ioping nc fio 
if [ ! -e '/usr/bin/fio' ]; then 
yum install -y fio || apt-get install -y fio 
fi 

if [ ! -e '/usr/bin/nc' ]; then 
yum install -y nc || apt-get install -y nc
fi 

if [ ! -e '/usr/bin/ioping' ]; then 
yum install -y ioping || apt-get install -y ioping
fi 

if [ ! -e '/usr/sbin/virt-what' ]; then 
yum install -y virt-what || apt-get install -y virt-what
fi 

if [ ! -e '/usr/bin/wget' ]; then 
yum install -y wget || apt-get install -y wget 
fi 

virtua=$(virt-what)

if [[ ${virtua} ]]; then
	virt="$virtua"
else
	virt="No Virt"
fi

get_opsy() {
	[ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
	[ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
	[ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

next() {
	printf "%-70s\n" "-" | sed 's/\s/-/g'
}

echo "Ioping test"
ioping -c 10 . > ioping.txt && result=$(cat ioping.txt | grep min | cut -d "=" -f2) && echo "Min/Avg/Max/Mdev     : $result" && rm -rf ioping.txt

