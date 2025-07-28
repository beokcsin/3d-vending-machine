# 3D Vending Machine Deployment Script (PowerShell)
# This script helps deploy the complete infrastructure and applications

param(
    [switch]$SkipInfrastructure,
    [switch]$SkipBackend,
    [switch]$SkipFrontend,
    [switch]$SkipEdge
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting 3D Vending Machine Deployment..." -ForegroundColor Green

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check prerequisites
function Test-Prerequisites {
    Write-Status "Checking prerequisites..."
    
    # Check AWS CLI
    try {
        $null = Get-Command aws -ErrorAction Stop
    }
    catch {
        Write-Error "AWS CLI is not installed. Please install it first."
        exit 1
    }
    
    # Check if AWS is configured
    try {
        $null = aws sts get-caller-identity 2>$null
    }
    catch {
        Write-Error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    }
    
    # Check Node.js
    try {
        $null = Get-Command node -ErrorAction Stop
    }
    catch {
        Write-Error "Node.js is not installed. Please install it first."
        exit 1
    }
    
    # Check .NET
    try {
        $null = Get-Command dotnet -ErrorAction Stop
    }
    catch {
        Write-Error ".NET SDK is not installed. Please install it first."
        exit 1
    }
    
    # Check Docker
    try {
        $null = Get-Command docker -ErrorAction Stop
    }
    catch {
        Write-Error "Docker is not installed. Please install it first."
        exit 1
    }
    
    Write-Status "All prerequisites are satisfied!"
}

# Deploy infrastructure
function Deploy-Infrastructure {
    if ($SkipInfrastructure) {
        Write-Warning "Skipping infrastructure deployment"
        return
    }
    
    Write-Status "Deploying AWS infrastructure..."
    
    Push-Location infra
    
    # Install dependencies
    Write-Status "Installing CDK dependencies..."
    npm install
    
    # Bootstrap CDK (if needed)
    Write-Status "Bootstrapping CDK..."
    npx cdk bootstrap
    
    # Deploy infrastructure
    Write-Status "Deploying infrastructure stack..."
    npx cdk deploy --require-approval never
    
    # Get outputs
    Write-Status "Getting infrastructure outputs..."
    npx cdk deploy --outputs-file outputs.json
    
    Pop-Location
    
    Write-Status "Infrastructure deployment completed!"
}

# Build and deploy backend
function Deploy-Backend {
    if ($SkipBackend) {
        Write-Warning "Skipping backend deployment"
        return
    }
    
    Write-Status "Building and deploying backend..."
    
    Push-Location backend
    
    # Build the application
    Write-Status "Building ASP.NET Core application..."
    dotnet build
    
    # Build Docker image
    Write-Status "Building Docker image..."
    docker build -t vending-machine-api .
    
    # Get AWS account ID
    $ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
    $REGION = aws configure get region
    $ECR_REPO = "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/vending-machine-api"
    
    # Create ECR repository if it doesn't exist
    Write-Status "Creating ECR repository..."
    aws ecr create-repository --repository-name vending-machine-api --region $REGION 2>$null
    
    # Login to ECR
    Write-Status "Logging in to ECR..."
    aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REPO
    
    # Tag and push image
    Write-Status "Pushing Docker image to ECR..."
    docker tag vending-machine-api:latest $ECR_REPO:latest
    docker push $ECR_REPO:latest
    
    Pop-Location
    
    Write-Status "Backend deployment completed!"
}

# Setup frontend
function Setup-Frontend {
    if ($SkipFrontend) {
        Write-Warning "Skipping frontend setup"
        return
    }
    
    Write-Status "Setting up frontend..."
    
    Push-Location frontend
    
    # Install dependencies
    Write-Status "Installing frontend dependencies..."
    npm install
    
    # Create .env.local file
    Write-Status "Creating environment configuration..."
    @"
NEXT_PUBLIC_API_URL=http://localhost:5000
"@ | Out-File -FilePath .env.local -Encoding UTF8
    
    Pop-Location
    
    Write-Status "Frontend setup completed!"
}

# Setup edge device
function Setup-Edge {
    if ($SkipEdge) {
        Write-Warning "Skipping edge device setup"
        return
    }
    
    Write-Status "Setting up edge device configuration..."
    
    Push-Location edge
    
    # Create virtual environment
    Write-Status "Creating Python virtual environment..."
    python -m venv venv
    
    # Activate virtual environment
    & .\venv\Scripts\Activate.ps1
    
    # Install dependencies
    Write-Status "Installing Python dependencies..."
    pip install -r requirements.txt
    
    # Create .env file
    Write-Status "Creating edge device configuration..."
    $REGION = aws configure get region
    @"
PRINTER_ID=printer-001
AWS_REGION=$REGION
AWS_IOT_CERT_PATH=/path/to/certificate.pem.crt
AWS_IOT_KEY_PATH=/path/to/private.pem.key
AWS_IOT_CA_PATH=/path/to/AmazonRootCA1.pem
"@ | Out-File -FilePath .env -Encoding UTF8
    
    Pop-Location
    
    Write-Status "Edge device setup completed!"
}

# Main deployment function
function Start-Deployment {
    Write-Status "Starting 3D Vending Machine deployment..."
    
    # Check prerequisites
    Test-Prerequisites
    
    # Deploy infrastructure
    Deploy-Infrastructure
    
    # Deploy backend
    Deploy-Backend
    
    # Setup frontend
    Setup-Frontend
    
    # Setup edge device
    Setup-Edge
    
    Write-Status "🎉 Deployment completed successfully!"
    Write-Host ""
    Write-Status "Next steps:"
    Write-Status "1. Configure IoT Core certificates for edge device"
    Write-Status "2. Update frontend API URL in .env.local"
    Write-Status "3. Start the frontend: cd frontend && npm run dev"
    Write-Status "4. Start the edge device: cd edge && python printer_client.py"
    Write-Host ""
    Write-Status "For more information, see the README.md file."
}

# Run main function
Start-Deployment 