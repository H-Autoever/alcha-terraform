#!/usr/bin/env python3

import boto3
import json
import time
import logging
from datetime import datetime
import random

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 설정값
CONFIG = {
    'aws_region': 'ap-northeast-2',
    'iot_thing_name': 'test-psw0507',
    'iot_topic': 'topic/test',  # IoT Rule에서 리스닝하는 토픽
    'endpoint_url': None  # AWS IoT Core 엔드포인트 (자동으로 찾음)
}


def get_iot_endpoint():
    """AWS IoT Core 데이터 엔드포인트 조회"""
    try:
        iot_client = boto3.client('iot', region_name=CONFIG['aws_region'])
        response = iot_client.describe_endpoint(endpointType='iot:Data-ATS')
        return response['endpointAddress']
    except Exception as e:
        logger.error(f"IoT 엔드포인트 조회 실패: {e}")
        return None

def generate_sensor_data():
    """가상 센서 데이터 생성"""
    return {
        'device_id': CONFIG['iot_thing_name'],
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'temperature': round(random.uniform(20.0, 35.0), 2),
        'humidity': round(random.uniform(40.0, 80.0), 2),
        'pressure': round(random.uniform(990.0, 1020.0), 2),
        'location': {
            'latitude': round(random.uniform(37.4, 37.6), 6),
            'longitude': round(random.uniform(126.8, 127.2), 6)
        },
        'battery_level': random.randint(10, 100),
        'signal_strength': random.randint(-90, -30)
    }

def send_iot_message(message_data, topic=None):
    """AWS IoT Core로 메시지 발송"""
    try:
        # 토픽이 지정되지 않으면 기본 토픽 사용
        if topic is None:
            topic = CONFIG['iot_topic']
            
        # IoT 엔드포인트 가져오기
        endpoint = get_iot_endpoint()
        if not endpoint:
            raise Exception("IoT 엔드포인트를 가져올 수 없습니다")
        
        logger.info(f"IoT 엔드포인트: {endpoint}")
        
        # IoT Data 클라이언트 생성
        iot_data_client = boto3.client(
            'iot-data',
            region_name=CONFIG['aws_region'],
            endpoint_url=f'https://{endpoint}'
        )
        
        # 메시지 발송
        response = iot_data_client.publish(
            topic=topic,
            qos=1,
            payload=json.dumps(message_data, ensure_ascii=False)
        )
        
        logger.info(f"✅ 메시지 발송 성공 (토픽: {topic}): {response}")
        return True
        
    except Exception as e:
        logger.error(f"❌ 메시지 발송 실패 (토픽: {topic}): {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """메인 실행 함수"""
    logger.info("🚀 IoT 메시지 발송기 시작...")
    logger.info(f"🔧 설정: {CONFIG}")
    
    try:
        message_count = 0
        
        while True:
            # 센서 데이터 생성
            sensor_data = generate_sensor_data()
            
            logger.info("=" * 50)
            logger.info(f"📤 메시지 #{message_count + 1} 발송 중...")
            logger.info(f"📊 데이터: {json.dumps(sensor_data, indent=2, ensure_ascii=False)}")
            
            # 메시지 발송
            if send_iot_message(sensor_data):
                message_count += 1
                logger.info(f"✅ 총 {message_count}개 메시지 발송 완료")
            else:
                logger.error("❌ 메시지 발송 실패")
            
            logger.info("=" * 50)
            
            # 5초 대기
            time.sleep(5)
            
    except KeyboardInterrupt:
        logger.info(f"\n🛑 발송 중단됨 (Ctrl+C) - 총 {message_count}개 메시지 발송")
    except Exception as e:
        logger.error(f"오류 발생: {e}")
        import traceback
        traceback.print_exc()

def test_multiple_topics():
    """여러 IoT 토픽으로 테스트 메시지 발송"""
    # 테스트할 토픽들
    test_topics = [
        "topic/test",      # 기존 토픽
        "topic/sensor",    # 새로운 센서 토픽
        "topic/device",    # 새로운 디바이스 토픽
        "topic/alert"      # 새로운 알림 토픽
    ]
    
    success_count = 0
    
    for topic in test_topics:
        logger.info(f"\n📤 {topic} 토픽으로 메시지 발송 중...")
        
        # 토픽별로 약간 다른 데이터 생성
        message_data = generate_sensor_data()
        message_data['topic_name'] = topic
        message_data['message_type'] = topic.split('/')[-1]  # test, sensor, device, alert
        
        if send_iot_message(message_data, topic):
            success_count += 1
            logger.info(f"✅ {topic} 발송 성공!")
        else:
            logger.error(f"❌ {topic} 발송 실패!")
        
        # 토픽 간 간격
        time.sleep(1)
    
    logger.info(f"\n📊 테스트 결과: {success_count}/{len(test_topics)} 성공")
    return success_count == len(test_topics)

def test_single_message():
    """단일 테스트 메시지 발송"""
    logger.info("🧪 단일 테스트 메시지 발송...")
    
    test_data = generate_sensor_data()
    test_data['message'] = '테스트 메시지입니다'
    
    logger.info(f"📊 테스트 데이터: {json.dumps(test_data, indent=2, ensure_ascii=False)}")
    
    if send_iot_message(test_data):
        logger.info("✅ 테스트 메시지 발송 성공!")
    else:
        logger.error("❌ 테스트 메시지 발송 실패!")

if __name__ == "__main__":
    print("""
    🔧 IoT 메시지 발송기 로컬 테스트 가이드:
    
    1. 필요한 패키지 설치:
       pip install boto3
    
    2. AWS 자격증명 설정:
       aws configure
       또는 환경변수 설정: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
    
    3. 실행 옵션:
       - 연속 발송: python iot_publisher.py
       - 단일 테스트: python iot_publisher.py --test
       - 다중 토픽 테스트: python iot_publisher.py --multi-topics
    
    📝 현재 설정된 IoT 토픽: 'topic/test'
    📝 IoT Thing 이름: 'test-psw0507'
    """)
    
    import sys
    if '--test' in sys.argv:
        test_single_message()
    elif '--multi-topics' in sys.argv:
        test_multiple_topics()
    else:
        main()
