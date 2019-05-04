#!/bin/bash
link=git://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git
read -p "Please enter the linux-next version, it should look like this 'next-20190503': " branch

#Variables to set
kerneldir=$HOME/kernels
debdir=$HOME/kernels/built-debs

#Variables that should not be changed
#file=${link##*/}
name=$branch
version=${name:5}
debdirname=${debdir##*/}

#create directory for kernel build and for outputed debs
#mkdir $kerneldir/$name
mkdir $debdir/$name

#clone the git repo
git clone --branch $branch --single-branch $link

#cd into kernel directory then copy current config and delete CONFIG_SYSTEM_TRUSTED_KEYS = ""
cd $kerneldir/linux-next && {
cp /boot/config-`uname -r` .config
sed -i "/CONFIG_SYSTEM_TRUSTED_KEYS/d" .config

#make oldconfig then build kernel
make olddefconfig
make -j`nproc` bindeb-pkg
}
#delete build directory, then move newly created deb packages to debdir version subfolder
rm -r $kerneldir/linux-next
mv $kerneldir/*$version* $debdir/$name

#install linux-headers, linux-image and linux-libc-dev
read -r -p "Do you want to install the kernel debs automatically? [y/N] " response
    response=${response,,}    # tolower
    if [[ "$response" =~ ^(yes|y)$ ]]
    then
        echo "Sudo is required, so please enter your password when the prompt appears"
        sudo apt install ./$debdirname/$name/linux-image-*-${name}_*-${name}-1_`dpkg --print-architecture`.deb ./$debdirname/$name/linux-headers-*-${name}_*-${name}-1_`dpkg --print-architecture`.deb ./$debdirname/$name/linux-libc-dev_*-${name}-1_`dpkg --print-architecture`.deb
    fi
echo "This script has finished building your Linux $version kernel, enjoy!"