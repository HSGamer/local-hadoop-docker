FROM ubuntu:22.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    openssh-server \
    rsync \
    curl \
    wget \
    python3 \
    python3-pip \
    scala \
    net-tools \
    vim \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$PATH:$JAVA_HOME/bin

# Configure SSH
RUN mkdir /var/run/sshd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Create hadoop user
RUN useradd -m -s /bin/bash hadoop && \
    echo "hadoop:hadoop" | chpasswd && \
    adduser hadoop sudo

# Configure passwordless sudo for the hadoop user
RUN echo "hadoop ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/hadoop

# Switch to hadoop user for installation
USER hadoop
WORKDIR /home/hadoop

# Install Hadoop 3.4.2 Lean
RUN wget https://dlcdn.apache.org/hadoop/common/hadoop-3.4.2/hadoop-3.4.2-lean.tar.gz && \
    tar -xzf hadoop-3.4.2-lean.tar.gz && \
    mv hadoop-3.4.2 hadoop && \
    rm hadoop-3.4.2-lean.tar.gz

# Install Pig 0.18.0
RUN wget https://dlcdn.apache.org/pig/pig-0.18.0/pig-0.18.0.tar.gz && \
    tar -xzf pig-0.18.0.tar.gz && \
    mv pig-0.18.0 pig && \
    rm pig-0.18.0.tar.gz

# Install Hive 4.1.0
RUN wget https://dlcdn.apache.org/hive/hive-4.1.0/apache-hive-4.1.0-bin.tar.gz && \
    tar -xzf apache-hive-4.1.0-bin.tar.gz && \
    mv apache-hive-4.1.0-bin hive && \
    rm apache-hive-4.1.0-bin.tar.gz

# Install Spark 3.5.6 (with Hadoop 3)
RUN wget https://dlcdn.apache.org/spark/spark-3.5.6/spark-3.5.6-bin-hadoop3.tgz && \
    tar -xzf spark-3.5.6-bin-hadoop3.tgz && \
    mv spark-3.5.6-bin-hadoop3 spark && \
    rm spark-3.5.6-bin-hadoop3.tgz

# Set environment variables
ENV HADOOP_HOME=/home/hadoop/hadoop
ENV HADOOP_INSTALL=$HADOOP_HOME
ENV HADOOP_MAPRED_HOME=$HADOOP_HOME
ENV HADOOP_COMMON_HOME=$HADOOP_HOME
ENV HADOOP_HDFS_HOME=$HADOOP_HOME
ENV YARN_HOME=$HADOOP_HOME
ENV HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"

ENV PIG_HOME=/home/hadoop/pig
ENV PIG_CLASSPATH=$HADOOP_CONF_DIR

ENV HIVE_HOME=/home/hadoop/hive
ENV HIVE_CONF_DIR=$HIVE_HOME/conf

ENV SPARK_HOME=/home/hadoop/spark

ENV PATH=$PATH:$HADOOP_HOME/sbin:$HADOOP_HOME/bin
ENV PATH=$PATH:$PIG_HOME/bin
ENV PATH=$PATH:$HIVE_HOME/bin
ENV PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin

# Configure SSH (passwordless)
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys

# Add SSH config
RUN echo "Host *\n  StrictHostKeyChecking no\n  UserKnownHostsFile /dev/null" > ~/.ssh/config && \
    chmod 600 ~/.ssh/config

# Configure Hadoop - core-site.xml
RUN echo '<?xml version="1.0" encoding="UTF-8"?>\n\
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>\n\
<configuration>\n\
    <property>\n\
        <name>fs.defaultFS</name>\n\
        <value>hdfs://localhost:9000</value>\n\
    </property>\n\
    <property>\n\
        <name>hadoop.tmp.dir</name>\n\
        <value>/home/hadoop/hadoop_tmp</value>\n\
    </property>\n\
</configuration>' > $HADOOP_CONF_DIR/core-site.xml

