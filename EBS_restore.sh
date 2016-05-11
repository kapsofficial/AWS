#!/bin/bash
#AutoRestore Snapshot
#Author:KapilYadav: kapsofficial@gmail.com
#2016-04-15
echo ------------------------------------------
echo   ++Auto Restore Started, please wait++
echo ------------------------------------------
instance_id=$(wget -q -O- http://169.254.169.254/latest/meta-data/instance-id)
corr=`df -h | grep DB | awk '{print $1}' | tail -c 3`
Old=`aws ec2 describe-volumes --output text  | grep $corr | grep $instance_id | awk '{print $7}'`
#Unmout Volume from linux machinei
echo "---Processing umount Volume from linux machine---"
/bin/umount -l /<mount-point>

#Detaching Corrupted Volume
echo "---Detaching Corrupted Volume---"
ec2-detach-volume --region ap-southeast-1 $Old
sleep 2;

#Finding latest snapshot
echo "---Finding latest snapshot---"
Snapshot_id=`ec2-describe-snapshots --region ap-southeast-1 | grep Database | awk '{print $5,$2}'|sort|awk '{print $2}'  | tail -1`

#Creating new volume using latest snapshot
echo "---Creating new volume using latest snapshot---"
ec2-create-volume --size 5 --snapshot $Snapshot_id --region ap-southeast-1 --availability-zone  ap-southeast-1b --type gp2 > /var/log/Restore_volume.txt
sleep 15;
vol_id=`cat /var/log/Restore_volume.txt | awk '{print $2}'`

#############################################################################################################
EBS_state=`aws ec2 describe-volumes --output text | grep $vol_id | awk '{print $8}'`

	if [ "$EBS_state" = "available" ]
	   then
#Attaching Volume to required instance
echo "---Attaching Volume to required instance---"
aws ec2 attach-volume --volume-id $vol_id --instance-id <instance-id> --device /dev/sdl
sleep 15;
	else
echo --Volume state is $EBS_state, please wait....---
sleep 15;
	if [ "$EBS_state" = "available" ]
	then
#Attaching Volume to required instance
echo "---Attaching Volume to required instance---"
aws ec2 attach-volume --volume-id $vol_id --instance-id <instance-id> --device /dev/sdl
sleep 15;
	else
sleep 15;
	if [ "$EBS_state" = "creating" ]
        then
echo ---Please wait.. Volume state is pending, sleeping 150seconds---
sleep 150;
	else
        if [ "$EBS_state" = "available" ]
        then
#Attaching Volume to required instance
echo "---Attaching Volume to required instance---"
aws ec2 attach-volume --volume-id $vol_id --instance-id <instance-id> --device /dev/sdl
sleep 15;
	else
echo ---Thers is some issue in attaching, please proceed with manual action---
exit
fi
fi
fi
fi
	

#Mounting newly added volume to linux machine
echo "---Mounting newly added volume to /DB linux machine---"
/bin/mount /dev/xvdl /<mount-point>

echo --------------------------------
echo    @@ Restore Completed @@
echo --------------------------------
