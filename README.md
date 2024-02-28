# arch-setup

This repository contains two scripts for my personal arch-setup.

## install.bash

This script is based on [Walian0's install script](https://github.com/walian0/bashscripts/blob/main/arch_plasma_auto.bash), which is inspired by [swsnr's script](https://github.com/swsnr/dotfiles/blob/main/arch/install.bash).

The script is intended to install Arch Linux with:

- Encrypted root
- Encrypted swap (+ hibernate & resume)
- Unified Kernel Image
- Secure Boot
- EFISTUB
- btrfs

## postinstall.sh

This script is intended to be used with yay.
It is working as is, but not up to date with my current setup.

Currently it is used to install:

- Hyprland (hyprland-git) + Apps (like rofi, waybar, ...)
- base tools
- Audio (pipewire, wireplumber)
- Bluetooth
- Kernel Modules (for my XPS 9720)
- various tools like bat, tlp, btop, bitwarden, ...
- KVM & QEMU


Please keep in mind this repository is for my personal use, but made public so everyone can have a look at how I do it.
Feel free to modify it and make it fit your needs!
