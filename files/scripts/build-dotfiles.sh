#!/usr/bin/env bash

set -ouex pipefail

echo "Fetching minimal dotfiles (zsh + Brewfile) from public repo..."

DOTFILES_OWNER="${DOTFILES_OWNER:-samuelueluel}"
WORK_DIR=$(mktemp -d)

git clone --depth=1 --filter=blob:none --no-checkout \
    "https://github.com/${DOTFILES_OWNER}/dotfiles.git" "$WORK_DIR"

cd "$WORK_DIR"
git sparse-checkout init --cone
git sparse-checkout set dot_zshrc dot_zshenv dot_Brewfile
git checkout

mkdir -p /usr/share/kde-streamer
cp -v "$WORK_DIR/dot_zshrc"   /usr/share/kde-streamer/
cp -v "$WORK_DIR/dot_zshenv"  /usr/share/kde-streamer/
cp -v "$WORK_DIR/dot_Brewfile" /usr/share/kde-streamer/

rm -rf "$WORK_DIR"

chmod +x /usr/bin/kjust
