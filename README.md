# Hadoop Local Cluster

A complete Hadoop ecosystem running in Docker with persistent data storage.

> [!NOTE]
> Some parts of the project are AI-generated.
> This is intended to be used for educational purposes only. Not for production.

## 🏗️ What's Included

- **Hadoop 3.4.2** (HDFS + YARN + MapReduce)
- **Apache Spark 3.5.6**
- **Apache Hive 4.1.0**
- **Apache Pig 0.18.0**
- **SSH Server** for remote access

## 🚀 Quick Start

### Linux/macOS
1. **Clone and Setup**
   ```bash
   # Make the setup script executable
   chmod +x setup-hadoop.sh

   # Run setup (creates directories and starts services)
   ./setup-hadoop.sh
   ```

### Windows (PowerShell)
1. **Clone and Setup**
   ```powershell
   # Run setup (creates directories and starts services)
   .\setup-hadoop.ps1
   ```

2. **Wait for Initialization**
   - First startup takes 2-3 minutes
   - Monitor progress: `docker-compose logs -f hadoop` (or `docker compose logs -f hadoop`)

3. **Access the Cluster**
   ```bash
   # SSH into the container
   ssh hadoop@localhost -p 2222
   # Password: hadoop

   # Or use Docker exec
   docker-compose exec hadoop bash
   # (or docker compose exec hadoop bash)
   ```

## 📊 Web UIs

| Service | URL | Description |
|---------|-----|-------------|
| HDFS NameNode | http://localhost:9870 | HDFS cluster overview |
| YARN ResourceManager | http://localhost:8088 | Job tracking and cluster resources |
| Spark History Server | http://localhost:18080 | Spark application history |
| MapReduce JobHistory | http://localhost:19888 | MapReduce job history |
| HiveServer2 Web UI | http://localhost:10002 | Hive query interface |

## 🛠️ Common Commands

### Cluster Management
```bash
# Start cluster
docker-compose up -d
# or: docker compose up -d

# Stop cluster
docker-compose down
# or: docker compose down

# View logs
docker-compose logs -f hadoop
# or: docker compose logs -f hadoop

# Check cluster status
docker-compose exec hadoop ./check-status.sh
# or: docker compose exec hadoop ./check-status.sh

# Run test jobs
docker-compose exec hadoop ./test-hadoop.sh
# or: docker compose exec hadoop ./test-hadoop.sh
```

### HDFS Operations
```bash
# List HDFS contents
hdfs dfs -ls /

# Create directory
hdfs dfs -mkdir /user/data

# Upload file
hdfs dfs -put local-file.txt /user/data/

# Download file
hdfs dfs -get /user/data/file.txt ./

# Check HDFS usage
hdfs dfs -df -h
```

### YARN/MapReduce
```bash
# List running applications
yarn application -list

# Run WordCount example
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar \
  wordcount /input /output

# Check node status
yarn node -list
```

### Spark
```bash
# Spark Scala shell
spark-shell

# Spark Python shell
pyspark

# Spark SQL shell
spark-sql

# Submit Spark job
spark-submit --class YourMainClass your-app.jar
```

### Hive
```bash
# Start Hive CLI
hive

# Example Hive commands
CREATE TABLE test (id INT, name STRING);
INSERT INTO test VALUES (1, 'Alice'), (2, 'Bob');
SELECT * FROM test;
```

### Pig
```bash
# Start Pig shell
pig

# Example Pig script
data = LOAD '/input/data.txt' AS (line:chararray);
words = FOREACH data GENERATE FLATTEN(TOKENIZE(line));
grouped = GROUP words BY $0;
counts = FOREACH grouped GENERATE group, COUNT(words);
STORE counts INTO '/output';
```

## 📁 Data Persistence

All data is stored in local directories and persists between container restarts:

**Linux/macOS:**
```
./data/
├── namenode/          # HDFS NameNode metadata
├── datanode/          # HDFS DataNode blocks
├── logs/              # Hadoop service logs
├── tmp/               # Temporary files
├── spark-logs/        # Spark application logs
├── spark-events/      # Spark event logs for history server
└── hive/
    ├── warehouse/     # Hive data warehouse
    └── metastore/     # Hive metadata database

./workspace/           # Your development files
```

