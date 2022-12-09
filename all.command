#!/bin/sh

# runs the renamer scripts
source ~/.zshrc
all

#removes all torrent files
cd /Users/user/Library/Application\ Support/Transmission/Resume

rm *.resume

cd /Users/user/Library/Application\ Support/Transmission/Torrents

rm *.torrent