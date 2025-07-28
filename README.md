# 3D Printing Vending Machine - Commercial Platform

A proprietary cloud-based 3D printing vending machine system that enables automated 3D printing services for commercial deployment.

This project implements a complete 3D printing vending machine system with the following components:

### Cloud Infrastructure (AWS)
- **Frontend**: React/Next.js web application with Material-UI
- **Backend**: ASP.NET Core API running on ECS Fargate
- **Database**: PostgreSQL on RDS for data persistence
- **File Storage**: S3 for 3D model files
- **Real-time Communication**: AWS IoT Core (MQTT) for printer communication
- **Notifications**: SNS/SES for email/SMS + WebSocket push notifications
- **Infrastructure**: AWS CDK for infrastructure as code

### Edge Device
- **Hardware**: Raspberry Pi or mini PC
- **Software**: Python client for AWS IoT Core communication
- **Functionality**: Downloads files from S3, manages printer operations, reports status

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured with appropriate permissions
- .NET 8.0 SDK
- Node.js 18+
- Python 3.8+
- Docker

### 1. Deploy Infrastructure

```bash
# Navigate to infrastructure directory
cd infra

# Install dependencies
npm install

# Deploy the infrastructure
npm run cdk deploy
```

This will create:
- VPC with public/private subnets
- RDS PostgreSQL database
- S3 bucket for file storage
- ECS cluster with Fargate
- API Gateway (REST + WebSocket)
- IoT Core setup
- SNS topics for notifications

### 2. Build and Deploy Backend

```bash
# Navigate to backend directory
cd backend

# Build the Docker image
docker build -t vending-machine-api .

# Push to ECR (replace with your ECR repository)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.us-east-1.amazonaws.com
docker tag vending-machine-api:latest <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/vending-machine-api:latest
docker push <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/vending-machine-api:latest
```

### 3. Setup Frontend

```bash
# Navigate to frontend directory
cd frontend

# Install dependencies
npm install

# Set environment variables
export NEXT_PUBLIC_API_URL=<your-api-gateway-url>

# Run development server
npm run dev
```

### 4. Setup Edge Device

```bash
# Navigate to edge directory
cd edge

# Install Python dependencies
pip install -r requirements.txt

# Set environment variables
export PRINTER_ID=printer-001
export AWS_REGION=us-east-1
export AWS_IOT_CERT_PATH=/path/to/certificate.pem.crt
export AWS_IOT_KEY_PATH=/path/to/private.pem.key
export AWS_IOT_CA_PATH=/path/to/AmazonRootCA1.pem

# Run the edge client
python printer_client.py
```

## 📁 Project Structure

```
3d-vending-machine/
├── architecture-mermaid          # Architecture diagram
├── backend/                      # ASP.NET Core API
│   ├── Dockerfile
│   ├── VendingMachine.Api/      # Main API project
│   ├── VendingMachine.Core/     # Domain models
│   └── VendingMachine.Infrastructure/ # Data access
├── frontend/                     # React/Next.js frontend
│   ├── app/
│   ├── package.json
│   └── next.config.js
├── edge/                         # Edge device software
│   ├── printer_client.py
│   └── requirements.txt
└── infra/                       # AWS CDK infrastructure
    ├── lib/
    ├── package.json
    └── cdk.json
```

## 💼 Business Features

### Frontend
- Modern React/Next.js UI with Material-UI
- Drag & drop file upload for 3D models
- Real-time status updates via WebSocket
- Price and time estimation
- Email notifications
- Payment integration ready

### Backend API
- RESTful API for print job management
- WebSocket support for real-time updates
- PostgreSQL database with Entity Framework
- AWS S3 integration for file storage
- SNS integration for notifications
- Business logic for pricing and operations

### Edge Device
- Python client for AWS IoT Core
- Automatic file download from S3
- Printer status monitoring
- MQTT communication with cloud
- Support for multiple printer types
- Remote management capabilities

### Infrastructure
- Infrastructure as Code with AWS CDK
- Scalable ECS Fargate deployment
- Secure VPC with private subnets
- RDS PostgreSQL for data persistence
- S3 for file storage
- IoT Core for device communication

## 🔒 Security & Compliance

1. **Local Development**:
   - Backend: `dotnet run` in `backend/VendingMachine.Api`
   - Frontend: `npm run dev` in `frontend`
   - Database: Use local PostgreSQL or Docker

2. **Testing**:
   - Backend: `dotnet test`
   - Frontend: `npm test`
   - Infrastructure: `npm test` in `infra`

3. **Deployment**:
   - Infrastructure: `npm run cdk deploy`
   - Backend: Build and push Docker image
   - Frontend: Deploy to Vercel/Netlify


**This is proprietary software. Unauthorized use, copying, or distribution is prohibited.**
