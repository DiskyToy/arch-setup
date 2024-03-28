#!/bin/bash
# uncomment to view debugging information 
#set -xeuo pipefail

#check if we're root
if [[ "$UID" -ne 0 ]]; then
    echo "This script needs to be run as root!" >&2
    exit 3
fi

### Config options
target="/dev/nvme0n1"
rootmnt="/mnt"
locale="en_US.UTF-8"
keymap="de-latin1-nodeadkeys"
timezone="Europe/Vienna"
hostname="earth"
username="human"
#SHA512 hash of password. To generate, run 'mkpasswd -m sha-512', don't forget to prefix any $ symbols with \ . The entry below is the hash of 'password'
#or just simply copy from your current /etc/shadow
user_password="\$6\$....x//"
#To fully automate the setup, change badidea=no to yes, and enter a cleartext password for the disk and swap encryption
badidea="no"
crypt_password="PLAINTEXT NVME ENCRYPTION PASSWORD"
swap_password="PLAINTEXT SWAP PASSWORD"

### Packages to pacstrap ##
pacstrappacs=(
        base
	base-devel
        linux
        linux-firmware
        intel-ucode
        #amd-ucode
        vim
        nano
        cryptsetup
        util-linux
        e2fsprogs
        dosfstools
        sudo
        reflector
        networkmanager
        )    
### Desktop packages #####
guipacs=(
	kitty
	nm-connection-editor
	neofetch
 	sbctl
	make
	fakeroot
	cmake
	go
	)


# Partition
echo "Creating partitions..."
sgdisk -Z "$target"
sgdisk \
    -n1:0:+512M    -t1:ef00 -c1:EFISYSTEM \
    -n2::-32G  	   -t2:8304 -c2:linux \
    -N3            -t3:8200 -c3:SWAP \
    "$target"
# Reload partition table
sleep 2
partprobe -s "$target"
sleep 2
echo "Encrypting root and swap partition..."
#Encrypt the root and swap partition. If badidea=yes, then pipe cryptpass and carry on, if not, prompt for it
if [[ "$badidea" == "yes" ]]; then
echo -n "$crypt_password" | cryptsetup luksFormat --type luks2 /dev/disk/by-partlabel/linux -
echo -n "$crypt_password" | cryptsetup luksOpen /dev/disk/by-partlabel/linux root -
echo -n "$swap_password"  | cryptsetup luksFormat --type luks2 /dev/disk/by-partlabel/SWAP -
echo -n "$swap_password"  | cryptsetup luksOpen /dev/disk/by-partlabel/SWAP swap -
else
cryptsetup luksFormat --type luks2 /dev/disk/by-partlabel/linux
cryptsetup luksOpen /dev/disk/by-partlabel/linux root
cryptsetup luksFormat --type luks2 /dev/disk/by-partlabel/SWAP
crpytsetup luksOpen /dev/disk/by-partlabel/SWAP swap
fi
echo "Making File Systems..."
# Create file systems
mkfs.vfat -F32 -n EFISYSTEM /dev/disk/by-partlabel/EFISYSTEM
mkfs.btrfs -f -L linux /dev/mapper/root
mkswap /dev/mapper/swap
# mount the root, and create + mount the EFI directory
echo "Mounting File Systems..."
mount /dev/mapper/root "$rootmnt"
mkdir "$rootmnt"/efi -p
mount -t vfat /dev/disk/by-partlabel/EFISYSTEM "$rootmnt"/efi
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/srv
btrfs subvolume create /mnt/var
btrfs subvolume create /mnt/var/log
btrfs subvolume create /mnt/var/cache
btrfs subvolume create /mnt/var/tmp


#Update pacman mirrors and then pacstrap base install
echo "Pacstrapping..."
reflector --country AT --age 24 --protocol http,https --sort rate --save /etc/pacman.d/mirrorlist
pacstrap -K $rootmnt "${pacstrappacs[@]}" 

