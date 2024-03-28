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
	fwupd
	gvfs-smb
	linux-headers
	mtd-utils
	neovim
	ntfs-3g
	smartmontools
	ufw
	wget
	wireless_tools
	wpa_supplicant
    )
gui=(
	#Hypr Eco-System
	cliphist
	greetd-tuigreet-git
	grim
	hyprcursor
	hypridle
	#using the -git version because it fixed the resizing issue I had. Might change to "hyprland" in future
	hyprland-git
	hyprlock
	hyprpaper
	polkit-kde-agent
	qt5-base
	qt5-wayland
	qt6-base
	qt6-wayland
	rofi-lbonn-wayland-only-git
	slurp
	tiramisu-git
	ttf-font-awesome
	ttf-hack-nerd
	ttf-jetbrains-mono
	waybar
	wl-clipboard
	xdg-desktop-portal-gtk
	xdg-desktop-portal-hyprland
	xwaylandvideobridge
    )
audio=(
	#sof-firmware
	alsa-firmware
	alsa-utils
	gst-plugin-pipewire
	libpulse
	pamixer
	pavucontrol
	pipewire
	pipewire-alsa
	pipewire-audio
	pipewire-jack
	pipewire-pulse
	wireplumber
    )
drivers=(
	blueman
	bluez
	bluez-tools
	bluez-utils
	intel-media-driver
	libva-utils
	vulkan-intel
    )
kernelmodules=(
	#aic94xx-firmware
	#ast-firmware
	#linux-firmware-qlogic
	#upd72020x-fw
	#wd719x-firmware
    )
tools=(
	arch-audit
	bash-completion
	bat
	bitwarden
	brightnessctl
	btop
	btrfs-progs
	chromium
	discord
	eza
	fd
	fprintd
	fzf
	gimp
	glow
	gnome-calculator
	gnome-disk-utility
	icat
	imv
	linux-headers
	mpv
	network-manager-applet
	oh-my-zsh-git
	pam
	pam-u2f
	python-pip
	ripgrep
	signal-desktop
	spotify-launcher
	starship
	steam
	teamspeak3
	thunar
	thunar-archive-plugin
	thunar-vcs-plugin
	tlp
	udisks2
	unrar
	unzip
	visual-studio-code-bin
	wireguard-tools
	yubico-c
	yubico-c-client
	yubikey-manager
	yubikey-manager-qt
	yubikey-personalization
	yubikey-personalization-gui
	zsh
	zsh-completions
    )
theme=(
	arc-gtk-theme
	arc-icon-theme
	gnome-themes-extra
	gtk-engine-murrine
	nwg-look
	papirus-folders
	papirus-icon-theme
	plymouth
	plymouth-theme-arch-os
	qogit-cursor-theme-git
	vimix-cursors
	volantes-cursors-git
	)
kvmqemu=(
	bridge-utils
	dnsmasq
	ebtables
	edk2-ovmf
	iptables-nft
	nftables
	qemu-full
	qemu-hw-display-qxl	
	swtpm
	vde2
	virt-manager
	virt-viewer
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

echo "installing 'base'-packages"
sudo pacman -Sy --needed "${base[@]}" --noconfirm --quiet
sudo systemctl enable ufw.service
sudo systemctl start ufw.service
sudo ufw enable
sudo ufw default deny
sudo systemctl enable reflector.service

echo "installing 'GUI'-packages"
yay -S --needed "${gui[@]}" --noconfirm --quiet
sudo systemctl enable greetd

echo "installing 'audio'-packages"
yay -S --needed "${audio[@]}" --noconfirm --quiet
systemctl enable --user pipewire-pulse.service

echo "installing 'drivers'-packages"
yay -S --needed "${drivers[@]}" --noconfirm --quiet
sudo systemctl enable bluetooth.service

echo "installing 'kernelmodules'-packages"
yay -S --needed "${kernelmodules[@]}" --noconfirm --quiet

echo "installing 'tools'-packages"
yay -S --needed "${tools[@]}" --noconfirm --quiet
sudo systemctl enable tlp

echo "installing 'theme'-packages"
yay -S --needed "${tools[@]}" --noconfirm --quiet


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
    's/#user = "libvirt-qemu"/user = "INSERT_USER"/g' \
    's/#group = "libvirt-qemu"/user = "INSERT_USER"/g' \
    /etc/libvirt/qemu.conf

sudo systemctl restart libvirtd && sudo virsh net-autostart default
