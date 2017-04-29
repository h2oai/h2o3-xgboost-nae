#!/bin/bash

# This will start H2o backgrounded, and automatically consume 90% available memory

# If you want S3 support create a core-site.xml file and place it in $HOME/.ec2/

# Assumes the h2o.jar you want is in /opt

set -e

d=`dirname $0`

# Use 90% of RAM for H2O.
memTotalKb=`cat /proc/meminfo | grep MemTotal | sed 's/MemTotal:[ \t]*//' | sed 's/ kB//'`
memTotalMb=$[ $memTotalKb / 1024 ]
tmp=$[ $memTotalMb * 90 ]
xmxMb=$[ $tmp / 100 ]

# HDFS credentials.
hdfs_config_option=""
hdfs_config_value=""
hdfs_option=""
hdfs_option_value=""
hdfs_version=""
if [ -f .ec2/core-site.xml ]
then
  hdfs_config_option="-hdfs_config"
  hdfs_config_value=".ec2/core-site.xml"
  hdfs_option="-hdfs"
  hdfs_option_value=""
  hdfs_version=""
fi

java -Xmx${xmxMb}m -jar /opt/h2o3-xgboost/h2o.jar -name H2ODemo -flatfile flatfile.txt -port 54321 ${hdfs_config_option} ${hdfs_config_value} ${hdfs_option} ${hdfs_option_value} ${hdfs_version}
