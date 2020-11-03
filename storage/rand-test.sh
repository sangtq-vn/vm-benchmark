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

fio_test() {
	if [ -e '/usr/bin/fio' ]; then
		echo "Fio Test"
		local tmp=$(mktemp)
		fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fio_test --filename=fio_test --bs=4k --numjobs=1 --iodepth=64 --size=256M --readwrite=randrw --rwmixread=75 --runtime=30 --time_based --output="$tmp"
		
		if [ $(fio -v | cut -d '.' -f 1) == "fio-2" ]; then
			local iops_read=`grep "iops=" "$tmp" | grep read | awk -F[=,]+ '{print $6}'`
			local iops_write=`grep "iops=" "$tmp" | grep write | awk -F[=,]+ '{print $6}'`
			local bw_read=`grep "bw=" "$tmp" | grep read | awk -F[=,B]+ '{if(match($4, /[0-9]+K$/)) {printf("%.1f", int($4)/1024);} else if(match($4, /[0-9]+M$/)) {printf("%.1f", substr($4, 0, length($4)-1))} else {printf("%.1f", int($4)/1024/1024);}}'`"MB/s"
			local bw_write=`grep "bw=" "$tmp" | grep write | awk -F[=,B]+ '{if(match($4, /[0-9]+K$/)) {printf("%.1f", int($4)/1024);} else if(match($4, /[0-9]+M$/)) {printf("%.1f", substr($4, 0, length($4)-1))} else {printf("%.1f", int($4)/1024/1024);}}'`"MB/s"
			
		elif [ $(fio -v | cut -d '.' -f 1) == "fio-3" ]; then
			local iops_read=`grep "IOPS=" "$tmp" | grep read | awk -F[=,]+ '{print $2}'`
			local iops_write=`grep "IOPS=" "$tmp" | grep write | awk -F[=,]+ '{print $2}'`
			local bw_read=`grep "bw=" "$tmp" | grep READ | awk -F"[()]" '{print $2}'`
			local bw_write=`grep "bw=" "$tmp" | grep WRITE | awk -F"[()]" '{print $2}'`
		fi
		echo "Read performance     : $bw_read"
		echo "Read IOPS            : $iops_read"
		echo "Write performance    : $bw_write"
		echo "Write IOPS           : $iops_write"
		
		rm -f $tmp fio_test
	else
		echo "Fio is missing!!! Please install Fio before running test."
	fi
}

echo "-----------------------------------"
fio_test