echo "Setting up environment..."
#set up locale/env
#add our locale to locale.gen
sed -i -e "/^#"$locale"/s/^#//" "$rootmnt"/etc/locale.gen
#remove any existing config files that may have been pacstrapped, systemd-firstboot will then regenerate them
rm "$rootmnt"/etc/{machine-id,localtime,hostname,shadow,locale.conf} ||
systemd-firstboot --root "$rootmnt" \
	--keymap="$keymap" --locale="$locale" \
	--locale-messages="$locale" --timezone="$timezone" \
	--hostname="$hostname" --setup-machine-id \
	--welcome=false
arch-chroot "$rootmnt" locale-gen
echo "Configuring for first boot..."
#add the local user
arch-chroot "$rootmnt" useradd -G wheel -m -p "$user_password" "$username" 
#uncomment the wheel group in the sudoers file
sed -i -e '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' "$rootmnt"/etc/sudoers
#create a basic kernel cmdline, we're using DPS so we don't need to have anything here really, but if the file doesn't exist, mkinitcpio will complain
swapid="$(lsblk -f | grep 'p3' | awk 'NR>0 {print $NF}')"
#rd.luks.name and resume are options for encrypted swap. "quiet rw" would be default without encrypted swap.
echo "rd.luks.name=$swapid=swap resume=/dev/mapper/swap quiet rw" > "$rootmnt"/etc/kernel/cmdline
#change the HOOKS in mkinitcpio.conf to use systemd hooks
#systemd hook takes care of the resume hook
sed -i \
    -e 's/base udev/base systemd/g' \
    -e 's/keymap consolefont/sd-vconsole sd-encrypt/g' \
    "$rootmnt"/etc/mkinitcpio.conf
#change the preset file to generate a Unified Kernel Image instead of an initram disk + kernel
sed -i \
    -e '/^#ALL_config/s/^#//' \
    -e '/^#default_uki/s/^#//' \
    -e '/^#default_options/s/^#//' \
    -e 's/default_image=/#default_image=/g' \
    -e "s/PRESETS=('default' 'fallback')/PRESETS=('default')/g" \
    "$rootmnt"/etc/mkinitcpio.d/linux.preset

#read the UKI setting and create the folder structure otherwise mkinitcpio will crash
declare $(grep default_uki "$rootmnt"/etc/mkinitcpio.d/linux.preset)
arch-chroot "$rootmnt" mkdir -p "$(dirname "${default_uki//\"}")"

#install the gui packages
echo "Installing GUI..."
arch-chroot "$rootmnt" pacman -Sy "${guipacs[@]}" --noconfirm --quiet


#enable the services we will need on start up
echo "Enabling services..."
systemctl --root "$rootmnt" enable systemd-resolved systemd-timesyncd NetworkManager
#mask systemd-networkd as we will use NetworkManager instead
systemctl --root "$rootmnt" mask systemd-networkd
#regenerate the ramdisk, this will create our UKI
echo "Generating UKI and installing Boot Loader..."
arch-chroot "$rootmnt" mkinitcpio -p linux
echo "Setting up Secure Boot..."
if [[ "$(efivar -d --name 8be4df61-93ca-11d2-aa0d-00e098032b8c-SetupMode)" -eq 1 ]]; then
arch-chroot "$rootmnt" sbctl create-keys
arch-chroot "$rootmnt" sbctl enroll-keys -m
arch-chroot "$rootmnt" sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed /usr/lib/systemd/boot/efi/systemd-bootx64.efi
arch-chroot "$rootmnt" sbctl sign -s "${default_uki//\"}"
else
echo "Not in Secure Boot setup mode."
fi

#install the systemd-boot bootloader
arch-chroot "$rootmnt" bootctl install --esp-path=/efi
#lock the root account
arch-chroot "$rootmnt" usermod -L root
#and we're done


echo "-----------------------------------------"
echo "- Install complete. You can reboot now! -"
echo "-----------------------------------------"
sleep 10
sync
#reboot

