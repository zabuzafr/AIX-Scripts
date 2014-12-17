#!/bin/bash
# Name: setup_aix_for_gpfs.bash
# Version : 1.0
# This script helps to configure HDS VSP disk drive for GPFS and db2 PureScale
# 
# MIMIFIR Pierre-Jacques - OpenSource - 2014/08/27 - initial creation
#
#
# VARS
queue_depth=32
num_cmd_elems=1000
algorithm="round_robin"
timeout_policy="retry_path"
reserve_policy="PR_shared"
maxuproc=10000;
max_xfer_size="0x800000"

displayHelp(){
	echo  -e "massive-resource-deallocation.sh v1.0 for AIX"
	echo  -e "written by Miguel PAIVA - PMU, 2014/07/28\n"
	echo  -e "This scripts helps configure HDS VSP MPIO disks for DB2 PureScale"
	echo  -e "Options:"
	echo  -e " -h, --help:\n\tOptional. Displays this message."
	echo  -e " -q, queue_depth."
	echo  -e " -p, maxuproc."
	echo  -e " -m, max_xfer_size."
	echo  -e " -r, reserve_policy."
	echo  -e " -t, timeout_policy."
	echo  -e " -a, timeout_policy."
	echo  -e "Default:"
	echo  -e "\tmaxuproc:${maxuproc}"
	echo  -e "\tnum_cmd_elems:${num_cmd_elems}"
	echo  -e "\tmax_xfer_size:${max_xfer_size}"
	echo  -e "\treserve_policy:${reserve_policy}"
	echo  -e "\ttimeout_policy:${timeout_policy}"
	echo  -e "\talgorithm:${algorithm}"
	echo  -e "\tqueue_depth:${queue_depth}"
}


while [ $# -gt 0 ]
do
case $1 in
-p|--maxuproc) maxuproc=$2;shift;;
-n|--num_cmd_elems) num_cmd_elems=$2;shift;;
-m|--max_xfer_size) max_xfer_size=$2;shift;;
-r|--reserve_policy) reserve_policy=$2;shift;;
-t|--timeout_policy) timeout_policy=$1;shift;;
-a|--algorithm) algorithm=$2;shift;;
-q|--queue_depth) queue_depth=$2 ; shift ;;
-h|--help) displayHelp ; exit 0;;
*) displayHelp ; exit 1;;
esac
shift
done


# Setup hdisk rond_robin and  PR_shared (SCSI3-PR) GPFS MPIO Drive on My  HDS VSP
# ALL GPFS drive on VSP must be in host_mode 72 with SCSI3-PR
# I used my LPAR hostid for PR_key_value attribute
pr_key=`hostid`
index=0
for disk in $(lsdev -Cc disk -F name|grep -v hdisk0$| grep -v hdisk1$)
do
pr_key_value=`echo ${pr_key} $index|sed 's/ //g`
		echo "chdev -Pl $disk -a PR_key_value=${pr_key_value} -a queue_depth=${queue_depth} -a algorithm=${algorithm}  -a timeout_policy=${timeout_policy} -a  reserve_policy=${reserve_policy}" |/bin/ksh
		index=`expr $index + 1`
				done
#
#
#
for fcs in $(lsdev -C  -F name | grep fcs )
		do
		chdev -P -l $fcs -a max_xfer_size=${max_xfer_size} -a num_cmd_elems=${num_cmd_elems}
		done
# Passer le nombre de processus utilisateur de 200 à 10000
chdev -l sys0 -a maxuproc=${maxuproc}
# Activer  tous les threads des cores CPUs
smtctl -m on
#activer ASO
asoo -p -o aso_active=1
for fscsi in $(lsdev -C -F name | grep fscsi )
do
chdev -Pl $fscsi -a dyntrk=yes -a fc_err_recov=fast_fail
done
no -po rfc1323=1
