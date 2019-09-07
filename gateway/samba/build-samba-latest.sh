#! /bin/bash

# this script takes the Ubuntu source package from a future Distro (in this case Samba) 
# and recompiles it the current (older) Distro. The key is to first install the 
# build-dep of the current Samba package and then only install select pacakges the 
# samba build complains about. 
# Note: Building on LXC hosts does not work. Error on bionic:  ERROR: System library 
# popt of version 0.0.0 not found, recipe for target 'override_dh_auto_configure' failed

# after building debs these binary packages from the future distribution also need to
# be added to the apt repos used for installing , e.g. https://www.ubuntuupdates.org: 
# python3-talloc, libldb1, libtdb1, libtalloc2, libevent0, python3 (3.7), python3-minimal,
# libpython3-stdlib, python3-tdb, python3-ldb, python3-crypto


# set the Ubuntu Distro from which you want to take the samba source package
distro='eoan' # Ubuntu 19.10
#export http_proxy=http://proxy-apt:3128/
export DEBIAN_FRONTEND=noninteractive

#add-apt-repository ppa:linux-schools/samba-latest
#sed -i '/deb-src/s/^# //' /etc/apt/sources.list.d/linux-schools-ubuntu-samba-latest-bionic.list

if [[ -f /etc/apt/sources.list.org ]]; then
  sudo mv /etc/apt/sources.list /etc/apt/sources.list.new
  sudo mv /etc/apt/sources.list.org /etc/apt/sources.list
  echo "restored sources.list, please start again"
  exit
else
  sudo cp /etc/apt/sources.list /etc/apt/sources.list.org
  sudo sed -i '/deb-src/s/^# //' /etc/apt/sources.list
fi

sudo -E apt-get update
sudo -E apt-get -y dist-upgrade
sudo -E apt-get install -y build-essential fakeroot devscripts
sudo -E apt-get build-dep -y samba

mkdir -p ~/src
cd ~/src
apt-get source -y samba
cd $(ls -1 | grep samba-4)

# optionally build old sources 
#debuild -us -uc -i -I

# now add build dependencies from newer distro
if [[ -f /etc/apt/sources.list.org ]]; then 
  sudo rm /etc/apt/sources.list
  echo "deb http://archive.ubuntu.com/ubuntu ${distro} main restricted" | sudo tee /etc/apt/sources.list > /dev/null
  echo "deb-src http://archive.ubuntu.com/ubuntu ${distro} main restricted" | sudo tee -a /etc/apt/sources.list > /dev/null
  echo "deb http://archive.ubuntu.com/ubuntu ${distro} universe" | sudo tee -a /etc/apt/sources.list > /dev/null
  echo "deb-src http://archive.ubuntu.com/ubuntu ${distro} universe" | sudo tee -a /etc/apt/sources.list > /dev/null
  sudo -E apt-get update
  sudo -E apt-get install -y dh-exec libcmocka-dev libldb-dev libtalloc-dev libtdb-dev libtevent-dev python3-ldb python3-ldb-dev python3-talloc-dev python3-tdb
fi

mkdir -p ~/src-${distro}
cd ~/src-${distro}
apt-get source -y samba
cd $(ls -1 | grep samba-4)

# sed -i 's/--prefix=\/usr \\/--prefix=\/usr \\\n\t--with-cluster-support \\/g' debian/rules
# debchange -i
# dpkg-source --commit

sudo mv /etc/apt/sources.list.org /etc/apt/sources.list

echo "running: debuild -us -uc -i -I -d"
debuild -us -uc -i -I -d

