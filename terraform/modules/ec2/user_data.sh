#!/bin/bash

# Update system
yum update -y

# Install Python 3 and pip
yum install -y python3 python3-pip git

# Install Java 11 (required for Kafka tools)
yum install -y java-11-amazon-corretto

# Install Kafka Client Tools
cd /opt
wget https://archive.apache.org/dist/kafka/2.8.1/kafka_2.12-2.8.1.tgz
tar -xzf kafka_2.12-2.8.1.tgz
mv kafka_2.12-2.8.1 kafka
chown -R ec2-user:ec2-user /opt/kafka

# Create Kafka client configuration directory
mkdir -p /opt/kafka/config
chown -R ec2-user:ec2-user /opt/kafka/config

# Create client.properties with SCRAM authentication
cat > /opt/kafka/config/client.properties << 'KAFKA_EOF'
security.protocol=SASL_SSL
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username="${username}" password="${password}";
KAFKA_EOF

# Set proper permissions
chown ec2-user:ec2-user /opt/kafka/config/client.properties
chmod 600 /opt/kafka/config/client.properties

# Create Kafka aliases for easy use
cat >> /home/ec2-user/.bashrc << 'ALIAS_EOF'

# Kafka Tools Aliases
export KAFKA_HOME=/opt/kafka
export PATH=$PATH:$KAFKA_HOME/bin
alias kafka-topics='$KAFKA_HOME/bin/kafka-topics.sh --bootstrap-server ${bootstrap_brokers} --command-config $KAFKA_HOME/config/client.properties'
alias kafka-console-consumer='$KAFKA_HOME/bin/kafka-console-consumer.sh --bootstrap-server ${bootstrap_brokers} --consumer.config $KAFKA_HOME/config/client.properties'
alias kafka-console-producer='$KAFKA_HOME/bin/kafka-console-producer.sh --bootstrap-server ${bootstrap_brokers} --producer.config $KAFKA_HOME/config/client.properties'
ALIAS_EOF

# Source bashrc for current session
source /home/ec2-user/.bashrc

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Start Kafka UI automatically
docker run -d -p 8080:8080 \
    -e DYNAMIC_CONFIG_ENABLED=true \
    --name kafka-ui \
    provectuslabs/kafka-ui:latest

# 추가 -- (ECR / .env / 컨테이너 실행)

# 에러시 중단
set -euo pipefail

# 변수는 Terraform templatefile로 주입됩니다
AWS_REGION="${aws_region}"
ECR_REGISTRY="${ecr_registry}"
ECR_REPO_CONNECTOR="${ecr_repository_connector}"
ECR_REPO_FRONTEND="${ecr_repository_frontend}"
IMAGE_TAG="${image_tag}"
CONNECTOR_IMAGE="$ECR_REGISTRY/$ECR_REPO_CONNECTOR:$IMAGE_TAG"
FRONTEND_IMAGE="$ECR_REGISTRY/$ECR_REPO_FRONTEND:$IMAGE_TAG"

# AWS CLI 설치 (없으면)
if ! command -v aws >/dev/null 2>&1; then
  yum install -y awscli
fi

# ECR 로그인
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"


docker network create --driver=bridge alcha_network



# MongoDB (영속 볼륨 포함)
docker volume create mongo_data || true
docker rm -f mongodb-server || true
docker pull mongo:latest
docker run -d --name mongodb-server \
  --restart unless-stopped \
  --network alcha_network \
  -p 27017:27017 \
  -v mongo_data:/data/db \
  mongo:latest

# 통합 환경파일 작성(~/.env)
cat > /home/ec2-user/.env <<ENV_EOF
# Kafka
KAFKA_BOOTSTRAP_SERVERS=${bootstrap_brokers}
KAFKA_SECURITY_PROTOCOL=SASL_SSL
KAFKA_SASL_MECHANISM=SCRAM-SHA-512
KAFKA_SASL_USERNAME=${username}
KAFKA_SASL_PASSWORD=${password}

# connector
KAFKA_GROUP_ID=vehicle-data-consumer-group
MONGO_URI=mongodb://mongodb:27017/
MONGO_DB_NAME=vehicle_data_db

