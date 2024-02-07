#!/bin/bash

usage()
{
cat << EOF
set mtu of bonding device

OPTIONS:
   -h      Show this message
   -d      dry run, 0 OR 1(default)
   -m      mtu, MTU of bonding device
   -b      bonding device (default:bond0)

EOF
}

dry=1

while getopts "hd:m:b:" OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         d)
             dry=$OPTARG
             ;;
         m)
             mtu=$OPTARG
             ;;
         b)
             interface=$OPTARG
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

if [[ $dry == 1 ]]; then
  echo in dry run mode
fi

if [ "x$interface" = "x" ]; then
    interface=bond0
fi
if [[ ! -n $mtu ]]; then
  usage
  exit 1
fi
echo set mtu to $mtu in $interface

# get all slaves
slave0=`ip link|grep "master $interface"|cut -d " " -f 2|cut -d ":" -f 1| head -n 1`
slave1=`ip link|grep "master $interface"|cut -d " " -f 2|cut -d ":" -f 1| tail -n 1`

if [ "x$slave1" = "x" ]; then
    echo "ERROR: get $interface slaves failed."
    exit 1
fi

if [ $slave0 = $slave1 ]; then
    echo "ERROR: single $interface slave."
    exit 1
fi

mtu0=`cat /sys/class/net/$slave0/mtu`
mtu1=`cat /sys/class/net/$slave1/mtu`
mtub=`cat /sys/class/net/$interface/mtu`

# already set
if [ $mtub -eq $mtu ]; then
    exit 0
fi

# check bonding is ok, slave nic must in FAST-LACP mode
timeout 5 tcpdump -e ether proto 0x8809 -i $slave0 -c 2
if [ $? -ne 0 ]; then
    echo "ERROR: $slave0 bond check failed."
    exit 1
fi

timeout 5 tcpdump -e ether proto 0x8809 -i $slave1 -c 2
if [ $? -ne 0 ]; then
    echo "ERROR: $slave1 bond check failed."
    exit 1
fi

# dry mode
if [[ $dry == 1 ]]; then
    exit 0
fi

# now change mtu of the second slave
if [ $mtu1 -ne $mtu ]; then
    ip l set $slave1 down
    ip l set $slave1 mtu $mtu
    ip l set $slave1 up
    sleep 5

    # slave1 must be up
    timeout 5 tcpdump -e ether proto 0x8809 -i $slave1 -c 2
    if [ $? -ne 0 ]; then
        echo "ERROR: $slave1 bond check failed."
        exit 1
    fi

    mtu1=`cat /sys/class/net/$slave1/mtu`
    if [ $mtu1 -ne $mtu ]; then
        echo "ERROR: $slave1 mtu set failed."
        exit 1
    fi    
fi

# change bond mtu
ip l set $interface mtu $mtu
exit 0
