#!/bin/bash

# Script is based on gentoo-install.sh written by Michael Mol: 
# https://github.com/mikemol/gentoo-install/.
# Copyright (c) 2014, Frederik Schaller
# All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

################################################################################
#                                                                              #
#                                   Documentation                              #
#                                                                              #
################################################################################

# Before using the script please read the documentation:
# https://github.com/myschaller/gentoo-install

################################################################################
#                                                                              #
#                              Configuration Variables                         #
#                                                                              #
################################################################################

# Mirror for portage snapshot and stage3 tarball
MIRROR=http://mirror.switch.ch/

# Mirror base path
MIRROR_BASE_PATH=ftp/mirror/gentoo/

# Stage 3 relative path
STAGE_PATH=releases/amd64/current-iso/hardened/

# Portage snapshot relative path
PORTAGE_PATH=snapshots/

# Stage3 tarball
STAGE_BALL=stage3-amd64-hardened-20140403.tar.bz2

# Portage snapshot tarball
PORTAGE_SNAPSHOT=portage-latest.tar.bz2

# Hostname
ETC_CONFD_HOSTNAME="gentoo-image"

# Network device
NET_IFNAME=$(ip route get 8.8.8.8 | awk '{ print $5; exit }') 
NET_HOST_DOMAIN="domain.com"
NET_HOST_IP="192.168.1.10"
NET_HOST_NETMASK="255.255.255.0"
NET_HOST_BRD="192.168.1.255"
NET_DNS_IP="192.168.1.1"
NET_GATEWAY_IP="192.168.1.1"

# Timezone
ETC_TIMEZONE="Europe/Zurich"

# Kernel sources
KERNEL_SOURCES="sys-kernel/hardened-sources"

# Default kernel config. The default provided by this script is optimized for 
# a VMware virtulation environment
KERNEL_CONFIG_PATH="https://raw.github.com/myschaller/gentoo-install/master/kernel-configs/config-linux-3.14.5-r2-hardened-default"

# FSTAB configuration: /etc/fstab
read -r -d '' FSTAB <<'EOF'
/dev/sda2               /boot           ext2            noauto,noatime  1 2
/dev/sda4               /               ext4            noatime         0 1
/dev/vg01/home          /home           ext4            noatime,noexec,nodev,nosuid     0 1
/dev/vg01/usr           /usr            ext4            noatime         0 1
/dev/vg01/opt           /opt            ext4            noatime         0 1
/dev/vg01/var           /var            ext4            noatime,nosuid  0 1
/dev/vg01/tmp           /tmp            ext4            noatime,noexec,nodev,nosuid     0 1
/dev/sda3               none            swap            sw              0 0
/dev/cdroms/cdrom0      /mnt/cdrom      auto            noauto,user,ro  0 0
#/dev/fd0               /mnt/floppy     auto            noauto          0 0

# NOTE: The next line is critical for boot!
proc                    /proc           proc            defaults        0 0

# glibc 2.2 and above expects tmpfs to be mounted at /dev/shm for
# POSIX shared memory (shm_open, shm_unlink).
# (tmpfs is a dynamically expandable/shrinkable ramdisk, and will
#  use almost no memory if not populated with files)
shm                     /dev/shm        tmpfs           nodev,nosuid,noexec     0 0
EOF

# Network configuration: /etc/conf.d/net 
read -r -d '' ETC_CONFD_NET_FILE_CONTENT <<'EOF'
dns_domain_lo="NET_HOST_DOMAIN"
dns_domain_NET_IFNAME="NET_HOST_DOMAIN"

dns_servers_NET_IFNAME="NET_DNS_IP"

config_NET_IFNAME="NET_HOST_IP netmask NET_HOST_NETMASK brd NET_HOST_BRD"
routes_NET_IFNAME="default gw NET_GATEWAY_IP"
EOF

