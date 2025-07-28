import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as iot from 'aws-cdk-lib/aws-iot';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as apigatewayv2 from 'aws-cdk-lib/aws-apigatewayv2';
import * as apigatewayv2_integrations from 'aws-cdk-lib/aws-apigatewayv2-integrations';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as ecs_patterns from 'aws-cdk-lib/aws-ecs-patterns';

export class InfraStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // VPC for our resources
    const vpc = new ec2.Vpc(this, 'VendingMachineVPC', {
      maxAzs: 2,
      natGateways: 1,
    });

    // Print job bucket
    const bucket = new s3.Bucket(this, 'PrintJobBucket', {
      versioned: true,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
      cors: [
        {
          allowedMethods: [s3.HttpMethods.GET, s3.HttpMethods.PUT, s3.HttpMethods.POST],
          allowedOrigins: ['*'],
          allowedHeaders: ['*'],
        },
      ],
    });

    // RDS PostgreSQL Database
    const dbSecurityGroup = new ec2.SecurityGroup(this, 'DatabaseSecurityGroup', {
      vpc,
      description: 'Security group for RDS PostgreSQL',
      allowAllOutbound: true,
    });

    const database = new rds.DatabaseInstance(this, 'VendingMachineDatabase', {
      engine: rds.DatabaseInstanceEngine.postgres({
        version: rds.PostgresEngineVersion.VER_15_4,
      }),
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.MICRO),
      vpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
      },
      securityGroups: [dbSecurityGroup],
      databaseName: 'vendingmachine',
      credentials: rds.Credentials.fromGeneratedSecret('postgres'),
      backupRetention: cdk.Duration.days(7),
      deletionProtection: false,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // SNS Topic for notifications
    const notificationTopic = new sns.Topic(this, 'VendingMachineNotifications', {
      displayName: '3D Printing Vending Machine Notifications',
    });

    // Lambda for WebSocket fan-out
    const websocketFanoutLambda = new lambda.Function(this, 'WebSocketFanoutLambda', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromInline(`
        exports.handler = async (event) => {
          console.log('WebSocket fan-out lambda triggered:', JSON.stringify(event));
          return { statusCode: 200 };
        };
      `),
      environment: {
        WEBSOCKET_API_ENDPOINT: 'PLACEHOLDER', // Will be updated after API Gateway creation
      },
    });

    // Grant SNS permissions to Lambda
    notificationTopic.grantPublish(websocketFanoutLambda);

    // IoT Policy for devices
    const iotPolicy = new iot.CfnPolicy(this, 'EdgeDevicePolicy', {
      policyName: 'EdgeDevicePolicy',
      policyDocument: {
        Version: '2012-10-17',
        Statement: [
          {
            Effect: 'Allow',
            Action: ['iot:Connect'],
            Resource: '*',
          },
          {
            Effect: 'Allow',
            Action: ['iot:Publish', 'iot:Subscribe', 'iot:Receive'],
            Resource: [
              `arn:aws:iot:${this.region}:${this.account}:topic/3dprinter/*`,
              `arn:aws:iot:${this.region}:${this.account}:topicfilter/3dprinter/*`
            ],
          }
        ],
      },
    });

    // ECS Cluster
    const cluster = new ecs.Cluster(this, 'VendingMachineCluster', {
      vpc,
      containerInsights: true,
    });

    // Task Definition for ASP.NET Core API
    const taskDefinition = new ecs.FargateTaskDefinition(this, 'ApiTaskDefinition', {
      memoryLimitMiB: 512,
      cpu: 256,
    });

    // Grant permissions to task
    bucket.grantReadWrite(taskDefinition.taskRole);
    database.grantConnect(taskDefinition.taskRole);
    notificationTopic.grantPublish(taskDefinition.taskRole);

    // Add container to task definition
    const apiContainer = taskDefinition.addContainer('ApiContainer', {
      image: ecs.ContainerImage.fromAsset('../backend'),
      logging: ecs.LogDrivers.awsLogs({ streamPrefix: 'api' }),
      environment: {
        DATABASE_CONNECTION_STRING: database.instanceEndpoint.socketAddress,
        S3_BUCKET_NAME: bucket.bucketName,
        SNS_TOPIC_ARN: notificationTopic.topicArn,
        AWS_REGION: this.region,
      },
      portMappings: [{ containerPort: 80 }],
    });

    // API Gateway with REST and WebSocket
    const restApi = new apigateway.RestApi(this, 'VendingMachineRestApi', {
      restApiName: '3D Vending Machine API',
      description: 'API for 3D printing vending machine',
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
      },
    });

    // WebSocket API
    const websocketApi = new apigatewayv2.WebSocketApi(this, 'VendingMachineWebSocketApi', {
      connectRouteOptions: { integration: new apigatewayv2_integrations.WebSocketLambdaIntegration('ConnectHandler', new lambda.Function(this, 'ConnectHandler', {
        runtime: lambda.Runtime.NODEJS_18_X,
        handler: 'index.handler',
        code: lambda.Code.fromInline(`
          exports.handler = async (event) => {
            console.log('WebSocket connect:', JSON.stringify(event));
            return { statusCode: 200 };
          };
        `),
      })) },
      disconnectRouteOptions: { integration: new apigatewayv2_integrations.WebSocketLambdaIntegration('DisconnectHandler', new lambda.Function(this, 'DisconnectHandler', {
        runtime: lambda.Runtime.NODEJS_18_X,
        handler: 'index.handler',
        code: lambda.Code.fromInline(`
          exports.handler = async (event) => {
            console.log('WebSocket disconnect:', JSON.stringify(event));
            return { statusCode: 200 };
          };
        `),
      })) },
      defaultRouteOptions: { integration: new apigatewayv2_integrations.WebSocketLambdaIntegration('DefaultHandler', new lambda.Function(this, 'DefaultHandler', {
        runtime: lambda.Runtime.NODEJS_18_X,
        handler: 'index.handler',
        code: lambda.Code.fromInline(`
          exports.handler = async (event) => {
            console.log('WebSocket default route:', JSON.stringify(event));
            return { statusCode: 200 };
          };
        `),
      })) },
    });

    const websocketStage = new apigatewayv2.WebSocketStage(this, 'WebSocketStage', {
      webSocketApi: websocketApi,
      stageName: 'prod',
      autoDeploy: true,
    });

    // Update Lambda environment with WebSocket endpoint
    websocketFanoutLambda.addEnvironment('WEBSOCKET_API_ENDPOINT', websocketStage.url);

    // ECS Service
    const apiService = new ecs.FargateService(this, 'ApiService', {
      cluster,
      taskDefinition,
      desiredCount: 1,
      assignPublicIp: false,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
      },
    });

    // Allow API Gateway to invoke ECS service
    apiService.connections.allowFromAnyIpv4(ec2.Port.tcp(80));

    // Output important values
    new cdk.CfnOutput(this, 'S3BucketName', {
      value: bucket.bucketName,
      description: 'S3 Bucket for 3D print files',
    });

    new cdk.CfnOutput(this, 'DatabaseEndpoint', {
      value: database.instanceEndpoint.hostname,
      description: 'RDS PostgreSQL endpoint',
    });

    new cdk.CfnOutput(this, 'RestApiUrl', {
      value: restApi.url,
      description: 'REST API Gateway URL',
    });

    new cdk.CfnOutput(this, 'WebSocketUrl', {
      value: websocketStage.url,
      description: 'WebSocket API Gateway URL',
    });

    new cdk.CfnOutput(this, 'SnsTopicArn', {
      value: notificationTopic.topicArn,
      description: 'SNS Topic for notifications',
    });
  }
}
