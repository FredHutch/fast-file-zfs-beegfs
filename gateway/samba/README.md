## Maintaining clustered SMB file access

Samba services should always be kept updated to ensure performance, stability and security. 
You should either purchase a Samba plus subscription from sernet.de https://oposso.samba.plus/
or you can build packages yourself. 


### Building Samba Packages for Ubuntu 

Our approach to keeping samba packages current is to use source packages from a future Ubuntu 
distribution and recompile it on our current production LTS distribution. We recommend a build  
host with 8 cores and 4GB memory. Please use the script build-samba-latest.sh to build current 
samba packages. Check the comments inside the script
 

### creating a new APY repository 

You can use tools such as aptly to create a repos on a web server or you just put them in a 
mounted file system or a local folder on your samba server. 


    cd /opt/debs/samba
    dpkg-scanpackages -m . > Packages

    echo "deb [trusted=yes] file:/opt/debs/samba /" > /etc/apt/sources.list.d/samba.list
    apt update

### adding missing dependencies

When you install samba using apt you will likely have missing dependencies. You can find newer
packages on https://www.ubuntuupdates.org. Download the oldest package that will satisfy 
your needs. For example if you are building on 'bionic' (18.04) and take samba source packages
from 'eoan' (19.10) it may be best to take missing binary packages from 'cosmic' (18.10) or
'disco' (19.04) as they are 'closer to home'. After you add deb packages to /opt/debs/samba 
make sure that you re-run dpkg-scanpackages and 'apt update'


### configuring samba



