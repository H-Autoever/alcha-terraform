# IoT-MSK-EC2 파이프라인

##  개요

AWS IoT Core, Amazon MSK (Managed Streaming for Apache Kafka), EC2를 활용한 실시간 IoT 데이터 파이프라인입니다.

###  아키텍처

`
IoT Device  AWS IoT Core  Amazon MSK  EC2 Consumer
`

- **IoT Core**: IoT 디바이스에서 전송된 데이터 수집
- **MSK**: Kafka 클러스터로 스트리밍 데이터 처리
- **EC2**: MSK에서 데이터를 소비하여 실시간 처리

##  프로젝트 구조

`
IoT-MSK-EC2/
 app/
    iot_publisher.py       # IoT 메시지 발송 스크립트
 terraform/
    main.tf               # 메인 Terraform 설정
    variables.tf          # 변수 정의
    outputs.tf           # 출력 값 정의
    modules/
        networking/       # VPC, 보안그룹 설정
        msk/             # Amazon MSK 클러스터
        iot/             # IoT Core 설정
        ec2/             # EC2 Consumer 인스턴스
 README.md
`

##  배포 가이드

### 1. 사전 요구사항

- AWS CLI 설정 (ws configure)
- Terraform 설치 (>= 1.0)
- Python 3.7+ (로컬 테스트용)

### 2. Terraform 배포

`ash
cd terraform

# 초기화
terraform init

# 배포 계획 확인
terraform plan

# 배포 실행
terraform apply
`

### 3. 로컬 테스트 환경 설정

`ash
cd app

# Python 가상환경 생성
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 패키지 설치
pip install boto3

# 테스트 메시지 발송
python iot_publisher.py --test
`

##  구성 요소

###  IoT Core
- **Thing**: 	est-psw0904
- **Topic**: 	opic/test
- **Rule**: MSK로 메시지 라우팅

###  Amazon MSK
- **버전**: Kafka 3.5.1
- **인증**: SCRAM-SHA-512
- **암호화**: TLS + KMS
- **모니터링**: CloudWatch 로깅

###  EC2 Consumer
- **인스턴스**: t3.micro (Amazon Linux 2)
- **Python**: 3.7.16
- **패키지**: confluent-kafka, boto3
- **서비스**: systemd 자동 실행

##  보안 설정

### IAM 역할
- **EC2 역할**: MSK, Secrets Manager 접근 권한
- **IoT 역할**: MSK 발행 권한

### 네트워킹
- **VPC**: 전용 네트워크 환경
- **보안그룹**: 최소 권한 원칙
- **서브넷**: 퍼블릭/프라이빗 분리

### 암호화
- **MSK**: TLS in-transit, KMS at-rest
- **Secrets**: SCRAM 자격증명 암호화 저장

##  모니터링

### CloudWatch 로그
- MSK 브로커 로그
- EC2 Consumer 애플리케이션 로그
- IoT Core 규칙 실행 로그

### 메트릭
- MSK 클러스터 성능
- EC2 인스턴스 리소스 사용량
- IoT 메시지 처리량

##  테스트

### 1. 단일 메시지 테스트
`ash
python iot_publisher.py --test
`

### 2. 연속 메시지 발송
`ash
python iot_publisher.py
`

### 3. EC2 Consumer 상태 확인
`ash
# SSH 접속
ssh -i psw0904-key.pem ec2-user@<EC2_PUBLIC_IP>

# Consumer 서비스 상태
sudo systemctl status iot-msk-pipeline-psw0904-consumer

# 실시간 로그 확인
sudo journalctl -f -u iot-msk-pipeline-psw0904-consumer
`

##  메시지 플로우

1. **발송**: IoT Publisher가 IoT Core로 JSON 메시지 전송
2. **라우팅**: IoT Rule이 메시지를 MSK 토픽으로 라우팅
3. **처리**: EC2 Consumer가 MSK에서 메시지 소비
4. **로깅**: CloudWatch에 처리 결과 기록

### 메시지 형식
`json
{
  "device_id": "test-psw0904",
  "timestamp": "2025-09-04T04:50:27.474600Z",
  "temperature": 30.91,
  "humidity": 61.96,
  "pressure": 1012.84,
  "location": {
    "latitude": 37.419712,
    "longitude": 126.821186
  },
  "battery_level": 84,
  "signal_strength": -55,
  "message": "테스트 메시지입니다"
}
`

##  리소스 정리

`ash
cd terraform
terraform destroy
`

##  참고사항

- **비용**: MSK 클러스터는 시간당 요금이 발생합니다
- **보안**: 실제 운영환경에서는 추가 보안 설정 필요
- **확장성**: 트래픽 증가 시 MSK 파티션 및 EC2 인스턴스 확장 고려

##  관련 문서

- [AWS IoT Core 개발자 가이드](https://docs.aws.amazon.com/iot/latest/developerguide/)
- [Amazon MSK 개발자 가이드](https://docs.aws.amazon.com/msk/latest/developerguide/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

**Built with  using Terraform & AWS**
