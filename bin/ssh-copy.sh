#!/bin/sh

# ssh-copy.sh  
#
#  Created by Sang Han on 5/28/13.


# Checks home .ssh directory for id_rsa or id_dsa public keys and appends them into the authorized_keys using a remote ssh server"

clear

if [ -f ~/.ssh/id_rsa.pub ]; then
read -p "User  " usr
read -p "Server " servr
cat ~/.ssh/id_rsa.pub | ssh -l "${usr}" "${servr}" "if [ -d ~/.ssh ]; then cat >> ~/.ssh/authorized_keys; else mkdir ~/.ssh; cat >> ~/.ssh/authorized_keys; fi"

elif [ -f ~/.ssh/id_dsa.pub ]; then
read -p "User  " usr
read -p "Server " servr
cat ~/.ssh/id_dsa.pub | ssh -l "${usr}" "${servr}" "if [ -d ~/.ssh ]; then cat >> ~/.ssh/authorized_keys; else mkdir ~/.ssh; cat >> ~/.ssh/authorized_keys; fi"

else

echo "public key does not exist"

fi
exit