# consumer
ALCHA_BACKEND_PORT=${alcha_backend_port}
REDIS_HOST=${redis_host}
REDIS_PORT=${redis_port}
ENV_EOF
chown ec2-user:ec2-user /home/ec2-user/.env
chmod 600 /home/ec2-user/.env

# 커넥터 최신 이미지 pull & 실행
docker rm -f alcha-connector || true
docker pull "$CONNECTOR_IMAGE"
docker run -d --name alcha-connector \
  --restart unless-stopped \
  --network alcha_network \
  --env-file /home/ec2-user/.env \
  "$CONNECTOR_IMAGE"

# Start Frontend Server 
docker rm -f alcha-frontend || true
docker pull "$FRONTEND_IMAGE"
docker stop alcha-frontend || true
docker rm alcha-frontend || true
docker run -d --name alcha-frontend -p 5173:3000 "$FRONTEND_IMAGE"

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

# Log installation completion
echo "✅ Terraform EC2 Consumer 설치 완료!" > /home/ec2-user/installation.log
echo "📁 프로젝트 디렉토리: /home/ec2-user/${project_name}" >> /home/ec2-user/installation.log
echo "🔧 Consumer 스크립트: /home/ec2-user/${project_name}/msk_consumer.py" >> /home/ec2-user/installation.log
echo "⚙️  서비스 이름: ${project_name}-consumer.service" >> /home/ec2-user/installation.log
echo "🚀 시작 명령어: sudo systemctl start ${project_name}-consumer" >> /home/ec2-user/installation.log
echo "" >> /home/ec2-user/installation.log
echo "🔧 Kafka Client Tools 설치 완료!" >> /home/ec2-user/installation.log
echo "📂 Kafka 설치 경로: /opt/kafka" >> /home/ec2-user/installation.log
echo "🔑 인증 파일: /opt/kafka/config/client.properties" >> /home/ec2-user/installation.log
echo "" >> /home/ec2-user/installation.log
echo "� Docker 설치 완료!" >> /home/ec2-user/installation.log
echo "📱 Kafka UI 실행 명령어: docker run -d --name kafka-ui -p 8080:8080 provectuslabs/kafka-ui:latest" >> /home/ec2-user/installation.log
echo "🌐 Kafka UI 접속: http://\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080" >> /home/ec2-user/installation.log
echo "" >> /home/ec2-user/installation.log
echo "🔧 MSK 브로커: ${bootstrap_brokers}" >> /home/ec2-user/installation.log
echo "👤 사용자명: ${username}" >> /home/ec2-user/installation.log
echo "🔐 비밀번호: ${password}" >> /home/ec2-user/installation.log
echo "" >> /home/ec2-user/installation.log
echo "�📖 Kafka 명령어 사용법:" >> /home/ec2-user/installation.log
echo "  - 토픽 목록: kafka-topics --list" >> /home/ec2-user/installation.log
echo "  - 토픽 상세: kafka-topics --describe --topic ${topic_name}" >> /home/ec2-user/installation.log
echo "  - 메시지 확인: kafka-console-consumer --topic ${topic_name} --from-beginning" >> /home/ec2-user/installation.log
echo "  - 실시간 모니터링: kafka-console-consumer --topic ${topic_name}" >> /home/ec2-user/installation.log

# Create Kafka usage guide
cat > /home/ec2-user/kafka_guide.txt << 'GUIDE_EOF'
🔧 Kafka Client Tools 사용 가이드

📂 설치 위치: /opt/kafka
🔑 인증 파일: /opt/kafka/config/client.properties

🚀 자주 사용하는 명령어:

1. 토픽 목록 조회:
   kafka-topics --list

2. 특정 토픽 상세 정보:
   kafka-topics --describe --topic iot-sensor-data

3. 토픽의 모든 메시지 확인:
   kafka-console-consumer --topic iot-sensor-data --from-beginning

4. 실시간 메시지 모니터링:
   kafka-console-consumer --topic iot-sensor-data

5. 새로운 토픽 생성:
   kafka-topics --create --topic my-new-topic --partitions 2 --replication-factor 2

6. 토픽 삭제:
   kafka-topics --delete --topic my-topic

💡 팁: 모든 명령어는 이미 MSK 연결 정보와 인증이 설정되어 있습니다.
GUIDE_EOF

chown ec2-user:ec2-user /home/ec2-user/kafka_guide.txt