ETC_CONFD_NET_FILE_CONTENT="${ETC_CONFD_NET_FILE_CONTENT//NET_HOST_DOMAIN/$NET_HOST_DOMAIN}"
ETC_CONFD_NET_FILE_CONTENT="${ETC_CONFD_NET_FILE_CONTENT//NET_IFNAME/$NET_IFNAME}"
ETC_CONFD_NET_FILE_CONTENT="${ETC_CONFD_NET_FILE_CONTENT//NET_HOST_IP/$NET_HOST_IP}"
ETC_CONFD_NET_FILE_CONTENT="${ETC_CONFD_NET_FILE_CONTENT//NET_HOST_NETMASK/$NET_HOST_NETMASK}"
ETC_CONFD_NET_FILE_CONTENT="${ETC_CONFD_NET_FILE_CONTENT//NET_DNS_IP/$NET_DNS_IP}"
ETC_CONFD_NET_FILE_CONTENT="${ETC_CONFD_NET_FILE_CONTENT//NET_HOST_BRD/$NET_HOST_BRD}"
ETC_CONFD_NET_FILE_CONTENT="${ETC_CONFD_NET_FILE_CONTENT//NET_GATEWAY_IP/$NET_GATEWAY_IP}"

# Additional /etc/hosts entries
read -r -d '' ETC_HOSTS_CONTENT <<'EOF'
NET_HOST_IP      NET_HOST_NAME.NET_HOST_DOMAIN NET_HOST_NAME
EOF
ETC_HOSTS_CONTENT="${ETC_HOSTS_CONTENT//NET_HOST_DOMAIN/$NET_HOST_DOMAIN}"
ETC_HOSTS_CONTENT="${ETC_HOSTS_CONTENT//NET_HOST_IP/$NET_HOST_IP}"
ETC_HOSTS_CONTENT="${ETC_HOSTS_CONTENT//NET_HOST_NAME/$ETC_CONFD_HOSTNAME}"

# Keyborad settings /etc/conf.d/keymaps
read -r -d '' ETC_CONFD_KEYMAPS_CONTENT <<'EOF'
KEYMAP="de_CH-latin1"
SET_WINDOWKEYS="yes"
EOF

# Compilation settings /etc/portage/make.conf
read -r -d '' MAKE_CONF <<'EOF'
# These settings were set by the catalyst build script that automatically
# built this stage.
# Please consult /usr/share/portage/config/make.conf.example for a more
# detailed example.
CFLAGS="-march=native -O2 -pipe"
CXXFLAGS="${CFLAGS}"
# WARNING: Changing your CHOST is not something that should be done lightly.
# Please consult http://www.gentoo.org/doc/en/change-chost.xml before changing.
CHOST="x86_64-pc-linux-gnu"
# These are the USE flags that were used in addition to what is provided by the
# profile used for building.
MAKEOPTS="-j3"
USE="bindist mmx sse sse2 symlink -X -gtk -gnome -qt -kde"
PORTDIR="/usr/portage"
DISTDIR="${PORTDIR}/distfiles"
PKGDIR="${PORTDIR}/packages"
EOF

################################################################################
#                                                                              #
#                       Partitioning and File Systems (20GB)                   #
#                                                                              #
################################################################################

if [ -b "/dev/sda1" ] || [ -b "/dev/sda2" ] || [ -b "/dev/sda3" ] || [ -b "/dev/sda4" ] || [ -b "/dev/sda5" ] ; then
    echo "We have found partitions on /dev/sda. Aborting!"
    exit 1
fi

parted -a optimal <<HERE 
/dev/sda
mklabel gpt
unit MB
mkpart primary ext4 1 3
name 1 grub
set 1 bios_grub on
mkpart primary ext4 3 203
name 2 boot
set 2 boot on
mkpart primary linux-swap 203 2251
name 3 swap
mkpart primary ext4 2251 6347
name 4 root
mkpart primary  6347 -1
name 5 lvm
set 5 lvm on
q
HERE

mkdir -p /etc/lvm
echo 'devices { filter=["r/cdrom/"] }' > /etc/lvm/lvm.conf
vgscan
vgchange -a y
pvcreate /dev/sda5
vgcreate vg01 /dev/sda5

lvcreate -L1G -nhome vg01
lvcreate -L6G -nusr vg01
lvcreate -L2G -nopt vg01
lvcreate -L4G -nvar vg01
lvcreate -L1G -ntmp vg01

mkfs.ext4 -T small /dev/sda2
mkfs.ext4 -T small /dev/sda4
mkfs.ext4 -T small /dev/vg01/home
mkfs.ext4 -T small /dev/vg01/usr
mkfs.ext4 -T small /dev/vg01/opt
mkfs.ext4 -T small /dev/vg01/var
mkfs.ext4 /dev/vg01/tmp
mkswap /dev/sda3
swapon /dev/sda3

