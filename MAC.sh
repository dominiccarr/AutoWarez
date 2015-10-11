#! /usr/bin/env bash

# Get Airport MAC Address : ifconfig en1 | grep ether
# 
# Step 1 : disassociate from all wireless networks
# 
# Run command: sudo /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -z
# 
# The airport command is part or Apple’s Apple80211 framework. -z disassociates from any network.
# 
# Set symbolic link : sudo ln -s /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport /usr/sbin/airport
#  
# In future use airport -z to disassociate
# 
# airport -I = information on your current connection
# 
# Step 2: Change your MAC address
# 
# sudo ifconfig en1 ether 00:00:00:00:00:00
# 
# verify by running : ifconfig en1 | grep ether

sudo /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -z

sudo ifconfig en1 ether c8:bc:c8:ea:05:b4

echo "Modified Wireless MAC Address"