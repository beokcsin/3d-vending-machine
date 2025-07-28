# 3D Printing Vending Machine - Commercial Deployment Script
# Copyright © 2024 [Your Company Name]. All Rights Reserved.

param(
    [switch]$SkipInfrastructure,
    [switch]$SkipBackend,
    [switch]$SkipFrontend,
    [switch]$SkipEdge,
    [string]$Environment = "production",
    [string]$CompanyName = "[Your Company Name]"
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "🏢 $CompanyName - 3D Printing Vending Machine Platform" -ForegroundColor Cyan
Write-Host "🚀 Starting Commercial Deployment..." -ForegroundColor Green
Write-Host ""

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

function Write-Business {
    param([string]$Message)
    Write-Host "[BUSINESS] $Message" -ForegroundColor Magenta
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
    
    Write-Business "Deploying AWS infrastructure for $CompanyName..."
    
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
    
    Write-Business "Infrastructure deployment completed for $CompanyName!"
}

# Build and deploy backend
function Deploy-Backend {
    if ($SkipBackend) {
        Write-Warning "Skipping backend deployment"
        return
    }
    
    Write-Business "Building and deploying backend for $CompanyName..."
    
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
    
    Write-Business "Backend deployment completed for $CompanyName!"
}

# Setup frontend
function Setup-Frontend {
    if ($SkipFrontend) {
        Write-Warning "Skipping frontend setup"
        return
    }
    
    Write-Business "Setting up frontend for $CompanyName..."
    
    Push-Location frontend
    
    # Install dependencies
    Write-Status "Installing frontend dependencies..."
    npm install
    
    # Create .env.local file with company branding
    Write-Status "Creating environment configuration..."
    @"
NEXT_PUBLIC_API_URL=http://localhost:5000
NEXT_PUBLIC_COMPANY_NAME=$CompanyName
NEXT_PUBLIC_ENVIRONMENT=$Environment
"@ | Out-File -FilePath .env.local -Encoding UTF8
    
    Pop-Location
    
    Write-Business "Frontend setup completed for $CompanyName!"
}

# Setup edge device
function Setup-Edge {
    if ($SkipEdge) {
        Write-Warning "Skipping edge device setup"
        return
    }
    
    Write-Business "Setting up edge device configuration for $CompanyName..."
    
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
COMPANY_NAME=$CompanyName
ENVIRONMENT=$Environment
AWS_IOT_CERT_PATH=/path/to/certificate.pem.crt
AWS_IOT_KEY_PATH=/path/to/private.pem.key
AWS_IOT_CA_PATH=/path/to/AmazonRootCA1.pem
"@ | Out-File -FilePath .env -Encoding UTF8
    
    Pop-Location
    
    Write-Business "Edge device setup completed for $CompanyName!"
}

# Business validation
function Test-BusinessRequirements {
    Write-Business "Validating business requirements..."
    
    # Check if company name is set
    if ($CompanyName -eq "[Your Company Name]") {
        Write-Warning "Please update the company name in the deployment script"
    }
    
    # Check environment
    if ($Environment -notin @("development", "staging", "production")) {
        Write-Error "Environment must be development, staging, or production"
        exit 1
    }
    
    Write-Business "Business requirements validated!"
}

# Main deployment function
function Start-CommercialDeployment {
    Write-Business "Starting commercial deployment for $CompanyName..."
    
    # Validate business requirements
    Test-BusinessRequirements
    
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
    
    Write-Host ""
    Write-Host "🎉 Commercial deployment completed successfully for $CompanyName!" -ForegroundColor Green
    Write-Host ""
    Write-Business "Next steps:"
    Write-Business "1. Configure IoT Core certificates for edge device"
    Write-Business "2. Update frontend API URL in .env.local"
    Write-Business "3. Set up payment processing integration"
    Write-Business "4. Configure customer analytics and reporting"
    Write-Business "5. Set up monitoring and alerting"
    Write-Business "6. Launch marketing and customer acquisition campaigns"
    Write-Host ""
    Write-Business "For business support, contact: [your-email@company.com]"
    Write-Host ""
    Write-Host "Copyright © 2024 $CompanyName. All Rights Reserved." -ForegroundColor Cyan
}

# Run main function
Start-CommercialDeployment 