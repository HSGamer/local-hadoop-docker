#!/bin/bash

# setup-hadoop.sh - Initialize Hadoop cluster directories and start services

set -e

echo "Setting up Hadoop cluster directories..."

# Create data directories
mkdir -p data/{namenode,datanode,logs,tmp,spark-logs,spark-events}
mkdir -p data/hive/{warehouse,metastore}
mkdir -p workspace

# Set proper permissions
chmod -R 755 data/
chmod -R 755 workspace/

echo "Directory structure created:"
echo "📁 data/"
echo "  ├── 📁 namenode/          (HDFS NameNode data)"
echo "  ├── 📁 datanode/          (HDFS DataNode data)"
echo "  ├── 📁 logs/              (Hadoop service logs)"
echo "  ├── 📁 tmp/               (Temporary files)"
echo "  ├── 📁 spark-logs/        (Spark application logs)"
echo "  ├── 📁 spark-events/      (Spark event logs)"
echo "  └── 📁 hive/"
echo "      ├── 📁 warehouse/     (Hive data warehouse)"
echo "      └── 📁 metastore/     (Hive metadata)"
echo "📁 workspace/              (Development workspace)"
echo ""

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null && ! command -v docker compose &> /dev/null; then
    echo "❌ Docker Compose not found. Please install Docker Compose."
    exit 1
fi

# Determine Docker Compose command
if command -v docker compose &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

echo "🐳 Starting Hadoop cluster..."
echo "This may take several minutes on first run..."
echo ""

# Start the services
$DOCKER_COMPOSE up -d --build

echo ""
echo "⏳ Waiting for services to initialize (this may take 2-3 minutes)..."
sleep 120

echo ""
echo "🎉 Hadoop cluster should be ready!"
echo ""
echo "📊 Web UIs available:"
echo "  🗄️  HDFS NameNode:        http://localhost:9870"
echo "  🧵  YARN ResourceManager: http://localhost:8088"
echo "  ⚡  Spark History Server: http://localhost:18080"
echo "  📈  MapReduce JobHistory:  http://localhost:19888"
echo "  🐝  HiveServer2 Web UI:    http://localhost:10002"
echo ""
echo "🔌 SSH Access:"
echo "  ssh hadoop@localhost -p 2222"
echo "  Password: hadoop"
echo ""
echo "🛠️  Quick commands to get started:"
echo "  # Check cluster status"
echo "  $DOCKER_COMPOSE exec hadoop ./check-status.sh"
echo ""
echo "  # Run test jobs"
echo "  $DOCKER_COMPOSE exec hadoop ./test-hadoop.sh"
echo ""
echo "  # Access Hadoop shell"
echo "  $DOCKER_COMPOSE exec hadoop bash"
echo ""
echo "  # View logs"
echo "  $DOCKER_COMPOSE logs -f hadoop"
echo ""
echo "  # Stop cluster"
echo "  $DOCKER_COMPOSE down"
echo ""
echo "📁 Data is persisted in './data/' directory"
echo "💼 Your workspace is available in './workspace/' directory"
echo ""

# Check if services are responding
echo "🔍 Quick health check..."
sleep 10

if curl -s http://localhost:9870 > /dev/null; then
    echo "✅ HDFS NameNode is responding"
else
    echo "⚠️  HDFS NameNode may still be starting up"
fi

if curl -s http://localhost:8088 > /dev/null; then
    echo "✅ YARN ResourceManager is responding"
else
    echo "⚠️  YARN ResourceManager may still be starting up"
fi

echo ""
echo "🚀 Setup complete! Your Hadoop cluster is ready for use."
echo "   Run '$DOCKER_COMPOSE logs -f hadoop' to monitor startup progress."
