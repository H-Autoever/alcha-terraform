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
    'endpoint_url': None  # AWS IoT Core 엔드포인트 (자동으로 찾음)
}

# 차량 토픽들
VEHICLE_TOPICS = [
    'topic/truck',
    'topic/sedan', 
    'topic/suv'
]

def get_iot_endpoint():
    """AWS IoT Core 데이터 엔드포인트 조회"""
    try:
        iot_client = boto3.client('iot', region_name=CONFIG['aws_region'])
        response = iot_client.describe_endpoint(endpointType='iot:Data-ATS')
        return response['endpointAddress']
    except Exception as e:
        logger.error(f"IoT 엔드포인트 조회 실패: {e}")
        return None

def generate_vehicle_data(vehicle_type):
    """차량별 가상 센서 데이터 생성"""
    base_data = {
        'device_id': CONFIG['iot_thing_name'],
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'vehicle_type': vehicle_type,
        'engine_temperature': round(random.uniform(80.0, 110.0), 2),
        'fuel_level': round(random.uniform(10.0, 95.0), 2),
        'location': {
            'latitude': round(random.uniform(37.4, 37.6), 6),
            'longitude': round(random.uniform(126.8, 127.2), 6)
        },
        'mileage': random.randint(50000, 200000),
        'tire_pressure': {
            'front_left': round(random.uniform(30.0, 35.0), 1),
            'front_right': round(random.uniform(30.0, 35.0), 1),
            'rear_left': round(random.uniform(30.0, 35.0), 1),
            'rear_right': round(random.uniform(30.0, 35.0), 1)
        },
        'battery_voltage': round(random.uniform(12.0, 14.4), 2)
    }
    
    # 차량 타입별 특화 데이터
    if vehicle_type == 'truck':
        base_data.update({
            'cargo_weight': round(random.uniform(0, 20000), 2),  # kg
            'max_speed': round(random.uniform(80, 120), 1),      # km/h
            'fuel_consumption': round(random.uniform(8, 15), 2), # L/100km
            'trailer_connected': random.choice([True, False])
        })
    elif vehicle_type == 'sedan':
        base_data.update({
            'passenger_count': random.randint(1, 5),
            'max_speed': round(random.uniform(120, 180), 1),     # km/h
            'fuel_consumption': round(random.uniform(6, 10), 2), # L/100km
            'air_conditioning': random.choice([True, False])
        })
    elif vehicle_type == 'suv':
        base_data.update({
            'passenger_count': random.randint(1, 7),
            'max_speed': round(random.uniform(100, 160), 1),     # km/h
            'fuel_consumption': round(random.uniform(8, 12), 2), # L/100km
            'four_wheel_drive': random.choice([True, False]),
            'roof_rack_load': round(random.uniform(0, 100), 2)   # kg
        })
    
    return base_data

def send_iot_message(message_data, topic):
    """AWS IoT Core로 메시지 발송"""
    try:
        # IoT 엔드포인트 가져오기
        endpoint = get_iot_endpoint()
        if not endpoint:
            raise Exception("IoT 엔드포인트를 가져올 수 없습니다")
        
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
        
        logger.info(f"✅ {message_data['vehicle_type'].upper()} 메시지 발송 성공 (토픽: {topic})")
        return True
        
    except Exception as e:
        logger.error(f"❌ 메시지 발송 실패 (토픽: {topic}): {e}")
        import traceback
        traceback.print_exc()
        return False

