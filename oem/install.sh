#!/bin/sh

DEVICE=/dev/sda1
MOUNT_POINT=/mnt

CONFIG_DIR=${MOUNT_POINT}/lib/rancher/conf
SCRIPT_DIR=${MOUNT_POINT}/lib/rancher/state/opt/rancher/bin

mkdir -p ${MOUNT_POINT}
mount ${DEVICE} ${MOUNT_POINT}

mkdir -p ${CONFIG_DIR}
cp /opt/rancher.yml ${CONFIG_DIR}

mkdir -p ${SCRIPT_DIR}
cp /opt/start.sh ${SCRIPT_DIR}
chmod +x ${SCRIPT_DIR}/start.sh
