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


io_test() {
    (LANG=C dd if=/dev/zero of=test_$$ bs=64k count=16k conv=fdatasync && rm -f test_$$ ) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//'
}

dd_test() {
	echo "dd Test"
	io1=$( io_test )
	echo "I/O (1st run)        : $io1"
	io2=$( io_test )
	echo "I/O (2nd run)        : $io2"
	io3=$( io_test )
	echo "I/O (3rd run)        : $io3"
	ioraw1=$( echo $io1 | awk 'NR==1 {print $1}' )
	[ "`echo $io1 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw1=$( awk 'BEGIN{print '$ioraw1' * 1024}' )
	ioraw2=$( echo $io2 | awk 'NR==1 {print $1}' )
	[ "`echo $io2 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw2=$( awk 'BEGIN{print '$ioraw2' * 1024}' )
	ioraw3=$( echo $io3 | awk 'NR==1 {print $1}' )
	[ "`echo $io3 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw3=$( awk 'BEGIN{print '$ioraw3' * 1024}' )
	ioall=$( awk 'BEGIN{print '$ioraw1' + '$ioraw2' + '$ioraw3'}' )
	ioavg=$( awk 'BEGIN{printf "%.1f", '$ioall' / 3}' )
	echo "Average              : $ioavg MB/s"
}

echo "Disk Speed"
echo "-----------------------------------"
dd_test

