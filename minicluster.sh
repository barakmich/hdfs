#!/bin/sh

HADOOP_DISTRO=${HADOOP_DISTRO-"cdh5"}
HADOOP_HOME=${HADOOP_HOME-"/tmp/hadoop-$HADOOP_DISTRO"}
NN_PORT=${NN_PORT-"9000"}
HADOOP_NAMENODE="localhost:$NN_PORT"

if [ ! -d "$HADOOP_HOME" ]; then
  mkdir -p $HADOOP_HOME

  if [ $HADOOP_DISTRO = "cdh5" ]; then
      HADOOP_URL="http://archive.cloudera.com/cdh5/cdh/5/hadoop-latest.tar.gz"
  elif [ $HADOOP_DISTRO = "hdp2" ]; then
      HADOOP_URL="http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.4.0.0/tars/hadoop-2.7.1.2.4.0.0-169.tar.gz"
  else
      echo "No/bad HADOOP_DISTRO='${HADOOP_DISTRO}' specified"
      exit 1
  fi

  echo "Downloading Hadoop from $HADOOP_URL to ${HADOOP_HOME}/hadoop.tar.gz"
  curl -o ${HADOOP_HOME}/hadoop.tar.gz -L $HADOOP_URL

  echo "Extracting ${HADOOP_HOME}/hadoop.tar.gz into $HADOOP_HOME"
  tar zxf ${HADOOP_HOME}/hadoop.tar.gz --strip-components 1 -C $HADOOP_HOME
fi

MINICLUSTER_JAR=$(find $HADOOP_HOME -name "hadoop-mapreduce-client-jobclient*.jar" | grep -v tests | grep -v sources | head -1)
if [ ! -f "$MINICLUSTER_JAR" ]; then
  echo "Couldn't find minicluster jar!"
  exit 1
fi

echo "Starting minicluster..."
$HADOOP_HOME/bin/hadoop jar $MINICLUSTER_JAR minicluster -nnport $NN_PORT -datanodes 3 -nomr -format "$@" > minicluster.log 2>&1 &
echo "Waiting for namenode to start up..."
$HADOOP_HOME/bin/hdfs dfsadmin "-Dfs.defaultFS=$HADOOP_NAMENODE" -safemode wait

HADOOP_FS="$HADOOP_HOME/bin/hadoop fs"
./fixtures.sh

echo "Please run the following commands:"
echo "export HADOOP_NAMENODE='$HADOOP_NAMENODE'"
echo "export HADOOP_FS='$HADOOP_HOME/bin/hadoop'"