**Windows:**
```
.\data\
├── namenode\          # HDFS NameNode metadata
├── datanode\          # HDFS DataNode blocks
├── logs\              # Hadoop service logs
├── tmp\               # Temporary files
├── spark-logs\        # Spark application logs
├── spark-events\      # Spark event logs for history server
└── hive\
    ├── warehouse\     # Hive data warehouse
    └── metastore\     # Hive metadata database

.\workspace\           # Your development files
```

## 🔧 Configuration

### Resource Limits
The cluster is configured with:
- **Memory**: 8GB limit, 4GB reservation
- **CPU**: 4 cores limit, 2 cores reservation
- **YARN Memory**: 4GB available
- **MapReduce Tasks**: 512MB each

### Ports Exposed
| Port | Service |
|------|---------|
| 2222 | SSH |
| 9000 | HDFS NameNode IPC |
| 9870 | HDFS NameNode Web UI |
| 8088 | YARN ResourceManager Web UI |
| 19888 | MapReduce JobHistory Web UI |
| 18080 | Spark History Server |
| 10000 | HiveServer2 |
| And more... |

## 🛠 Troubleshooting

### Services Not Starting
```bash
# Check container logs
docker-compose logs hadoop
# or: docker compose logs hadoop

# Check service status inside container
docker-compose exec hadoop ./check-status.sh
# or: docker compose exec hadoop ./check-status.sh

# Restart services
docker-compose restart hadoop
# or: docker compose restart hadoop
```

### Out of Memory Issues
```bash
# Check resource usage
docker stats hadoop-local

# Increase Docker memory allocation in Docker Desktop
# Or adjust resource limits in docker-compose.yml
```

### Permission Issues

**Linux/macOS:**
```bash
# Fix data directory permissions
sudo chown -R $USER:$USER ./data ./workspace
chmod -R 755 ./data ./workspace
```

**Windows (PowerShell as Administrator):**
```powershell
# Fix data directory permissions
icacls .\data /grant:r "$($env:USERNAME):(OI)(CI)F" /T
icacls .\workspace /grant:r "$($env:USERNAME):(OI)(CI)F" /T
```

### HDFS Safe Mode
```bash
# If HDFS is in safe mode
docker-compose exec hadoop hdfs dfsadmin -safemode leave
# or: docker compose exec hadoop hdfs dfsadmin -safemode leave
```

### Reset Cluster

**Linux/macOS:**
```bash
# Stop and remove everything
docker-compose down -v

# Remove data (⚠️ This deletes all data!)
sudo rm -rf ./data

# Setup again
./setup-hadoop.sh
```

**Windows (PowerShell):**
```powershell
# Stop and remove everything
docker-compose down -v
# or: docker compose down -v

# Remove data (⚠️ This deletes all data!)
Remove-Item -Path .\data -Recurse -Force

# Setup again
.\setup-hadoop.ps1
```

## 📈 Performance Tuning

For better performance on your specific hardware:

1. **Adjust memory settings** in `docker-compose.yml`:
   ```yaml
   environment:
     - YARN_HEAPSIZE=2048    # Increase heap size
     - HADOOP_HEAPSIZE=2048
   ```

2. **Modify YARN configuration** in the Dockerfile:
   - Increase `yarn.nodemanager.resource.memory-mb`
   - Adjust `mapreduce.map.memory.mb` and `mapreduce.reduce.memory.mb`

3. **Allocate more resources** to Docker:
   - Increase Docker Desktop memory allocation
   - Adjust `deploy.resources` in docker-compose.yml

## 🔍 Setup Script Features

Both setup scripts (`setup-hadoop.sh` for Linux/macOS and `setup-hadoop.ps1` for Windows) provide:

- **Automatic directory creation** with proper permissions
- **Docker Compose detection** (supports both legacy `docker-compose` and new `docker compose` commands)
- **Service health checks** to verify cluster startup
- **Colorized output** for better user experience
- **Comprehensive status information** including all web UI links and useful commands
- **Error handling** with informative messages

The scripts will automatically:
1. Create all necessary data directories
2. Set appropriate permissions
3. Detect and use the correct Docker Compose command
4. Start the Hadoop cluster
5. Wait for services to initialize
6. Perform health checks on key services
7. Display all relevant URLs and commands