mount /dev/sda4 /mnt/gentoo
mkdir /mnt/gentoo/boot
mkdir /mnt/gentoo/home
mkdir /mnt/gentoo/usr
mkdir /mnt/gentoo/opt
mkdir /mnt/gentoo/var
mkdir /mnt/gentoo/tmp
mount /dev/sda2 /mnt/gentoo/boot
mount /dev/vg01/home /mnt/gentoo/home
mount /dev/vg01/usr /mnt/gentoo/usr
mount /dev/vg01/opt /mnt/gentoo/opt
mount /dev/vg01/var /mnt/gentoo/var
mount /dev/vg01/tmp /mnt/gentoo/tmp

################################################################################
#                                                                              #
#                             Installing Stage 3 Tarball                       #
#                                                                              #
################################################################################

chmod 1777 /mnt/gentoo/tmp
cd /mnt/gentoo

ROOTPATH="$MIRROR$MIRROR_BASE_PATH"

STAGEFILEPATH="$ROOTPATH$STAGE_PATH$STAGE_BALL"
if [[ ! -f $STAGE_BALL ]]; then
    wget "$STAGEFILEPATH"
fi
unset STAGEFILEPATH

PORTAGEFILEPATH="$ROOTPATH$PORTAGE_PATH$PORTAGE_SNAPSHOT"
if [[ ! -f $PORTAGE_SNAPSHOT ]]; then
    wget "$PORTAGEFILEPATH"
fi
unset PORTAGEFILEPATH

unset ROOTPATH

logger "Gentoo Install: Unpacking the stage tarball"

tar xjpf "$STAGE_BALL" -C /mnt/gentoo
rm $STAGE_BALL

logger "Gentoo install: Unpacking the portage snapshot."

tar xjpf "$PORTAGE_SNAPSHOT" -C /mnt/gentoo/usr
rm $PORTAGE_SNAPSHOT

################################################################################
#                                                                              #
#                                Preparing for CHROOT                          #
#                                                                              #
################################################################################

rm /mnt/gentoo/etc/portage/make.conf
echo "$MAKE_CONF" > /mnt/gentoo/etc/portage/make.conf

cp -L /etc/resolv.conf /mnt/gentoo/etc/resolv.conf

mount -t proc none /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev

################################################################################
#                                                                              #
#                                   CHROOT Script                              #
#                                                                              #
################################################################################

read -r -d '' INNER_SCRIPT <<'INNERSCRIPT'
env-update
source /etc/profile
export PS1="(autochroot) $PS1" # Not that the user will see this.

# Is there any reason the handbook specifies anything but emerges to be done
# _after_ the chroot?

# Extract data passed to us from the pre-chroot script.
ETC_CONFD_HOSTNAME="$1"
ETC_TIMEZONE="$2"
KERNEL_SOURCES="$3"
KERNEL_CONFIG_PATH="$4"
FSTAB="$5"
ETC_CONFD_NET_FILE_CONTENT="$6"
ETC_HOSTS_CONTENT="$7"
ETC_CONFD_KEYMAPS_CONTENT="$8"
NET_IFNAME="$9"

script_emerge_sync() {
    logger "Syncing portage"
    emerge -q --sync
}

script_env_update() {
    logger "Gentoo install: Updating environment"
    env-update
    logger "Gentoo install: sourcing environment"
    source /etc/profile
}

script_write_fstab() {
    logger "Gentoo install: Writing fstab"
    echo "" > /etc/fstab
    echo "$FSTAB" > /etc/fstab
}

script_conf_timezone() {
    echo "$ETC_TIMEZONE" > /etc/timezone
    emerge --config sys-libs/timezone-data
}

script_conf_hostname() {
    logger "Gentoo install: setting hostname"
    echo "hostname=\"$ETC_CONFD_HOSTNAME\"" > /etc/conf.d/hostname
}

script_conf_net() {
    logger "Configuring network"
    # Write the etc/conf.d/net file.
    echo "$ETC_CONFD_NET_FILE_CONTENT" > /etc/conf.d/net
    echo "$ETC_HOSTS_CONTENT" >> /etc/hosts
    ln -s /etc/init.d/net.lo /etc/init.d/net.$NET_IFNAME
    rc-update add net.$NET_IFNAME default
}

