#!/usr/bin/env python3
"""
3D Printer Edge Client
Runs on Raspberry Pi or mini PC to manage 3D printer operations
"""

import json
import time
import logging
import os
import subprocess
from typing import Dict, Any
import boto3
from botocore.exceptions import ClientError
import paho.mqtt.client as mqtt
from dataclasses import dataclass
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@dataclass
class PrinterStatus:
    """Represents the current status of a 3D printer"""
    printer_id: str
    status: str  # 'online', 'offline', 'printing', 'paused', 'error'
    temperature: float = 0.0
    material_level: float = 0.0
    current_material: str = ""
    error_message: str = ""
    last_seen: datetime = None

class PrinterEdgeClient:
    def __init__(self, printer_id: str, aws_region: str = "us-east-1"):
        self.printer_id = printer_id
        self.aws_region = aws_region
        self.status = PrinterStatus(printer_id=printer_id, status="offline")
        self.current_job = None
        
        # AWS IoT Core client
        self.iot_client = boto3.client('iot', region_name=aws_region)
        
        # S3 client for downloading files
        self.s3_client = boto3.client('s3', region_name=aws_region)
        
        # MQTT client for IoT Core communication
        self.mqtt_client = mqtt.Client()
        self.mqtt_client.on_connect = self.on_mqtt_connect
        self.mqtt_client.on_message = self.on_mqtt_message
        self.mqtt_client.on_disconnect = self.on_mqtt_disconnect
        
        # Get IoT endpoint
        try:
            response = self.iot_client.describe_endpoint(endpointType='iot:Data-ATS')
            self.iot_endpoint = response['endpointAddress']
        except ClientError as e:
            logger.error(f"Failed to get IoT endpoint: {e}")
            raise
        
        logger.info(f"Initialized printer client for printer {printer_id}")
    
    def on_mqtt_connect(self, client, userdata, flags, rc):
        """Called when MQTT client connects"""
        logger.info(f"Connected to AWS IoT Core with result code {rc}")
        
        # Subscribe to printer-specific topics
        topics = [
            f"3dprinter/{self.printer_id}/jobs",
            f"3dprinter/{self.printer_id}/commands",
            f"3dprinter/{self.printer_id}/config"
        ]
        
        for topic in topics:
            client.subscribe(topic)
            logger.info(f"Subscribed to {topic}")
    
    def on_mqtt_message(self, client, userdata, msg):
        """Called when MQTT message is received"""
        try:
            payload = json.loads(msg.payload.decode())
            logger.info(f"Received message on {msg.topic}: {payload}")
            
            if "jobs" in msg.topic:
                self.handle_job_message(payload)
            elif "commands" in msg.topic:
                self.handle_command_message(payload)
            elif "config" in msg.topic:
                self.handle_config_message(payload)
                
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse MQTT message: {e}")
        except Exception as e:
            logger.error(f"Error handling MQTT message: {e}")
    
    def on_mqtt_disconnect(self, client, userdata, rc):
        """Called when MQTT client disconnects"""
        logger.warning(f"Disconnected from AWS IoT Core with result code {rc}")
    
    def handle_job_message(self, payload: Dict[str, Any]):
        """Handle print job messages"""
        job_type = payload.get('type')
        
        if job_type == 'start':
            self.start_print_job(payload)
        elif job_type == 'pause':
            self.pause_print_job()
        elif job_type == 'resume':
            self.resume_print_job()
        elif job_type == 'cancel':
            self.cancel_print_job()
    
    def handle_command_message(self, payload: Dict[str, Any]):
        """Handle printer commands"""
        command = payload.get('command')
        
        if command == 'status':
            self.publish_status()
        elif command == 'home':
            self.home_printer()
        elif command == 'set_temperature':
            temperature = payload.get('temperature', 200)
            self.set_temperature(temperature)
    
    def handle_config_message(self, payload: Dict[str, Any]):
        """Handle configuration updates"""
        logger.info(f"Received config update: {payload}")
        # Update printer configuration
        if 'material' in payload:
            self.status.current_material = payload['material']
    
    def start_print_job(self, job_data: Dict[str, Any]):
        """Start a new print job"""
        try:
            job_id = job_data['job_id']
            file_url = job_data['file_url']
            material = job_data.get('material', 'PLA')
            
            logger.info(f"Starting print job {job_id} with file {file_url}")
            
            # Download file from S3
            local_file = self.download_file_from_s3(file_url)
            
            if local_file:
                # Update status
                self.status.status = "printing"
                self.current_job = {
                    'job_id': job_id,
                    'file_path': local_file,
                    'material': material,
                    'start_time': datetime.now()
                }
                
                # Start the print (this would integrate with your printer's API)
                self.start_print(local_file, material)
                
                # Publish status update
                self.publish_job_status(job_id, "printing", 0)
            else:
                logger.error(f"Failed to download file for job {job_id}")
                self.publish_job_status(job_id, "failed", 0, "Failed to download file")
                
        except Exception as e:
            logger.error(f"Error starting print job: {e}")
            self.publish_job_status(job_id, "failed", 0, str(e))
    
    def download_file_from_s3(self, file_url: str) -> str:
        """Download file from S3 to local storage"""
        try:
            # Parse S3 URL (s3://bucket/key)
            if file_url.startswith('s3://'):
                parts = file_url[5:].split('/', 1)
                bucket = parts[0]
                key = parts[1]
            else:
                # Assume it's a direct S3 URL
                parts = file_url.split('/')
                bucket = parts[2]
                key = '/'.join(parts[3:])
            
            # Create local directory
            os.makedirs('/tmp/prints', exist_ok=True)
            
            # Download file
            local_file = f"/tmp/prints/{os.path.basename(key)}"
            self.s3_client.download_file(bucket, key, local_file)
            
            logger.info(f"Downloaded file to {local_file}")
            return local_file
            
        except Exception as e:
            logger.error(f"Failed to download file from S3: {e}")
            return None
    
    def start_print(self, file_path: str, material: str):
        """Start the actual print process"""
        # This would integrate with your specific 3D printer's API
        # For example, using OctoPrint, Repetier, or direct G-code
        
        logger.info(f"Starting print of {file_path} with {material}")
        
        # Example: Send to OctoPrint API
        # self.send_to_octoprint(file_path, material)
        
        # For now, just simulate the print process
        self.simulate_print_process(file_path, material)
    
    def simulate_print_process(self, file_path: str, material: str):
        """Simulate the print process for testing"""
        logger.info("Simulating print process...")
        
        # In a real implementation, this would:
        # 1. Send G-code to the printer
        # 2. Monitor temperature and progress
        # 3. Update status periodically
        # 4. Handle errors and completion
        
        # For simulation, we'll just update progress every 10 seconds
        import threading
        
        def progress_updater():
            progress = 0
            while progress < 100 and self.current_job:
                time.sleep(10)
                progress += 10
                self.publish_job_status(
                    self.current_job['job_id'], 
                    "printing", 
                    progress
                )
                
                if progress >= 100:
                    self.complete_print_job()
                    break
        
        threading.Thread(target=progress_updater, daemon=True).start()
    
    def complete_print_job(self):
        """Complete the current print job"""
        if self.current_job:
            logger.info(f"Completing print job {self.current_job['job_id']}")
            
            self.status.status = "online"
            self.current_job = None
            
            # Publish completion status
            self.publish_job_status(
                self.current_job['job_id'], 
                "completed", 
                100
            )
    
    def publish_status(self):
        """Publish current printer status"""
        status_message = {
            'printer_id': self.printer_id,
            'status': self.status.status,
            'temperature': self.status.temperature,
            'material_level': self.status.material_level,
            'current_material': self.status.current_material,
            'error_message': self.status.error_message,
            'last_seen': datetime.now().isoformat(),
            'timestamp': datetime.now().isoformat()
        }
        
        topic = f"3dprinter/{self.printer_id}/status"
        self.mqtt_client.publish(topic, json.dumps(status_message))
        logger.info(f"Published status: {status_message}")
    
    def publish_job_status(self, job_id: str, status: str, progress: int, error: str = None):
        """Publish job status update"""
        status_message = {
            'job_id': job_id,
            'printer_id': self.printer_id,
            'status': status,
            'progress': progress,
            'error': error,
            'timestamp': datetime.now().isoformat()
        }
        
        topic = f"3dprinter/{self.printer_id}/job_status"
        self.mqtt_client.publish(topic, json.dumps(status_message))
        logger.info(f"Published job status: {status_message}")
    
    def connect(self):
        """Connect to AWS IoT Core"""
        try:
            # Load certificates (you'll need to set these up)
            cert_path = os.getenv('AWS_IOT_CERT_PATH', '/path/to/certificate.pem.crt')
            key_path = os.getenv('AWS_IOT_KEY_PATH', '/path/to/private.pem.key')
            ca_path = os.getenv('AWS_IOT_CA_PATH', '/path/to/AmazonRootCA1.pem')
            
            if not all(os.path.exists(p) for p in [cert_path, key_path, ca_path]):
                logger.warning("Certificate files not found, using simulated mode")
                return self.connect_simulated()
            
            self.mqtt_client.tls_set(
                ca_certs=ca_path,
                certfile=cert_path,
                keyfile=key_path,
                cert_reqs=mqtt.ssl.CERT_REQUIRED,
                tls_version=mqtt.ssl.PROTOCOL_TLSv1_2,
                ciphers=None
            )
            
            # Connect to IoT Core
            self.mqtt_client.connect(self.iot_endpoint, 8883, 60)
            self.mqtt_client.loop_start()
            
            # Update status
            self.status.status = "online"
            self.status.last_seen = datetime.now()
            
            logger.info("Connected to AWS IoT Core")
            
        except Exception as e:
            logger.error(f"Failed to connect to AWS IoT Core: {e}")
            raise
    
    def connect_simulated(self):
        """Connect in simulated mode for testing"""
        logger.info("Running in simulated mode")
        self.status.status = "online"
        self.status.last_seen = datetime.now()
        
        # Simulate periodic status updates
        import threading
        
        def status_updater():
            while True:
                time.sleep(30)
                self.publish_status()
        
        threading.Thread(target=status_updater, daemon=True).start()
    
    def run(self):
        """Main run loop"""
        try:
            self.connect()
            
            # Main loop
            while True:
                time.sleep(1)
                
        except KeyboardInterrupt:
            logger.info("Shutting down...")
        except Exception as e:
            logger.error(f"Error in main loop: {e}")
        finally:
            self.cleanup()
    
    def cleanup(self):
        """Cleanup resources"""
        if self.mqtt_client:
            self.mqtt_client.loop_stop()
            self.mqtt_client.disconnect()
        
        logger.info("Cleanup completed")

def main():
    """Main entry point"""
    printer_id = os.getenv('PRINTER_ID', 'printer-001')
    aws_region = os.getenv('AWS_REGION', 'us-east-1')
    
    client = PrinterEdgeClient(printer_id, aws_region)
    client.run()

if __name__ == "__main__":
    main() 