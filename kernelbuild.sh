#!/bin/bash
#link="https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.0.11.tar.xz" #was used for testing
read -p "Please enter the link to the kernel tar file: " link

#EDIT
#EDIT 2 - Jayden


#Variables to set
kerneldir=$HOME/kernels
debdir=$HOME/kernels/built-debs

#Variables that should not be changed
file=${link##*/}
name=${file::-7}
version=${name:6}
debdirname=${debdir##*/}

#if link ends in .tar.xz continue, else, exit
if [[ "$link" == *.tar.xz ]] || [[ "$link" == *.tar.gz ]]
then
    :
else
    echo "Link is incorrect"
    exit
fi

if [[ $file == *rc* ]]; then
 version=$(sed 's/\(-rc\)/.0\1/g' <<< $version)
fi
#check for file name, if found, ask the user if they want the file redownloaded
if [ -e $file ]
then
    read -r -p "File exists. Do you want to redownload the file, if not, existing file will be used? [y/N] " response
    response=${response,,}    # tolower
    if [[ "$response" =~ ^(yes|y)$ ]]
    then
        rm $file
        wget $link
    fi
else
    wget $link
fi

#create directory for kernel build and for outputed debs
mkdir $kerneldir/$name
mkdir $debdir/$name

#extract tar file to kernel build directory
echo "Extracting tar file..."
tar xaf $kerneldir/$file
rm $file
echo "Done!"

#cd into kernel directory then copy current config and delete CONFIG_SYSTEM_TRUSTED_KEYS = ""
cd $kerneldir/$name && {
cp /boot/config-`uname -r` .config
sed -i "/CONFIG_SYSTEM_TRUSTED_KEYS/d" .config

#make oldconfig then build kernel
make olddefconfig
make -j`nproc` bindeb-pkg
}
#delete build directory, then move newly created deb packages to debdir version subfolder
rm -r $kerneldir/$name
mv $kerneldir/*$version* $debdir/$name

#install linux-headers, linux-image and linux-libc-dev
read -r -p "Do you want to install the kernel debs automatically? [y/N] " response
    response=${response,,}    # tolower
    if [[ "$response" =~ ^(yes|y)$ ]]
    then
        echo "Sudo is required, so please enter your password when the prompt appears"
        sudo apt install "./$debdirname/$name/linux-image-${version}_${version}-1_`dpkg --print-architecture`.deb" "./$debdirname/$name/linux-headers-${version}_${version}-1_`dpkg --print-architecture`.deb" "./$debdirname/$name/linux-libc-dev_${version}-1_`dpkg --print-architecture`.deb"
    fi
echo "This script has finished building your Linux $version kernel, enjoy!"
