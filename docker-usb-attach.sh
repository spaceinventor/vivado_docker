#!/bin/bash

XILINX_USB_VENDEV=(0403:6014 03fd:000f)

# args: docker_name BUSPATH BUSDEV
function attach_usb_node {

    USB_PATH=/dev/bus/usb/$2
    USB_FILE=$USB_PATH/$3

    MAJ=`ls -l $USB_FILE | cut -f 5 -d ' ' | cut -f 1 -d ','`
    MIN=`ls -l $USB_FILE | cut -f 6 -d ' '`

    DOCKER_ID=`docker ps -f name=$1 --format "{{.ID}}" --no-trunc`

    if [ ${DOCKER_ID}x = x ]; then
	echo "Cannot find this docker container.."
	exit 3
    fi

    docker exec -u 0 -it $DOCKER_ID mkdir -p $USB_PATH
    docker exec -u 0 -it $DOCKER_ID mknod $USB_FILE c $MAJ $MIN
    docker exec -u 0 -it $DOCKER_ID chmod 777 $USB_FILE

    echo "c $MAJ:$MIN rwm" > /sys/fs/cgroup/devices/docker/$DOCKER_ID/devices.allow
}

if [[ $EUID -ne 0 ]]; then
   echo "Please run me as root.."
   exit 1
fi

if [ $# != 1 ]; then
    echo "usage: $0 <docker_name>"
    exit 2
fi

for i in "${XILINX_USB_VENDEV[@]}"; do
    lsusb | grep $i > /dev/null || continue
    BUSDEV=$(lsusb | awk "/.*: ID $i .*/{print \$2 \":\" substr(\$4,0,3)}")
    BUS=${BUSDEV:0:3}
    DEV=${BUSDEV:4:3}

    echo "Attacching Xilinx device ($BUS $DEV) to $1"
    attach_usb_node $1 $BUS $DEV
done
