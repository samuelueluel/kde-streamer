#!/usr/bin/env bash

set -ouex pipefail

echo "Baking dotfiles snapshot from public repo..."

DOTFILES_OWNER="${DOTFILES_OWNER:-samuelueluel}"
git clone --depth=1 "https://github.com/${DOTFILES_OWNER}/dotfiles.git" /usr/share/kde-streamer/dotfiles
rm -rf /usr/share/kde-streamer/dotfiles/.git

chmod +x /usr/bin/kjust