# Configure Hadoop - hdfs-site.xml
RUN echo '<?xml version="1.0" encoding="UTF-8"?>\n\
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>\n\
<configuration>\n\
    <property>\n\
        <name>dfs.replication</name>\n\
        <value>1</value>\n\
    </property>\n\
    <property>\n\
        <name>dfs.namenode.name.dir</name>\n\
        <value>file:///home/hadoop/hadoop_data/namenode</value>\n\
    </property>\n\
    <property>\n\
        <name>dfs.datanode.data.dir</name>\n\
        <value>file:///home/hadoop/hadoop_data/datanode</value>\n\
    </property>\n\
    <property>\n\
        <name>dfs.permissions.enabled</name>\n\
        <value>false</value>\n\
    </property>\n\
    <property>\n\
        <name>dfs.webhdfs.enabled</name>\n\
        <value>true</value>\n\
    </property>\n\
</configuration>' > $HADOOP_CONF_DIR/hdfs-site.xml

# Configure Hadoop - mapred-site.xml
RUN echo '<?xml version="1.0"?>\n\
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>\n\
<configuration>\n\
    <property>\n\
        <name>mapreduce.framework.name</name>\n\
        <value>yarn</value>\n\
    </property>\n\
    <property>\n\
        <name>mapreduce.application.classpath</name>\n\
        <value>$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/*:$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/lib/*</value>\n\
    </property>\n\
    <property>\n\
        <name>yarn.app.mapreduce.am.env</name>\n\
        <value>HADOOP_MAPRED_HOME=/home/hadoop/hadoop</value>\n\
    </property>\n\
    <property>\n\
        <name>mapreduce.map.env</name>\n\
        <value>HADOOP_MAPRED_HOME=/home/hadoop/hadoop</value>\n\
    </property>\n\
    <property>\n\
        <name>mapreduce.reduce.env</name>\n\
        <value>HADOOP_MAPRED_HOME=/home/hadoop/hadoop</value>\n\
    </property>\n\
    <property>\n\
        <name>mapreduce.map.memory.mb</name>\n\
        <value>512</value>\n\
    </property>\n\
    <property>\n\
        <name>mapreduce.reduce.memory.mb</name>\n\
        <value>512</value>\n\
    </property>\n\
    <property>\n\
        <name>mapreduce.map.java.opts</name>\n\
        <value>-Xmx256m</value>\n\
    </property>\n\
    <property>\n\
        <name>mapreduce.reduce.java.opts</name>\n\
        <value>-Xmx256m</value>\n\
    </property>\n\
    <property>\n\
        <name>yarn.app.mapreduce.am.resource.mb</name>\n\
        <value>512</value>\n\
    </property>\n\
    <property>\n\
        <name>yarn.app.mapreduce.am.command-opts</name>\n\
        <value>-Xmx256m</value>\n\
    </property>\n\
    <property>\n\
        <name>mapreduce.jobhistory.address</name>\n\
        <value>localhost:10020</value>\n\
    </property>\n\
    <property>\n\
        <name>mapreduce.jobhistory.webapp.address</name>\n\
        <value>0.0.0.0:19888</value>\n\
    </property>\n\
</configuration>' > $HADOOP_CONF_DIR/mapred-site.xml

