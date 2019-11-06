#!/bin/bash

set -e

VERSION="juno"
TARGET="arm64+raspi4"
YYYYMMDD="$(date +%Y%m%d)"
OUTPUT_SUFFIX=".img"
TARGET_IMG="elementaryos-${VERSION}-${TARGET}.${YYYYMMDD}${OUTPUT_SUFFIX}"

BASE_IMG_URL="https://github.com/TheRemote/Ubuntu-Server-raspi4-unofficial/releases/download/v19/ubuntu-18.04.3-preinstalled-server-arm64+raspi4.img.xz"
BASE_IMG="ubuntu-18.04.3-preinstalled-server-arm64+raspi4.img"
MountXZ=""

function MountIMG {
  MountXZ=$(kpartx -avs "$TARGET_IMG")
  sync
  MountXZ=$(echo "$MountXZ" | awk 'NR==1{ print $3 }')
  MountXZ="${MountXZ%p1}"
  echo "Mounted $TARGET_IMG on loop $MountXZ"
}

function MountIMGPartitions {
  # % Mount the image on /mnt (rootfs)
  mount /dev/mapper/"${MountXZ}"p2 /mnt

  # % Remove overlapping firmware folder from rootfs
  rm -rf /mnt/boot/firmware
  mkdir /mnt/boot/firmware

  # % Mount /mnt/boot/firmware folder from bootfs
  mount /dev/mapper/"${MountXZ}"p1 /mnt/boot/firmware
  sync
  sleep 0.1
}

function UnmountIMGPartitions {
  sync
  sleep 0.1

  echo "Unmounting /mnt/boot/firmware"
  while mountpoint -q /mnt/boot/firmware && ! umount /mnt/boot/firmware; do
    sync
    sleep 0.1
  done

  echo "Unmounting /mnt"
  while mountpoint -q /mnt && ! umount /mnt; do
    sync
    sleep 0.1
  done

  sync
  sleep 0.1
}

function UnmountIMG {
  sync
  sleep 0.1

  UnmountIMGPartitions

  echo "Unmounting $TARGET_IMG"
  kpartx -dvs "$TARGET_IMG"

  sleep 0.1

  dmsetup remove ${MountXZ}p1
  dmsetup remove ${MountXZ}p2

  sleep 0.1

  losetup --detach-all /dev/${MountXZ}

  while [ -n "$(losetup --list | grep /dev/${MountXZ})" ]; do
    sync
    sleep 0.1
  done
}

apt-get update
apt-get install -y \
  wget \
  xz-utils \
  kpartx \
  qemu-user-static \
  parted \
  zerofree \
  dosfstools

if [ ! -f ${BASE_IMG} ]; then
    wget ${BASE_IMG_URL} -O ${BASE_IMG}.xz
    unxz ${BASE_IMG}.xz
fi

cp -vf ${BASE_IMG} ${TARGET_IMG}

sync
sleep 5

# Expand the image
truncate -s 7G "$TARGET_IMG"
sync

sleep 5

MountIMG

# Get the starting offset of the root partition
PART_START=$(parted /dev/"${MountXZ}" -ms unit s p | grep ":ext4" | cut -f 2 -d: | sed 's/[^0-9]//g')

# Perform fdisk to correct the partition table
set +e
fdisk /dev/"${MountXZ}" << EOF
p
d
2
n
p
2
$PART_START

p
w
EOF
set -e

# Close and unmount image then reopen it to get the new mapping
UnmountIMG
MountIMG

# Run fsck
e2fsck -fva /dev/mapper/"${MountXZ}"p2
sync
sleep 1

UnmountIMG
MountIMG

# Run resize2fs
resize2fs /dev/mapper/"${MountXZ}"p2
sync
sleep 1

UnmountIMG
MountIMG

# Zero out free space on drive to reduce compressed img size
zerofree -v /dev/mapper/"${MountXZ}"p2
sync
sleep 1

