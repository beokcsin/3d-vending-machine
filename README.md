# 3D Printing Vending Machine

A cloud-based 3D printing vending machine system that allows users to upload 3D models and have them printed automatically.

## Architecture Overview

This project implements a complete 3D printing vending machine system with the following components:

### Cloud Infrastructure (AWS)
- **Frontend**: React/Next.js web application with Material-UI
- **Backend**: ASP.NET Core API running on ECS Fargate
- **Database**: PostgreSQL on RDS
- **File Storage**: S3 for 3D model files
- **Real-time Communication**: AWS IoT Core (MQTT) for printer communication
- **Notifications**: SNS/SES for email/SMS + WebSocket push notifications
- **Infrastructure**: AWS CDK for infrastructure as code

### Edge Device
- **Hardware**: Raspberry Pi or mini PC
- **Software**: Python client for AWS IoT Core communication
- **Functionality**: Downloads files from S3, manages printer operations, reports status

## Quick Start

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

## Project Structure

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

## Key Features

### Frontend
- Modern React/Next.js UI with Material-UI
- Drag & drop file upload for 3D models
- Real-time status updates via WebSocket
- Price and time estimation
- Email notifications

### Backend API
- RESTful API for print job management
- WebSocket support for real-time updates
- PostgreSQL database with Entity Framework
- AWS S3 integration for file storage
- SNS integration for notifications

### Edge Device
- Python client for AWS IoT Core
- Automatic file download from S3
- Printer status monitoring
- MQTT communication with cloud
- Support for multiple printer types

### Infrastructure
- Infrastructure as Code with AWS CDK
- Scalable ECS Fargate deployment
- Secure VPC with private subnets
- RDS PostgreSQL for data persistence
- S3 for file storage
- IoT Core for device communication

## Development Workflow

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

## Security Considerations

- All communication uses HTTPS/TLS
- AWS IAM roles for service permissions
- VPC with private subnets for database
- IoT Core certificates for device authentication
- CORS properly configured
- Input validation and sanitization

## Monitoring and Logging

- CloudWatch logs for all services
- X-Ray for distributed tracing
- CloudWatch metrics for performance
- SNS notifications for alerts

## Cost Optimization

- RDS instance sizing based on usage
- S3 lifecycle policies for file management
- ECS Fargate for serverless containers
- CloudWatch alarms for cost monitoring

## Next Steps

1. **Authentication**: Add AWS Cognito for user management
2. **Payment**: Integrate Stripe/PayPal for payments
3. **Printer Integration**: Add support for specific printer APIs (OctoPrint, etc.)
4. **Mobile App**: Create React Native mobile app
5. **Analytics**: Add usage analytics and reporting
6. **Multi-region**: Deploy to multiple AWS regions
7. **Auto-scaling**: Implement auto-scaling based on demand

## Troubleshooting

### Common Issues

1. **CDK Deployment Fails**:
   - Ensure AWS CLI is configured
   - Check IAM permissions
   - Verify region settings

2. **Database Connection Issues**:
   - Check security group rules
   - Verify connection string
   - Ensure database is running

3. **IoT Core Connection Issues**:
   - Verify certificates are valid
   - Check IoT policy permissions
   - Ensure correct endpoint

4. **Frontend API Calls Fail**:
   - Check CORS configuration
   - Verify API Gateway URL
   - Check network connectivity

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
