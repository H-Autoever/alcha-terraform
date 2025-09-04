# 🚀 Terraform 배포 가이드

## 📋 **배포 전 준비사항**

### 0. **Terraform 설치 확인**
```powershell
# Terraform 설치 확인
terraform version

# 설치되지 않았다면 Chocolatey로 설치
choco install terraform

# 또는 수동 다운로드: https://developer.hashicorp.com/terraform/downloads
```

### 1. **AWS CLI 설정**
```powershell
aws configure
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region name: ap-northeast-2
# Default output format: json
```

### 2. **EC2 키 페어 생성**
```powershell
# AWS 콘솔에서 EC2 키 페어 생성 또는 CLI로 생성
aws ec2 create-key-pair --key-name psw0904-key --query 'KeyMaterial' --output text > psw0904-key.pem

# 키 페어 권한 설정 (Windows에서는 파일 속성으로 설정)
# psw0904-key.pem 파일 우클릭 → 속성 → 보안 → 고급 → 상속 사용 안 함 → 현재 사용자만 읽기 권한
```

### 3. **terraform.tfvars 파일 수정**
```bash
# 실제 키 페어 이름으로 변경 (이미 psw0904-key로 설정됨)
ec2_key_pair_name = "psw0904-key"

# 보안을 위해 강력한 패스워드로 변경
msk_scram_password = "YourVerySecurePassword123!"

# 사용자명도 psw0904 포함
msk_scram_username = "iotuser-psw0904"

# 프로젝트명에 psw0904 포함 확인
project_name = "iot-msk-pipeline-psw0904"
```

---

## 🛠️ **배포 명령어**

### 1. **Terraform 초기화**
```powershell
cd terraform
terraform init
```

### 2. **배포 계획 확인**
```powershell
terraform plan
```

### 3. **인프라 배포**
```powershell
terraform apply
# "yes" 입력하여 배포 승인
```

### 4. **배포 결과 확인**
```powershell
terraform output
```

---

## 🧪 **배포 후 테스트**

### 1. **EC2 인스턴스 접속**
```powershell
# Terraform output에서 SSH 명령어 확인
terraform output ssh_command

# 예시: ssh -i psw0904-key.pem ec2-user@1.2.3.4
```

### 2. **Consumer 서비스 시작**
```bash
# EC2 인스턴스 내에서 실행
sudo systemctl start iot-msk-pipeline-psw0904-consumer
sudo systemctl status iot-msk-pipeline-psw0904-consumer
```

### 3. **IoT 메시지 테스트**
```bash
# AWS CLI로 IoT 메시지 발송
aws iot-data publish \
  --topic "topic/test" \
  --payload '{"temperature": 25.5, "humidity": 60.2, "timestamp": "2025-09-04T10:30:00Z"}' \
  --region ap-northeast-2
```

### 4. **Consumer 로그 확인**
```bash
# EC2에서 Consumer 로그 확인
sudo journalctl -f -u iot-msk-pipeline-psw0904-consumer
```

---

## 🔧 **문제 해결**

### MSK 클러스터 생성 실패
```bash
# MSK 클러스터는 생성에 20-30분 소요
# 타임아웃 오류 시 다시 apply 실행
terraform apply -auto-approve
```

### EC2 User Data 스크립트 확인
```bash
# EC2 접속 후 설치 로그 확인
cat /home/ec2-user/installation.log
cat /var/log/cloud-init-output.log
```

### Consumer 연결 문제
```bash
# 보안 그룹 규칙 확인
aws ec2 describe-security-groups --group-ids <msk-security-group-id>

# MSK 브로커 엔드포인트 확인
aws kafka get-bootstrap-brokers --cluster-arn <msk-cluster-arn>
```

---

## 🗑️ **인프라 삭제**

### 전체 리소스 삭제
```powershell
terraform destroy
# "yes" 입력하여 삭제 승인
```

### 특정 리소스만 삭제
```powershell
terraform destroy -target=module.ec2
```

---

## 📊 **배포 결과 예시**

```
Outputs:

deployment_summary = {
  "aws_region" = "ap-northeast-2"
  "ec2_instance" = "i-1234567890abcdef0"
  "ec2_public_ip" = "1.2.3.4"
  "environment" = "dev"
  "iot_rule" = "iotmskpipelinepsw0904MSKRule"
  "iot_thing" = "test-psw0904"
  "msk_cluster" = "iot-msk-pipeline-psw0904-cluster"
  "project_name" = "iot-msk-pipeline-psw0904"
  "vpc_id" = "vpc-1234567890abcdef0"
}

ssh_command = "ssh -i psw0904-key.pem ec2-user@1.2.3.4"
```

이제 `terraform apply` 한 번으로 전체 IoT 파이프라인이 자동으로 구축됩니다! 🎯✨

---

## 🎯 **최종 배포 단계별 체크리스트**

### ✅ **1단계: 사전 준비 (5분)**
```powershell
# 1. AWS CLI 설정 확인
aws configure list

# 2. 키 페어 생성 (아직 없다면)
aws ec2 create-key-pair --key-name psw0904-key --query 'KeyMaterial' --output text > psw0904-key.pem

# 3. terraform.tfvars 확인
cat terraform.tfvars  # psw0904가 모든 곳에 포함되어 있는지 확인
```

### ✅ **2단계: Terraform 배포 (30분)**
```powershell
# 1. 디렉토리 이동
cd C:\Users\admin\Desktop\IoT-application\terraform

# 2. Terraform 초기화
terraform init

# 3. 배포 계획 확인
terraform plan

# 4. 실제 배포 (자동 승인)
terraform apply -auto-approve
```

### ✅ **3단계: 배포 완료 확인 (5분)**
```powershell
# 1. 배포 결과 확인
terraform output

# 2. 주요 리소스 확인
terraform output deployment_summary

# 3. SSH 명령어 확인
terraform output ssh_command
```

### ✅ **4단계: Consumer 테스트 (10분)**
```bash
# 1. EC2 접속
ssh -i psw0904-key.pem ec2-user@<PUBLIC_IP>

# 2. Consumer 서비스 시작
sudo systemctl start iot-msk-pipeline-psw0904-consumer
sudo systemctl status iot-msk-pipeline-psw0904-consumer

# 3. 로그 확인 (별도 터미널에서)
sudo journalctl -f -u iot-msk-pipeline-psw0904-consumer
```

### ✅ **5단계: IoT 메시지 테스트 (5분)**
```powershell
# 로컬 PowerShell에서 테스트 메시지 발송
aws iot-data publish --topic "topic/test" --payload '{\"temperature\": 25.5, \"humidity\": 60.2, \"timestamp\": \"2025-09-04T10:30:00Z\", \"device\": \"psw0904-sensor\"}' --region ap-northeast-2
```

### 🎯 **예상 결과**
```
✅ KMS 키: key-iot-msk-pipeline-psw0904-kms
✅ Secrets Manager: AmazonMSK_iotuser-psw0904  
✅ MSK 클러스터: iot-msk-pipeline-psw0904-cluster
✅ IoT Thing: test-psw0904
✅ IoT Rule: iotmskpipelinepsw0904MSKRule
✅ EC2 Consumer: 실시간 메시지 수신 중
```

**총 소요시간: 약 55분 (대부분 MSK 클러스터 생성 시간)**