# Configure Hadoop - yarn-site.xml
RUN echo '<?xml version="1.0"?>\n\
<configuration>\n\
    <property>\n\
        <name>yarn.nodemanager.aux-services</name>\n\
        <value>mapreduce_shuffle</value>\n\
    </property>\n\
    <property>\n\
        <name>yarn.nodemanager.env-whitelist</name>\n\
        <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_MAPRED_HOME</value>\n\
    </property>\n\
    <property>\n\
        <name>yarn.resourcemanager.hostname</name>\n\
        <value>localhost</value>\n\
    </property>\n\
    <property>\n\
        <name>yarn.scheduler.minimum-allocation-mb</name>\n\
        <value>256</value>\n\
    </property>\n\
    <property>\n\
        <name>yarn.scheduler.maximum-allocation-mb</name>\n\
        <value>4096</value>\n\
    </property>\n\
    <property>\n\
        <name>yarn.nodemanager.resource.memory-mb</name>\n\
        <value>4096</value>\n\
    </property>\n\
    <property>\n\
        <name>yarn.nodemanager.vmem-check-enabled</name>\n\
        <value>false</value>\n\
    </property>\n\
    <property>\n\
        <name>yarn.scheduler.minimum-allocation-vcores</name>\n\
        <value>1</value>\n\
    </property>\n\
    <property>\n\
        <name>yarn.scheduler.maximum-allocation-vcores</name>\n\
        <value>4</value>\n\
    </property>\n\
    <property>\n\
        <name>yarn.nodemanager.resource.cpu-vcores</name>\n\
        <value>4</value>\n\
    </property>\n\
    <property>\n\
        <name>yarn.resourcemanager.scheduler.class</name>\n\
        <value>org.apache.hadoop.yarn.server.resourcemanager.scheduler.capacity.CapacityScheduler</value>\n\
    </property>\n\
    <property>\n\
        <name>yarn.nodemanager.disk-health-checker.enable</name>\n\
        <value>false</value>\n\
    </property>\n\
    <property>\n\
        <name>yarn.resourcemanager.webapp.address</name>\n\
        <value>0.0.0.0:8088</value>\n\
    </property>\n\
    <property>\n\
        <name>yarn.log-aggregation-enable</name>\n\
        <value>true</value>\n\
    </property>\n\
</configuration>' > $HADOOP_CONF_DIR/yarn-site.xml

# Set JAVA_HOME in hadoop-env.sh
RUN echo "export JAVA_HOME=$JAVA_HOME" >> $HADOOP_CONF_DIR/hadoop-env.sh

# Configure Hive
RUN cp $HIVE_HOME/conf/hive-default.xml.template $HIVE_HOME/conf/hive-site.xml

# Create necessary directories
RUN mkdir -p ~/hadoop_tmp && \
    mkdir -p ~/hadoop_data/namenode && \
    mkdir -p ~/hadoop_data/datanode && \
    mkdir -p ~/spark-logs

# Configure Spark
RUN cp $SPARK_HOME/conf/spark-defaults.conf.template $SPARK_HOME/conf/spark-defaults.conf && \
    echo "spark.master yarn" >> $SPARK_HOME/conf/spark-defaults.conf && \
    echo "spark.eventLog.enabled true" >> $SPARK_HOME/conf/spark-defaults.conf && \
    echo "spark.eventLog.dir file:///home/hadoop/spark-logs" >> $SPARK_HOME/conf/spark-defaults.conf

# Spark events directory
RUN mkdir -p /tmp/spark-events && chmod 777 /tmp/spark-events

# Switch back to root for final setup
USER root

# Create Hadoop initialization script
COPY <<EOF /home/hadoop/init-hadoop.sh
#!/bin/bash
# Source environment variables
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export HADOOP_HOME=/home/hadoop/hadoop
export HADOOP_INSTALL=\$HADOOP_HOME
export HADOOP_MAPRED_HOME=\$HADOOP_HOME
export HADOOP_COMMON_HOME=\$HADOOP_HOME
export HADOOP_HDFS_HOME=\$HADOOP_HOME
export YARN_HOME=\$HADOOP_HOME
export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_HOME/lib/native
export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop
export HADOOP_OPTS="-Djava.library.path=\$HADOOP_HOME/lib/native"
export PIG_HOME=/home/hadoop/pig
export PIG_CLASSPATH=\$HADOOP_CONF_DIR
export HIVE_HOME=/home/hadoop/hive
export HIVE_CONF_DIR=\$HIVE_HOME/conf
export SPARK_HOME=/home/hadoop/spark
export PATH=\$PATH:\$HADOOP_HOME/sbin:\$HADOOP_HOME/bin:\$PIG_HOME/bin:\$HIVE_HOME/bin:\$SPARK_HOME/bin:\$SPARK_HOME/sbin

