# Quick Start Guide - 3D Printing Vending Machine

This guide will help you get your 3D printing vending machine up and running quickly.

## 🚀 Prerequisites

Before you start, make sure you have:

- [AWS CLI](https://aws.amazon.com/cli/) installed and configured
- [.NET 8.0 SDK](https://dotnet.microsoft.com/download) installed
- [Node.js 18+](https://nodejs.org/) installed
- [Python 3.8+](https://python.org/) installed
- [Docker](https://docker.com/) installed and running

## 📋 Step 1: Clone and Setup

```bash
# Clone the repository (if you haven't already)
git clone <your-repo-url>
cd 3d-vending-machine

# Run the deployment script
./deploy.ps1  # On Windows
# OR
./deploy.sh   # On Linux/Mac
```

## 🏗️ Step 2: Deploy Infrastructure

The deployment script will automatically:

1. **Deploy AWS Infrastructure**:
   - VPC with public/private subnets
   - RDS PostgreSQL database
   - S3 bucket for file storage
   - ECS cluster with Fargate
   - API Gateway (REST + WebSocket)
   - IoT Core setup
   - SNS topics for notifications

2. **Build and Deploy Backend**:
   - Build ASP.NET Core API
   - Create Docker image
   - Push to ECR
   - Deploy to ECS

3. **Setup Frontend**:
   - Install dependencies
   - Create environment configuration

4. **Setup Edge Device**:
   - Create Python virtual environment
   - Install dependencies
   - Create configuration files

## 🔧 Step 3: Configure IoT Core Certificates

For the edge device to communicate with AWS IoT Core, you need to set up certificates:

1. **Create IoT Thing**:
   ```bash
   aws iot create-thing --thing-name printer-001
   ```

2. **Create Certificates**:
   ```bash
   aws iot create-keys-and-certificate --set-as-active --certificate-pem-outfile certificate.pem.crt --public-key-outfile public.pem.key --private-key-outfile private.pem.key
   ```

3. **Attach Policy**:
   ```bash
   aws iot attach-policy --policy-name EdgeDevicePolicy --target <certificate-arn>
   aws iot attach-thing-principal --thing-name printer-001 --principal <certificate-arn>
   ```

4. **Download CA Certificate**:
   ```bash
   curl https://www.amazontrust.com/repository/AmazonRootCA1.pem -o AmazonRootCA1.pem
   ```

5. **Update Edge Configuration**:
   Update the paths in `edge/.env`:
   ```
   AWS_IOT_CERT_PATH=./certificate.pem.crt
   AWS_IOT_KEY_PATH=./private.pem.key
   AWS_IOT_CA_PATH=./AmazonRootCA1.pem
   ```

## 🖥️ Step 4: Start the Applications

### Frontend
```bash
cd frontend
npm run dev
```
Visit `http://localhost:3000` to see the web interface.

### Edge Device
```bash
cd edge
# Activate virtual environment
.\venv\Scripts\Activate.ps1  # Windows
# OR
source venv/bin/activate     # Linux/Mac

# Run the edge client
python printer_client.py
```

## 🧪 Step 5: Test the System

1. **Upload a 3D Model**:
   - Go to the web interface
   - Drag and drop a .stl or .gcode file
   - Fill in the job details
   - Submit the print job

2. **Monitor Progress**:
   - Check the API logs in CloudWatch
   - Monitor the edge device logs
   - Watch for status updates

3. **Test Notifications**:
   - Check your email for job status updates
   - Monitor SNS topics in AWS Console

## 📊 Monitoring

### AWS Console
- **CloudWatch**: View logs and metrics
- **ECS**: Monitor container health
- **RDS**: Check database performance
- **IoT Core**: Monitor device connections
- **S3**: View uploaded files

### Local Monitoring
- **Frontend**: Browser developer tools
- **Backend**: Docker logs
- **Edge Device**: Python console output

## 🔍 Troubleshooting

### Common Issues

1. **CDK Deployment Fails**:
   ```bash
   # Check AWS credentials
   aws sts get-caller-identity
   
   # Bootstrap CDK
   cd infra
   npx cdk bootstrap
   ```

2. **Database Connection Issues**:
   - Check security group rules
   - Verify connection string in environment variables
   - Ensure database is running

3. **IoT Core Connection Issues**:
   - Verify certificates are valid
   - Check IoT policy permissions
   - Ensure correct endpoint

4. **Frontend API Calls Fail**:
   - Check CORS configuration
   - Verify API Gateway URL
   - Check network connectivity

### Debug Commands

```bash
# Check infrastructure status
cd infra
npx cdk diff

# Check backend logs
aws logs describe-log-groups --log-group-name-prefix /ecs/vending-machine

# Test IoT Core connection
aws iot describe-endpoint --endpoint-type iot:Data-ATS

# Check S3 bucket
aws s3 ls s3://your-bucket-name
```

## 🚀 Next Steps

Once the basic system is working, consider:

1. **Authentication**: Add AWS Cognito for user management
2. **Payment**: Integrate Stripe/PayPal for payments
3. **Printer Integration**: Add support for specific printer APIs
4. **Mobile App**: Create React Native mobile app
5. **Analytics**: Add usage analytics and reporting
6. **Auto-scaling**: Implement auto-scaling based on demand

## 📚 Additional Resources

- [AWS CDK Documentation](https://docs.aws.amazon.com/cdk/)
- [ASP.NET Core Documentation](https://docs.microsoft.com/en-us/aspnet/core/)
- [Next.js Documentation](https://nextjs.org/docs)
- [AWS IoT Core Documentation](https://docs.aws.amazon.com/iot/)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)

## 🆘 Getting Help

If you encounter issues:

1. Check the logs in CloudWatch
2. Review the troubleshooting section above
3. Check the main README.md for detailed information
4. Open an issue in the repository

Happy printing! 🖨️ 