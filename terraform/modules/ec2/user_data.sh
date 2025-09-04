#!/bin/bash

# Update system
yum update -y

# Install Python 3 and pip
yum install -y python3 python3-pip git

# Install Java 11 (required for Kafka tools)
yum install -y java-11-amazon-corretto

# 추가 --

# 1. 개발 도구 그룹 설치
sudo yum groupinstall -y "Development Tools"

# 2. 개별적으로 필요한 패키지 설치
sudo yum install -y gcc gcc-c++ make python3-devel librdkafka-devel


# 특정 버전 설치 시도 (더 안정적일 수 있음)
sudo pip3 install confluent-kafka==1.9.2 boto3 certifi

# 추가 --

# Install confluent-kafka and other Python packages

# 특정버전으로 변경
# pip3 install confluent-kafka boto3 certifi

# Create project directory
mkdir -p /home/ec2-user/${project_name}
cd /home/ec2-user/${project_name}

# Create MSK Consumer Python script
cat > msk_consumer.py << 'EOF'
#!/usr/bin/env python3

import boto3
import json
import certifi
from confluent_kafka import Consumer
import time
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def get_msk_credentials():
    """Secrets Manager에서 MSK SCRAM 자격 증명 조회"""
    try:
        secrets_client = boto3.client('secretsmanager', region_name='ap-northeast-2')
        response = secrets_client.get_secret_value(SecretId='${secret_name}')
        secret = json.loads(response['SecretString'])
        return secret['username'], secret['password']
    except Exception as e:
        logger.error(f"시크릿 조회 실패: {e}")
        return None, None

def create_msk_consumer():
    """MSK Consumer 생성 및 SCRAM 인증 설정"""
    username, password = get_msk_credentials()
    
    if not username or not password:
        raise Exception("MSK 자격 증명을 가져올 수 없습니다")
    
    logger.info(f"MSK 자격 증명을 성공적으로 가져왔습니다: {username}")
    
    # Consumer 설정
    config = {
        'bootstrap.servers': '${bootstrap_brokers}',
        'security.protocol': 'SASL_SSL',
        'sasl.mechanism': 'SCRAM-SHA-512',
        'sasl.username': username,
        'sasl.password': password,
        'group.id': f'iot-consumer-group-{int(time.time())}',
        'auto.offset.reset': 'latest',
        'ssl.ca.location': certifi.where(),
        'enable.auto.commit': True,
        'auto.commit.interval.ms': 5000
    }
    
    return Consumer(config)

def main():
    """메인 Consumer 실행 함수"""
    logger.info("🚀 Terraform MSK Consumer 시작...")
    
    try:
        consumer = create_msk_consumer()
        consumer.subscribe(['${topic_name}'])
        
        logger.info("📡 메시지 폴링 시작...")
        
        while True:
            msg = consumer.poll(1.0)
            
            if msg is None:
                continue
            if msg.error():
                logger.error(f"Consumer 오류: {msg.error()}")
                continue
                
            # 메시지 출력
            logger.info("=" * 50)
            logger.info("📨 수신된 메시지:")
            logger.info(f"   토픽: {msg.topic()}")
            logger.info(f"   파티션: {msg.partition()}")
            logger.info(f"   오프셋: {msg.offset()}")
            logger.info(f"   값: {msg.value().decode('utf-8')}")
            logger.info("=" * 50)
            
    except KeyboardInterrupt:
        logger.info("\n🛑 Consumer 중단됨")
    except Exception as e:
        logger.error(f"오류 발생: {e}")
    finally:
        consumer.close()
        logger.info("✅ Consumer 종료 완료")

if __name__ == "__main__":
    main()
EOF

# Make script executable
chmod +x msk_consumer.py

# Change ownership to ec2-user
chown -R ec2-user:ec2-user /home/ec2-user/${project_name}

# Create systemd service for auto-start
cat > /etc/systemd/system/${project_name}-consumer.service << EOF
[Unit]
Description=${project_name} MSK Consumer
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/${project_name}
ExecStart=/usr/bin/python3 /home/ec2-user/${project_name}/msk_consumer.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable ${project_name}-consumer.service

# Log installation completion
echo "✅ Terraform EC2 Consumer 설치 완료!" > /home/ec2-user/installation.log
echo "📁 프로젝트 디렉토리: /home/ec2-user/${project_name}" >> /home/ec2-user/installation.log
echo "🔧 Consumer 스크립트: /home/ec2-user/${project_name}/msk_consumer.py" >> /home/ec2-user/installation.log
echo "⚙️  서비스 이름: ${project_name}-consumer.service" >> /home/ec2-user/installation.log
echo "🚀 시작 명령어: sudo systemctl start ${project_name}-consumer" >> /home/ec2-user/installation.log
