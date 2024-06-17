#!/bin/bash
# Macbook Pro M1 Big Sur
# Reboot your Mac into Recovery Mode by restarting while holding power button, then click options, the Terminal from top menu
# csrutil disable
# csrutil authenticated-root disable
# reboot to desktop

# Find your root mount's device - run mount and chop off the last s, e.g. if your / is /dev/disk3s1s1, you'll mount /dev/disk1s2
mkdir -p -m777 ~/mount
sudo mount -o nobrowse -t apfs /dev/disk1s2 ~/mount

sudo rm -rf ~/mount/System/Applications/Chess.app
sudo rm -rf ~/mount/System/Applications/Contacts.app
sudo rm -rf ~/mount/System/Applications/Dictionary.app
sudo rm -rf ~/mount/System/Applications/FaceTime.app
sudo rm -rf ~/mount/System/Applications/FindMy.app
sudo rm -rf ~/mount/System/Applications/Home.app
sudo rm -rf ~/mount/System/Applications/Mail.app
sudo rm -rf ~/mount/System/Applications/Maps.app
sudo rm -rf ~/mount/System/Applications/Messages.app
sudo rm -rf ~/mount/System/Applications/Music.app
sudo rm -rf ~/mount/System/Applications/News.app
sudo rm -rf ~/mount/System/Applications/Notes.app
sudo rm -rf ~/mount/System/Applications/Photo\ Booth.app
sudo rm -rf ~/mount/System/Applications/Photos.app
sudo rm -rf ~/mount/System/Applications/Podcasts.app
sudo rm -rf ~/mount/System/Applications/Reminders.app
sudo rm -rf ~/mount/System/Applications/Siri.app
sudo rm -rf ~/mount/System/Applications/Stickies.app
sudo rm -rf ~/mount/System/Applications/Stocks.app
sudo rm -rf ~/mount/System/Applications/TV.app
sudo rm -rf ~/mount/System/Applications/VoiceMemos.app
sudo rm -rf ~/mount/System/Applications/Utilities/VoiceOver\ Utility.app

# Mission Control
defaults write com.apple.dock mcx-expose-disabled -bool TRUE
#defaults delete com.apple.dock mcx-expose-disabled

# Dashboard
defaults write com.apple.dashboard mcx-disabled -bool TRUE
#defaults delete com.apple.dashboard mcx-disabled

# Spotlight
# sudo mdutil -a -i off
# sudo chmod 0 ~/mount/System/Library/CoreServices/Spotlight.app
#sudo mdutil -a -i on
#sudo chmod 755 /System/Library/CoreServices/Spotlight.app

sudo bless --folder ~/mount/System/Library/CoreServices --bootefi --create-snapshot

killall Dock

echo -e "\033[1;31m THANK YOU APPLE \033[0m"
