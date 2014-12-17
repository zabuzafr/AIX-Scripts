		#!/usr/bin/perl
		# Name : rsync_nimodm.pl
		# This script synchronize resources on a NIM master to the alternate NIM Master
		#
		# (c) You  need to setup PermitRootLong=yes into the file /etc/ssh/ssd_config on the alternate NIM Master
		#
		# MIMIFIR Pierre-Jacques  -  Open Script - 2014/08/08 - Initial version
		#
		use strict;

		my $rsync="/usr/bin/rsync";
		my $nim="/usr/sbin/nim";
		my $lsnim="/usr/sbin/lsnim";
		my $df="/usr/bin/df";

		my %object_dir;

		my $nim_master="master";
		my $nim_slave;

		if (! -e $rsync ){
			die "RSYNC is not installed on  this host\n";
		}

		sub get_location_dir{
			my $object=shift;
			my $loc=undef;
			if(open S,"$lsnim -l $object |"){
				while(<S>){
					s/^\s+//g;
					if(/location/i){
						my($t1,$t2,$t3,$t4)=split /\s+/;
						$loc=$t3;
						if( -d $loc ){
							if(open DIR,"$df $loc |"){
								while(<DIR>){
									if(/^\/dev/){
										my @arr=split /\s+/;
										$loc=$arr[6];
									}
								}
								close DIR;
							}
						}else{
							undef $loc;
						}
					}
				}
				close S;
			}
			return $loc;
		}

		# find the alternate master NIM server
		if(open F,"$lsnim |"){
			while(<F>){
				my ($name,$t1,$t2)=split/\s+/;
				if(/alternate/){
					$nim_slave=$name;	
				}
				if(/lpp_sourc|script|spot|file_res|bundle/){
					$object_dir{get_location_dir($name)}=1 if defined get_location_dir($name);
				}
			}
			close F;
		}

		delete $object_dir{"/"};
		delete $object_dir{" "};
		foreach my $file (sort keys %object_dir){
			#my $cmd_rsync="$rsync -e '/usr/bin/ssh -o LogLevel=error -i /root/.ssh/rsync'  --exclude='mksysb' -xopavz $file $nim_slave:$file";
			my $cmd_rsync="$rsync -e '/usr/bin/ssh -o LogLevel=error'   --exclude='mksysb' -xopavz $file $nim_slave:$file";
			`$cmd_rsync`;
			if( $? == 0 ){
				print "$cmd_rsync \t\t[32m [OK][0m\n";
			}else{
				print "$cmd_rsync \t\t[31m [KO][0m\n";
			}
		}
		my $cmd="$nim -o sync -a replicate -a force=yes $nim_slave";
		`$cmd`;
		if( $? == 0 ){
			print "$cmd \t\t[32m [OK][0m\n";
		}else{
			print "$cmd \t\t[31m [KO][0m\n";
		}
}
