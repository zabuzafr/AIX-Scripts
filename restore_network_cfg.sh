#!/usr/bin/ksh
# Name : restore_network_cfg.sh
# This script helps to rebuild all configured networks interfaces from a ODM backup that into /tmp/devsave
# I used this script after a devreset in maintenance mode when my LPAR was Hungs with the code 551 -> 555
# You can also use this script after removing HDS HDLM or EMC PowerPATH driver's and a devreset.
#
# History:
# MIMIFIR Pierre-Jacques - Open Source script for IBM AIX -  [---]	- 2014/11/2 - last update for HDS drives
# MIMIFIR Pierre-Jacques - Open Source script for IBM AIX -  [---]	- 2008/04/02- Initital version
#
out_script="/tmp/script_rebuild.ksh"
>${out_script}
if [ ! -e "/tmp/devsave" ]
then
        echo "No ODM backup found into this system"
		exit -1
fi
export ODMDIR="/tmp/devsave"
#
# Restore network settings
#
for  en in $(odmget -q ddins=if_en CuDv | grep name| awk '{print $3}' | sed "s/\"//g")
do
        ip=`odmget -q "name=${en} and attribute=netaddr" CuAt | grep value | awk '{print $3}'`
        netmask=`odmget -q "name=${en} and attribute=netmask" CuAt | grep value | awk '{print $3}'`
		if [ `echo ${ip} | grep -c  "\." ` -gt 0 ]
		then
			echo chdev -l ${en} -a netaddr=${ip} -a netmask=${netmask} -a state=up
			echo chdev -l ${en} -a netaddr=${ip} -a netmask=${netmask} -a state=up >> ${out_script}
		fi
done
hostname_=`odmget -q "name=inet0 and attribute=hostname" CuAt | grep value | awk '{print $3}'`
# Add Hostname
echo chdev -l inet0 -a hostname=${hostname_} >> ${out_script}
#
# Add networks routes
#
for route in $(odmget -q "name=inet0 and attribute=route "  CuAt | grep value | awk '{print $3}')
do
        echo chdev -l inet0 -a route=${route} >> ${out_script}
done
#
# Get informations of VG for a from disk objects
#
for vgname in $(odmget -q attribute=vgserial_id CuAt| grep name |awk '{print $3}' | grep -v rootvg)
do
  vgid=`odmget -q "attribute=pv and name=${vgname}" CuAt | grep value|awk '{print $3}'`
   echo "importvg -y ${vgname} ${vgid}" >> ${out_script}
done
export ODMDIR=/etc/objrepos
echo "The script to run is hold into /tmp/script_rebuild.ksh"
