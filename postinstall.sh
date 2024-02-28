#!/bin/bash

#-----------------------#
#			#
#   INSTALL YAY FIRST   #
#			#
#-----------------------#

#-----------------------#
#- Packages to install -#
#-----------------------#

base=(
	nano
	neovim
	openssh
	wget
	wireless_tools
	wpa_supplicant
	smartmontools
    )
gui=(
	hyprland-git
	xorg-xhost
	rofi
	waybar
	swww
	python-pywal
	ttf-font-awesome
	ttf-jetbrains-mono
	ttf-hack-nerd
	grim
	slurp
	qt5-base
	qt5-wayland
	qt6-base
	qt6-wayland
	swayidle
	swaylock
	xdg-desktop-portal-hyprland
	tiramisu-git
    )
audio=(
	pipewire
	pipewire-audio
	pipewire-alsa
	jack2
	pipewire-pulse
	gst-plugin-pipewire
	libpulse
	wireplumber
	#sof-firmware
    )
drivers=(
	bluez
	bluez-utils
	blueman
    )
kernelmodules=(
	#aic94xx-firmware
	#ast-firmware
	#linux-firmware-qlogic
	#wd719x-firmware
	#upd72020x-fw
    )
tools=(
	arch-audit
	bash-completion
	bat
	btrfs-progs
	tlp
	fzf
	btop
	chromium
	wireguard-tools
	kitty
	thunar
	bitwarden
	signal-desktop
	discord
	neofetch
	brightnessctl
	eza
	gimp
	glow
	gnome-calculator
	gnome-disk-utility
	imv
	mpv
	linux-headers
	network-manager-applet
	nm-connection-editor
	pam
	pam-u2f
	teamspeak3
	udisks2
	unzip
	yubico-c
	yubico-c-client
	yubikey-manager
	yubikey-manager-qt
	yubikey-personalization
	yubikey-personalization-gui
    )
kvmqemu=(
	virt-manager
	virt-viewer
	qemu-full
	vde2
	ebtables
	iptables-nft
	nftables
	dnsmasq
	bridge-utils
	ovmf
	swtpm
	qemu-hw-display-qxl	
    )

# optimize pacman
echo "activating Colors and Parallel Downloads for Pacman"
sudo sed -i \
    -e '/^#Color/s/^#//' \
    -e '/^#ParallelDownloads/s/^#//' \
    /etc/pacman.conf
#echo "activating multilib in pacman.conf"
#echo -e "[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
#pacman -Sy

sudo pacman -Sy --needed "${base[@]}" --noconfirm --quiet

yay -S --needed "${gui[@]}" --noconfirm --quiet
yay -S --needed "${audio[@]}" --noconfirm --quiet
yay -S --needed "${drivers[@]}" --noconfirm --quiet
sudo systemctl enable bluetooth.service
yay -S --needed "${kernelmodules[@]}" --noconfirm --quiet
yay -S --needed "${tools[@]}" --noconfirm --quiet
sudo systemctl enable tlp

systemctl enable --user pipewire-pulse.service

# kvm qemu stuff
sudo pacman -Sy --needed "${kvmqemu[@]}" --noconfirm --quiet
sudo sed -i \
    -e '/^#unix_sock_group/s/^#//' \
    -e '/^#unix_sock_rw_perms/s/^#//'\
    /etc/libvirt/libvirtd.conf
sudo usermod -a -G kvm,libvirt $(whoami)

sudo systemctl enable libvirtd && sudo systemctl start libvirtd

#replace with your user/group name
sudo sed -i \
    's/#user = "libvirt-qemu"/user = "jewld"/g' \
    's/#group = "libvirt-qemu"/user = "jewld"/g' \
    /etc/libvirt/qemu.conf

sudo systemctl restart libvirtd && sudo virsh net-autostart default
