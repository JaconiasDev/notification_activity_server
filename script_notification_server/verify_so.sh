#!/bin/bash

so=$(cat /etc/os-release  | grep -v ".*_ID=" | grep "ID=" | cut -d '=' -f 2) 

verify_so () {

if [[ $so == "arch" ]] ; then

   echo "is_arch"

elif [[ $so == "debian" ]] ; then

   echo "is_debian"

fi

}
 verify_so