def vehicle_simulation():
    """차량 데이터 시뮬레이션 - 1초마다 순환"""
    logger.info("🚗 차량 데이터 시뮬레이션 시작...")
    logger.info(f"🔧 설정: {CONFIG}")
    logger.info(f"🚙 차량 토픽들: {VEHICLE_TOPICS}")
    
    try:
        message_count = 0
        topic_index = 0
        
        while True:
            # 현재 차량 토픽 선택 (순환)
            current_topic = VEHICLE_TOPICS[topic_index]
            vehicle_type = current_topic.split('/')[-1]  # truck, sedan, suv
            
            # 차량 데이터 생성
            vehicle_data = generate_vehicle_data(vehicle_type)
            
            logger.info("=" * 60)
            logger.info(f"📤 메시지 #{message_count + 1} | 차량: {vehicle_type.upper()}")
            logger.info(f"📊 주요 데이터: 연료 {vehicle_data['fuel_level']}%, 엔진온도 {vehicle_data['engine_temperature']}°C")
            
            # 메시지 발송
            if send_iot_message(vehicle_data, current_topic):
                message_count += 1
                logger.info(f"✅ 총 {message_count}개 메시지 발송 완료")
            else:
                logger.error(f"❌ {vehicle_type.upper()} 메시지 발송 실패")
            
            # 다음 토픽으로 순환
            topic_index = (topic_index + 1) % len(VEHICLE_TOPICS)
            
            logger.info("=" * 60)
            
            # 1초 대기
            time.sleep(1)
            
    except KeyboardInterrupt:
        logger.info(f"\n🛑 시뮬레이션 중단됨 (Ctrl+C) - 총 {message_count}개 메시지 발송")
    except Exception as e:
        logger.error(f"오류 발생: {e}")
        import traceback
        traceback.print_exc()

def test_all_vehicles():
    """모든 차량 타입으로 한 번씩 테스트"""
    logger.info("🧪 차량별 테스트 메시지 발송...")
    
    success_count = 0
    
    for topic in VEHICLE_TOPICS:
        vehicle_type = topic.split('/')[-1]
        logger.info(f"\n📤 {vehicle_type.upper()} 차량 테스트 중...")
        
        # 차량별 데이터 생성
        vehicle_data = generate_vehicle_data(vehicle_type)
        
        logger.info(f"📊 테스트 데이터 미리보기:")
        logger.info(f"   - 차량타입: {vehicle_data['vehicle_type']}")
        logger.info(f"   - 연료레벨: {vehicle_data['fuel_level']}%")
        logger.info(f"   - 엔진온도: {vehicle_data['engine_temperature']}°C")
        
        if send_iot_message(vehicle_data, topic):
            success_count += 1
            logger.info(f"✅ {vehicle_type.upper()} 테스트 성공!")
        else:
            logger.error(f"❌ {vehicle_type.upper()} 테스트 실패!")
        
        # 차량 간 간격
        time.sleep(1)
    
    logger.info(f"\n📊 테스트 결과: {success_count}/{len(VEHICLE_TOPICS)} 성공")
    return success_count == len(VEHICLE_TOPICS)

def detailed_vehicle_info():
    """차량별 상세 데이터 샘플 출력"""
    print("\n🚗 차량별 데이터 샘플:")
    print("=" * 80)
    
    for topic in VEHICLE_TOPICS:
        vehicle_type = topic.split('/')[-1]
        sample_data = generate_vehicle_data(vehicle_type)
        
        print(f"\n📋 {vehicle_type.upper()} 샘플 데이터:")
        print(f"   토픽: {topic}")
        print(f"   데이터: {json.dumps(sample_data, indent=4, ensure_ascii=False)}")
        print("-" * 60)

if __name__ == "__main__":
    print("""
    🚗 차량 IoT 데이터 시뮬레이터
    
    1. 필요한 패키지 설치:
       pip install boto3
    
    2. AWS 자격증명 설정:
       aws configure
       또는 환경변수 설정: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
    
    3. 실행 옵션:
       - 연속 시뮬레이션 (1초마다 순환): python vehicle_publisher.py
       - 차량별 단일 테스트: python vehicle_publisher.py --test
       - 데이터 샘플 확인: python vehicle_publisher.py --sample
    
    🚙 지원하는 차량 타입:
       - topic/truck  : 트럭 (화물차)
       - topic/sedan  : 세단 (승용차)  
       - topic/suv    : SUV (스포츠 유틸리티)
    
    📝 IoT Thing 이름: 'test-psw0507'
    """)
    
    import sys
    if '--test' in sys.argv:
        test_all_vehicles()
    elif '--sample' in sys.argv:
        detailed_vehicle_info()
    else:
        vehicle_simulation()
