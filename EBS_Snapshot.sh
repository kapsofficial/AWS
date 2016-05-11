#!/bin/bash
#Author:KapilYadav
#This script take snapshots of defined volume and delete oldest
#Syntax: Ec2-rolling-snaphot -d "Description-Vol-Date" Volume 3[count]
while [ "$1" != "" ]
do
  case $1 in
    -h)
      showHelp;
      exit 0;;
    --help)
      showHelp;
      exit 0;;
    -\?)
      showHelp;
      exit 0;;
    --dry-run)
      dryrun=true;;
    -d)
      description=$2;
      volume=$3
      max_snapshots=$4;
      break;;
    --description)
      description=$2;
      volume=$3
      max_snapshots=$4;
      break;;
    *)
      gen_opts="$gen_opts $1";;
  esac
  shift;
done
 
if [ -z "$description" ]; then
  echo "Required parameter 'DESCRIPTION' missing (-h for usage)"
  exit 1
fi
 
if [ -z "$volume" ]; then
  echo "Required parameter 'VOLUME' missing (-h for usage)"
  exit 1
fi
 
if [ -z "$max_snapshots" ]; then
  echo "Required parameter 'MAX_SNAPSHOTS' missing (-h for usage)"
  exit 1
else
  if [ $max_snapshots -lt 1 ]; then
    exit 1
  fi
fi
 
if [ -z "$EC2_HOME" ]; then
  echo "ERROR: The EC2_HOME environment variable is not defined."
  exit 1
fi

#if [ -z "$AWS_ACCESS_KEY" ]; then
#  echo "ERROR: The AWS_ACCESS_KEY environment variable is not defined."
#  exit 1
#fi

#if [ -z "$AWS_SECRET_KEY" ]; then
#  echo "ERROR: The AWS_SECRET_KEY environment variable is not defined."
#  exit 1
#fi

tempfile=/tmp/ec2-create-rolling-snapshot-$$.tmp
 
ec2cmd="$EC2_HOME/bin/ec2-create-snapshot$gen_opts --region ap-southeast-1 -d \"$description\" $volume"
snapshot_id=
if [ -z "$dryrun" ]; then
  eval $ec2cmd > $tempfile
  result=`cat $tempfile`
  snapshot_id=`cat $tempfile|grep SNAPSHOT|awk '{print $2}'`
  snapshot_state=`cat $tempfile|grep SNAPSHOT|awk '{print $4}'`
  rm $tempfile
  if [ -z "$snapshot_id" ]; then
    echo "ERROR: Snapshot creation failed"
    echo "$result"
    exit 1
  fi
  if [ "$snapshot_state" != "pending" ] && [ "$snapshot_state" != "completed" ]; then
    echo "ERROR: Snapshot state is not pending or completed"
    echo "$result"
    exit 1
  fi
  echo "Created $snapshot_id from $volume"
else
  echo "Created snap-TBD from $volume (not really; this is a dry run)"
fi
 
ec2cmd="$EC2_HOME/bin/ec2-describe-snapshots$gen_opts --region ap-southeast-1"
eval $ec2cmd > $tempfile
if [ $dryrun ]; then
    echo "SNAPSHOT snap-TBD $volume pending 9999-99-99T99:99:99+9999 1 $description" >> $tempfile
fi
result=`cat $tempfile`
series=`cat $tempfile|grep SNAPSHOT|grep "$description"|grep $volume|awk '{print $5,$2}'|sort|awk '{print $2}'`
rm $tempfile
if [ -z "$series" ]; then
  echo "ERROR: Failed to get snapshot series"
  echo "$result"
  exit 1
fi
 
count=`echo "$series"|wc -l|awk '{print $1}'`
echo "Series now contains $count snapshots, max is $max_snapshots"
oldest=`echo "$series"|head -n 1|awk '{print $1}'`
if [ $count -gt $max_snapshots ]; then
  if [ -z "$dryrun" ]; then
    echo "Deleting $oldest"
    ec2cmd="$EC2_HOME/bin/ec2-delete-snapshot$gen_opts --region ap-southeast-1  $oldest"
    eval $ec2cmd > $tempfile
    result=`cat $tempfile`
    check1=`cat $tempfile|awk '{print $1}'`
    check2=`cat $tempfile|awk '{print $2}'`
    rm $tempfile
    if [ "$check1" != "SNAPSHOT" ] || [ "$check2" != $oldest ]; then
      echo "ERROR: Unexpected output from ec2-delete-snapshot command"
      echo "$result"
      exit 1
    fi
  else
    echo "Deleting $oldest (not really; this is a dry run)"
  fi
fi
 
exit 0
