#!/bin/bash
#Author: KapilYadav
#Email: kapsofficial@gmail.com
#This script add instances in Load Balancer, when needed. 
echo "Press 1 to Add instances"
echo "Press 2 to Remove instance"
echo -n "enter your choice :"
read p;
instanceid=(instance-id-1 instance-id-2 instance-id-3)
declare -a checkstatus;

case $p in 
1 )
a=0;
echo "enter the no of instances you want to add to the load balancer:"
read n;

for ((i=1;i<=n;i++))
do
for ((j=0;j<=(${#instanceid[@]} - 1);j++))
do
#echo $j;
checkstatus[$j]=`aws ec2 describe-instances --instance-id ${instanceid[$j]} | egrep "stopped|running" | awk '{print $3}'`
echo ${sheckstatus[$j]};

if [ "${checkstatus[$j]}" = "stopped" ]
then
aws ec2 start-instances  --instance-ids ${instanceid[$j]} ;

aws elb register-instances-with-load-balancer --load-balancer-name Test --instances ${instanceid[$j]} ;
a=$((a+1))
if [ $a -eq $n ]
then
echo " $a Instances added to the load balancer" ;
exit
fi
fi

done
done

;;

2 ) 
a=0;
echo "enter the no of instances you want to Remove from the load balancer:"
read n;

for ((i=1;i<=n;i++))
do
for ((j=0;j<=(${#instanceid[@]} - 1);j++))
do
#echo $j;
checkstatus[$j]=`aws ec2 describe-instances --instance-id ${instanceid[$j]} | egrep "stopped|running" | awk '{print $3}'`
echo ${sheckstatus[$j]};

if [ "${checkstatus[$j]}" = "running" ]
then
aws elb deregister-instances-from-load-balancer --load-balancer-name Test --instances ${instanceid[$j]} ;

aws ec2 stop-instances  --instance-ids ${instanceid[$j]} ;
a=$((a+1))
if [ $a -eq $n ]
then
echo " $a Instances Removed to the load balancer" ;
exit
fi
fi

done
done

;;

*)
 echo " Please chose one number atleast"

esac