# Map the partitions of the IMG file so we can access the filesystem
MountIMGPartitions

# Configuration for elementary OS
wget https://raw.githubusercontent.com/elementary/os/master/etc/config/includes.chroot/etc/netplan/01-network-manager-all.yml \
  -O /mnt/etc/netplan/01-network-manager-all.yml

mkdir -p /mnt/etc/NetworkManager/conf.d

wget https://raw.githubusercontent.com/elementary/os/master/etc/config/includes.chroot/usr/lib/NetworkManager/conf.d/10-globally-managed-devices.conf \
  -O /mnt/etc/NetworkManager/conf.d/10-globally-managed-devices.conf

mkdir -p /mnt/etc/oem

wget https://www.raspberrypi.org/app/uploads/2018/03/RPi-Logo-Reg-SCREEN.png \
  -O /mnt/etc/oem/logo.png

cat > /mnt/etc/oem.conf << EOF
[OEM]
Manufacturer=Raspberry Pi Foundation
Product=Raspberry Pi
Logo=/etc/oem/logo.png
URL=https://www.raspberrypi.org/
EOF

# setup chroot
cp -f /usr/bin/qemu-aarch64-static /mnt/usr/bin

mount --bind /etc/resolv.conf /mnt/etc/resolv.conf

# chroot
set +e
chroot /mnt /bin/bash << EOF
# Add elementary OS stable repository
add-apt-repository ppa:elementary-os/stable -ny

# Add elementary OS patches repository
add-apt-repository ppa:elementary-os/os-patches -ny

# Upgrade packages
apt-get update
apt-get upgrade -y

# Install elementary OS packages
apt-get install -y \
  elementary-desktop \
  elementary-minimal \
  elementary-standard

# Install elementary OS initial setup
apt-get install -y \
  io.elementary.initial-setup

# Install elementary OS onboarding
apt-get install -y \
  io.elementary.onboarding

# Remove unnecessary packages
apt-get purge -y \
  unity-greeter \
  ubuntu-server \
  plymouth-theme-ubuntu-text \
  cloud-init \
  cloud-initramfs* \
  lxd \
  lxd-client \
  acpid \
  gnome-software \
  vim*

# Clean up after ourselves and clean out package cache to keep the image small
apt-get autoremove -y
apt-get clean
apt-get autoclean
EOF
set -e

umount /mnt/etc/resolv.conf

# Remove files needed for chroot
rm -rf /mnt/usr/bin/qemu-aarch64-static

# Remove any crash files generated during chroot
rm -rf /mnt/var/crash/*
rm -rf /mnt/var/run/*

# Configuration for elementary OS
sed -i 's/juno/bionic/g' /mnt/etc/apt/sources.list

sed -i 's/ubuntu/elementary/g' /mnt/etc/hostname
sed -i 's/ubuntu/elementary/g' /mnt/etc/hosts

sed -i 's/$/ logo.nologo loglevel=0 quiet splash vt.global_cursor_default=0 plymouth.ignore-serial-consoles/g' /mnt/boot/firmware/cmdline.txt

echo "" >> /mnt/boot/firmware/config.txt
echo "boot_delay=1" >> /mnt/boot/firmware/config.txt

# Unmount
UnmountIMGPartitions

# Run fsck on image
fsck.ext4 -pfv /dev/mapper/"${MountXZ}"p2
fsck.fat -av /dev/mapper/"${MountXZ}"p1

zerofree -v /dev/mapper/"${MountXZ}"p2

# Save image
UnmountIMG

# Create artifacts
mv ${TARGET_IMG} artifacts/
cd artifacts
rm -f ${TARGET_IMG}.xz
xz -0 ${TARGET_IMG}
md5sum ${TARGET_IMG}.xz > ${TARGET_IMG}.xz.md5
sha256sum ${TARGET_IMG}.xz > ${TARGET_IMG}.xz.sha256
