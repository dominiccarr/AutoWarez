#!/bin/sh

# runs the renamer scripts
source ~/.bash_profile
all

#removes all torrent files
cd /Users/user/Library/Application\ Support/Transmission/Resume

rm *.resume

cd /Users/user/Library/Application\ Support/Transmission/Torrents

rm *.torrent

# makes a text record of what episodes 
# we have not watched in case of HDD fail
touch ~/Dropbox/Documents/to-watch.txt 
ls -R ~/Content/ >~/Dropbox/Documents/to-watch.txt