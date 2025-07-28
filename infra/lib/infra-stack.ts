import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as iot from 'aws-cdk-lib/aws-iot';

export class InfraStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Print job bucket
    const bucket = new s3.Bucket(this, 'PrintJobBucket', {
      versioned: true,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
    });

    // IoT Policy for devices
    new iot.CfnPolicy(this, 'EdgeDevicePolicy', {
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
              `arn:aws:iot:${this.region}:${this.account}:topic/test/3dprinter/*`
            ],
          }
        ],
      },
    });
  }
}
