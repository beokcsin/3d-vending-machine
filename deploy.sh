#!/bin/bash

# 3D Vending Machine Deployment Script
# This script helps deploy the complete infrastructure and applications

set -e

echo "🚀 Starting 3D Vending Machine Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if AWS is configured
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed. Please install it first."
        exit 1
    fi
    
    # Check .NET
    if ! command -v dotnet &> /dev/null; then
        print_error ".NET SDK is not installed. Please install it first."
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install it first."
        exit 1
    fi
    
    print_status "All prerequisites are satisfied!"
}

# Deploy infrastructure
deploy_infrastructure() {
    print_status "Deploying AWS infrastructure..."
    
    cd infra
    
    # Install dependencies
    print_status "Installing CDK dependencies..."
    npm install
    
    # Bootstrap CDK (if needed)
    print_status "Bootstrapping CDK..."
    npx cdk bootstrap
    
    # Deploy infrastructure
    print_status "Deploying infrastructure stack..."
    npx cdk deploy --require-approval never
    
    # Get outputs
    print_status "Getting infrastructure outputs..."
    npx cdk deploy --outputs-file outputs.json
    
    cd ..
    
    print_status "Infrastructure deployment completed!"
}

# Build and deploy backend
deploy_backend() {
    print_status "Building and deploying backend..."
    
    cd backend
    
    # Build the application
    print_status "Building ASP.NET Core application..."
    dotnet build
    
    # Build Docker image
    print_status "Building Docker image..."
    docker build -t vending-machine-api .
    
    # Get AWS account ID
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    REGION=$(aws configure get region)
    ECR_REPO="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/vending-machine-api"
    
    # Create ECR repository if it doesn't exist
    print_status "Creating ECR repository..."
    aws ecr create-repository --repository-name vending-machine-api --region $REGION || true
    
    # Login to ECR
    print_status "Logging in to ECR..."
    aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REPO
    
    # Tag and push image
    print_status "Pushing Docker image to ECR..."
    docker tag vending-machine-api:latest $ECR_REPO:latest
    docker push $ECR_REPO:latest
    
    cd ..
    
    print_status "Backend deployment completed!"
}

# Setup frontend
setup_frontend() {
    print_status "Setting up frontend..."
    
    cd frontend
    
    # Install dependencies
    print_status "Installing frontend dependencies..."
    npm install
    
    # Create .env.local file
    print_status "Creating environment configuration..."
    cat > .env.local << EOF
NEXT_PUBLIC_API_URL=http://localhost:5000
EOF
    
    cd ..
    
    print_status "Frontend setup completed!"
}

# Setup edge device
setup_edge() {
    print_status "Setting up edge device configuration..."
    
    cd edge
    
    # Create virtual environment
    print_status "Creating Python virtual environment..."
    python -m venv venv
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Install dependencies
    print_status "Installing Python dependencies..."
    pip install -r requirements.txt
    
    # Create .env file
    print_status "Creating edge device configuration..."
    cat > .env << EOF
PRINTER_ID=printer-001
AWS_REGION=$(aws configure get region)
AWS_IOT_CERT_PATH=/path/to/certificate.pem.crt
AWS_IOT_KEY_PATH=/path/to/private.pem.key
AWS_IOT_CA_PATH=/path/to/AmazonRootCA1.pem
EOF
    
    cd ..
    
    print_status "Edge device setup completed!"
}

# Main deployment function
main() {
    print_status "Starting 3D Vending Machine deployment..."
    
    # Check prerequisites
    check_prerequisites
    
    # Deploy infrastructure
    deploy_infrastructure
    
    # Deploy backend
    deploy_backend
    
    # Setup frontend
    setup_frontend
    
    # Setup edge device
    setup_edge
    
    print_status "🎉 Deployment completed successfully!"
    print_status ""
    print_status "Next steps:"
    print_status "1. Configure IoT Core certificates for edge device"
    print_status "2. Update frontend API URL in .env.local"
    print_status "3. Start the frontend: cd frontend && npm run dev"
    print_status "4. Start the edge device: cd edge && python printer_client.py"
    print_status ""
    print_status "For more information, see the README.md file."
}

# Run main function
main "$@" 