# Format namenode if not already formatted
if [ ! -d "/home/hadoop/hadoop_data/namenode/current" ]; then
    echo "Formatting namenode..."
    hdfs namenode -format -force
fi

# Start Hadoop services
echo "Starting Hadoop services..."
start-dfs.sh
sleep 5
start-yarn.sh

# Start MapReduce JobHistory Server
mapred --daemon start historyserver

# Wait for services to start
echo "Waiting for services to initialize..."
sleep 15

# Check if services are running
echo "Checking service status..."
hdfs dfsadmin -report
yarn node -list

# Create HDFS directories for Hive
echo "Setting up HDFS directories..."
hdfs dfs -mkdir -p /tmp
hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -chmod g+w /tmp
hdfs dfs -chmod g+w /user/hive/warehouse

# Initialize Hive schema if needed
if [ ! -f "/home/hadoop/.hive_initialized" ]; then
    echo "Initializing Hive schema..."
    schematool -dbType derby -initSchema
    touch /home/hadoop/.hive_initialized
fi

# Start Spark history server
start-history-server.sh

echo ""
echo "All Hadoop services started successfully!"
echo "You can now run MapReduce jobs, Pig scripts, Hive queries, and Spark applications."
echo ""
EOF

# Create diagnostic script
COPY <<EOF /home/hadoop/check-status.sh
#!/bin/bash
echo "=== Hadoop Cluster Status ==="
echo ""
echo "Java Processes:"
jps
echo ""
echo "HDFS Status:"
hdfs dfsadmin -report
echo ""
echo "YARN Nodes:"
yarn node -list
echo ""
echo "YARN Applications:"
yarn application -list
echo ""
echo "HDFS Usage:"
hdfs dfs -df -h
echo ""
echo "Recent Log Files:"
echo "NameNode logs:"
ls -la \$HADOOP_HOME/logs/*namenode* 2>/dev/null || echo "No namenode logs found"
echo "ResourceManager logs:"
ls -la \$HADOOP_HOME/logs/*resourcemanager* 2>/dev/null || echo "No resourcemanager logs found"
echo ""
echo "=== End Status Report ==="
EOF

# Create test script
COPY <<EOF /home/hadoop/test-hadoop.sh
#!/bin/bash
echo "Testing Hadoop with sample jobs..."
echo ""

# Test 1: HDFS operations
echo "=== Test 1: HDFS Operations ==="
echo "Creating test directory..."
hdfs dfs -mkdir -p /user/hadoop/test
echo "Creating a test file..."
echo "Hello Hadoop World!" > /tmp/test.txt
hdfs dfs -put /tmp/test.txt /user/hadoop/test/
echo "Listing HDFS contents:"
hdfs dfs -ls /user/hadoop/test/
echo "Reading file from HDFS:"
hdfs dfs -cat /user/hadoop/test/test.txt
echo ""

# Test 2: MapReduce WordCount example
echo "=== Test 2: MapReduce WordCount ==="
echo "Preparing input data..."
hdfs dfs -mkdir -p /user/hadoop/wordcount/input
echo "The quick brown fox jumps over the lazy dog" > /tmp/input1.txt
echo "The dog was lazy but the fox was quick" > /tmp/input2.txt
hdfs dfs -put /tmp/input*.txt /user/hadoop/wordcount/input/
echo "Running WordCount job..."
hadoop jar \$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount /user/hadoop/wordcount/input /user/hadoop/wordcount/output
echo "WordCount results:"
hdfs dfs -cat /user/hadoop/wordcount/output/part-*
echo ""

echo "All tests completed!"
EOF

# Set permissions
RUN chmod +x /home/hadoop/init-hadoop.sh && \
    chmod +x /home/hadoop/check-status.sh && \
    chmod +x /home/hadoop/test-hadoop.sh && \
    chown hadoop:hadoop /home/hadoop/init-hadoop.sh && \
    chown hadoop:hadoop /home/hadoop/check-status.sh && \
    chown hadoop:hadoop /home/hadoop/test-hadoop.sh

# Add environment variables to hadoop user's .bashrc
RUN echo '' >> /home/hadoop/.bashrc && \
    echo '# Hadoop Environment Variables' >> /home/hadoop/.bashrc && \
    echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> /home/hadoop/.bashrc && \
    echo 'export HADOOP_HOME=/home/hadoop/hadoop' >> /home/hadoop/.bashrc && \
    echo 'export HADOOP_INSTALL=$HADOOP_HOME' >> /home/hadoop/.bashrc && \
    echo 'export HADOOP_MAPRED_HOME=$HADOOP_HOME' >> /home/hadoop/.bashrc && \
    echo 'export HADOOP_COMMON_HOME=$HADOOP_HOME' >> /home/hadoop/.bashrc && \
    echo 'export HADOOP_HDFS_HOME=$HADOOP_HOME' >> /home/hadoop/.bashrc && \
    echo 'export YARN_HOME=$HADOOP_HOME' >> /home/hadoop/.bashrc && \
    echo 'export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native' >> /home/hadoop/.bashrc && \
    echo 'export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop' >> /home/hadoop/.bashrc && \
    echo 'export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"' >> /home/hadoop/.bashrc && \
    echo 'export PIG_HOME=/home/hadoop/pig' >> /home/hadoop/.bashrc && \
    echo 'export PIG_CLASSPATH=$HADOOP_CONF_DIR' >> /home/hadoop/.bashrc && \
    echo 'export HIVE_HOME=/home/hadoop/hive' >> /home/hadoop/.bashrc && \
    echo 'export HIVE_CONF_DIR=$HIVE_HOME/conf' >> /home/hadoop/.bashrc && \
    echo 'export SPARK_HOME=/home/hadoop/spark' >> /home/hadoop/.bashrc && \
    echo 'export PATH=$PATH:$HADOOP_HOME/sbin:$HADOOP_HOME/bin:$PIG_HOME/bin:$HIVE_HOME/bin:$SPARK_HOME/bin:$SPARK_HOME/sbin' >> /home/hadoop/.bashrc

# Create startup script
COPY <<EOF /startup.sh
#!/bin/bash
# Start SSH service
service ssh start

# Initialize Hadoop services as hadoop user
su - hadoop -c "/home/hadoop/init-hadoop.sh" &

# Wait a moment for initialization to start
sleep 5

echo ""
echo "===================================="
echo "Hadoop ecosystem is starting up!"
echo "===================================="
echo "Hadoop NameNode: http://localhost:9870"
echo "YARN ResourceManager: http://localhost:8088"
echo "Spark History Server: http://localhost:18080"
echo "MapReduce JobHistory: http://localhost:19888"
echo ""
echo "SSH Access:"
echo "  ssh hadoop@localhost -p 2222 (password: hadoop)"
echo ""
echo "Available commands:"
echo "  hdfs - HDFS commands"
echo "  yarn - YARN commands"
echo "  pig - Start Pig shell"
echo "  hive - Start Hive shell"
echo "  spark-shell - Start Spark Scala shell"
echo "  pyspark - Start Spark Python shell"
echo "  spark-sql - Start Spark SQL shell"
echo ""
echo "Diagnostic tools:"
echo "  ./check-status.sh - Check cluster status"
echo "  ./test-hadoop.sh - Run sample jobs"
echo "===================================="

# Keep container running
tail -f /dev/null
EOF

RUN chmod +x /startup.sh

# Expose ports
# HDFS ports
EXPOSE 9000 9870 9864 9866 9867 9868 9869
# YARN ports
EXPOSE 8088 8042 8030 8031 8032 8033 8040 8041
# MapReduce JobHistory Server
EXPOSE 10020 19888
# Spark ports
EXPOSE 4040 18080 7077 8080 8081
# Hive ports
EXPOSE 10000 10002 9083
# SSH
EXPOSE 22

# Set working directory
WORKDIR /home/hadoop

# Default command
CMD ["/startup.sh"]