script_conf_locales_write() {
    logger "Writing and generating locales"
    echo '' > /etc/locale.gen
    echo "en_US ISO-8859-1" >> /etc/locale.gen
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
}

script_conf_locales_select() {
    logger "Configuring environment locales"
    echo '' > /etc/env.d/02locale
    echo 'LANG="en_US.UTF-8"' >> /etc/env.d/02locale
    echo 'LC_COLLATE="C"' >> /etc/env.d/02locale
}

script_conf_locales() {
    script_conf_locales_write
    locale-gen
    script_conf_locales_select
    script_env_update
}

script_emerge_portage_update() {
    logger "Gentoo install: Updating portage"
    emerge -q --update --deep --newuse sys-apps/portage
}

script_emerge_toolchain() {
    logger "Gentoo install: rebuilding toolchain"
    emerge -q --oneshot binutils gcc virtual/libc
}

script_emerge_rebuild_world() {
    # Rebuild the whole thing with our latest compiler, binutils...
    logger "Gentoo install: rebuilding world"
    emerge -q -e world
}

script_emerge() {
    logger "Gentoo install: emerging $*"
    emerge -q $*
}

script_copy_kernel() {
    cd /usr/src/linux
    KERNEL_DIRECTORY=$(pwd -P)
    KERNEL_NAME=$(basename $KERNEL_DIRECTORY)
    cp $KERNEL_DIRECTORY/arch/x86_64/boot/bzImage /boot/kernel-$KERNEL_NAME
    cp $KERNEL_DIRECTORY/.config /boot/config-$KERNEL_NAME
}


# Start

script_emerge_sync
script_emerge_portage_update
script_conf_timezone
script_conf_locales

script_emerge_toolchain
script_env_update
script_emerge_rebuild_world
script_env_update

logger "Gentoo install: Installing kernel-sources"
emerge -q $KERNEL_SOURCES
cd /usr/src/linux
wget -O .config $KERNEL_CONFIG_PATH
make && make modules_install
script_copy_kernel

script_write_fstab
script_conf_hostname
script_conf_net
echo "root:Hello." | chpasswd
echo "$ETC_CONFD_KEYMAPS_CONTENT" > /etc/conf.d/keymaps

script_emerge sys-fs/udev sys-fs/lvm2 app-admin/syslog-ng sys-process/fcron
rc-update add udev sysinit
rc-config add udev-mount sysinit
rc-config add lvm boot
rc-update add syslog-ng default
fcrontab -u systab /etc/crontab
rc-update add fcron default
rc-update add sshd default
grep -v rootfs /proc/mounts > /etc/mtab
echo "sys-boot/grub device-mapper" >> /etc/portage/package.use
emerge -q sys-boot/grub
# echo "GRUB_PRELOAD_MODULES=lvm" >> /etc/default/grub
grub2-install /dev/sda
grub2-mkconfig -o /boot/grub/grub.cfg

script_emerge app-portage/gentoolkit
script_emerge app-admin/logrotate

echo "SUCCESS!"
INNERSCRIPT

echo "Preparing chroot script"

# Write the script.
echo "$INNER_SCRIPT" > /mnt/gentoo/chroot_inner_script.sh 

echo "Running chroot script"

# and run it. Wish us luck!
chroot /mnt/gentoo/ /bin/bash /chroot_inner_script.sh "$ETC_CONFD_HOSTNAME" "$ETC_TIMEZONE" "$KERNEL_SOURCES" "$KERNEL_CONFIG_PATH" "$FSTAB" "$ETC_CONFD_NET_FILE_CONTENT" "$ETC_HOSTS_CONTENT" "$ETC_CONFD_KEYMAPS_CONTENT" "$NET_IFNAME"

if [[ $? -ne 0 ]]; then
    echo "chroot install script failed. Read output, collect logs, submit bugs..."
fi

cd
umount /mnt/gentoo/boot /mnt/gentoo/proc /mnt/gentoo/home /mnt/gentoo/var
umount /mnt/gentoo/usr /mnt/gentoo/opt /mnt/gentoo/tmp
reboot
