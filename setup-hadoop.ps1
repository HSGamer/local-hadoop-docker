# setup-hadoop.ps1 - Initialize Hadoop cluster directories and start services

# Set error action preference to stop on any error
$ErrorActionPreference = "Stop"

Write-Host "Setting up Hadoop cluster directories..." -ForegroundColor Green

# Create data directories
$directories = @(
    "data\namenode",
    "data\datanode", 
    "data\logs",
    "data\tmp",
    "data\spark-logs",
    "data\spark-events",
    "data\hive\warehouse",
    "data\hive\metastore",
    "workspace"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

Write-Host "Directory structure created:" -ForegroundColor Yellow
Write-Host "📁 data/"
Write-Host "  ├── 📁 namenode/          (HDFS NameNode data)"
Write-Host "  ├── 📁 datanode/          (HDFS DataNode data)"
Write-Host "  ├── 📁 logs/              (Hadoop service logs)"
Write-Host "  ├── 📁 tmp/               (Temporary files)"
Write-Host "  ├── 📁 spark-logs/        (Spark application logs)"
Write-Host "  ├── 📁 spark-events/      (Spark event logs)"
Write-Host "  └── 📁 hive/"
Write-Host "      ├── 📁 warehouse/     (Hive data warehouse)"
Write-Host "      └── 📁 metastore/     (Hive metadata)"
Write-Host "📁 workspace/              (Development workspace)"
Write-Host ""

# Check if Docker Compose is available
$dockerComposeCmd = $null

if (Get-Command "docker" -ErrorAction SilentlyContinue) {
    # Try docker compose (newer syntax)
    try {
        $null = docker compose version 2>$null
        $dockerComposeCmd = "docker compose"
    }
    catch {
        # Try docker-compose (legacy)
        if (Get-Command "docker-compose" -ErrorAction SilentlyContinue) {
            $dockerComposeCmd = "docker-compose"
        }
    }
}

if (-not $dockerComposeCmd) {
    Write-Host "❌ Docker Compose not found. Please install Docker Compose." -ForegroundColor Red
    exit 1
}

Write-Host "🐳 Starting Hadoop cluster..." -ForegroundColor Cyan
Write-Host "This may take several minutes on first run..." -ForegroundColor Yellow
Write-Host ""

# Start the services
try {
    if ($dockerComposeCmd -eq "docker compose") {
        docker compose up -d --build
    } else {
        docker-compose up -d --build
    }
}
catch {
    Write-Host "❌ Failed to start Docker services: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "⏳ Waiting for services to initialize (this may take 2-3 minutes)..." -ForegroundColor Yellow
Start-Sleep -Seconds 120

Write-Host ""
Write-Host "🎉 Hadoop cluster should be ready!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Web UIs available:" -ForegroundColor Cyan
Write-Host "  🗄️  HDFS NameNode:        http://localhost:9870"
Write-Host "  🧵  YARN ResourceManager: http://localhost:8088" 
Write-Host "  ⚡  Spark History Server: http://localhost:18080"
Write-Host "  📈  MapReduce JobHistory:  http://localhost:19888"
Write-Host "  🐝  HiveServer2 Web UI:    http://localhost:10002"
Write-Host ""
Write-Host "🔌 SSH Access:" -ForegroundColor Cyan
Write-Host "  ssh hadoop@localhost -p 2222"
Write-Host "  Password: hadoop"
Write-Host ""
Write-Host "🛠️  Quick commands to get started:" -ForegroundColor Cyan
Write-Host "  # Check cluster status"
Write-Host "  $dockerComposeCmd exec hadoop ./check-status.sh"
Write-Host ""
Write-Host "  # Run test jobs"
Write-Host "  $dockerComposeCmd exec hadoop ./test-hadoop.sh"
Write-Host ""
Write-Host "  # Access Hadoop shell"
Write-Host "  $dockerComposeCmd exec hadoop bash"
Write-Host ""
Write-Host "  # View logs"
Write-Host "  $dockerComposeCmd logs -f hadoop"
Write-Host ""
Write-Host "  # Stop cluster"
Write-Host "  $dockerComposeCmd down"
Write-Host ""
Write-Host "📁 Data is persisted in '.\data\' directory" -ForegroundColor Yellow
Write-Host "💼 Your workspace is available in '.\workspace\' directory" -ForegroundColor Yellow
Write-Host ""

# Check if services are responding
Write-Host "🔍 Quick health check..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

# Function to test HTTP endpoint
function Test-HttpEndpoint {
    param([string]$Url, [string]$ServiceName)
    
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ $ServiceName is responding" -ForegroundColor Green
        } else {
            Write-Host "⚠️  $ServiceName may still be starting up" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "⚠️  $ServiceName may still be starting up" -ForegroundColor Yellow
    }
}

Test-HttpEndpoint -Url "http://localhost:9870" -ServiceName "HDFS NameNode"
Test-HttpEndpoint -Url "http://localhost:8088" -ServiceName "YARN ResourceManager"

Write-Host ""
Write-Host "🚀 Setup complete! Your Hadoop cluster is ready for use." -ForegroundColor Green
Write-Host "   Run '$dockerComposeCmd logs -f hadoop' to monitor startup progress." -ForegroundColor Cyan