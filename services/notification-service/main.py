from fastapi import FastAPI, BackgroundTasks
from kafka import KafkaConsumer
import json
import logging
import os
import threading
from datetime import datetime

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Notification Service", version="1.0.0")

# Kafka configuration
KAFKA_BROKERS = os.getenv('KAFKA_BROKERS', 'fleet-kafka-kafka-bootstrap:9092')
kafka_connected = False

def consume_orders():
    """Background task to consume orders from Kafka"""
    global kafka_connected
    
    try:
        consumer = KafkaConsumer(
            'orders',
            bootstrap_servers=KAFKA_BROKERS.split(','),
            group_id='notification-service-group',
            auto_offset_reset='earliest',
            value_deserializer=lambda m: json.loads(m.decode('utf-8'))
        )
        
        kafka_connected = True
        logger.info("✅ Connected to Kafka, listening for orders...")
        
        for message in consumer:
            order = message.value
            send_notification(order)
            
    except Exception as e:
        logger.error(f"❌ Kafka consumer error: {e}")
        kafka_connected = False

def send_notification(order):
    """Send notification for an order"""
    try:
        order_id = order.get('orderId')
        customer_email = order.get('email')
        product = order.get('product')
        quantity = order.get('quantity')
        
        logger.info(f"📧 Sending notification for order: {order_id}")
        logger.info(f"   To: {customer_email}")
        logger.info(f"   Product: {product} (Quantity: {quantity})")
        
        # In real app: send actual email/SMS via SendGrid, Twilio, etc.
        # For demo: just log it
        notification_message = (
            f"Order Confirmation\n"
            f"Order ID: {order_id}\n"
            f"Product: {product}\n"
            f"Quantity: {quantity}\n"
            f"Thank you for your order!"
        )
        
        logger.info(f"✅ Notification sent: {notification_message}")
        
    except Exception as e:
        logger.error(f"❌ Error sending notification: {e}")

@app.on_event("startup")
async def startup_event():
    """Start Kafka consumer in background thread"""
    consumer_thread = threading.Thread(target=consume_orders, daemon=True)
    consumer_thread.start()
    logger.info("🚀 Notification Service started")

@app.get("/")
def root():
    return {
        "service": "Notification Service",
        "version": "1.0.0",
        "description": "Consumes orders and sends notifications",
        "endpoints": {
            "health": "GET /health",
            "info": "GET /"
        }
    }

@app.get("/health")
def health():
    return {
        "status": "healthy",
        "service": "notification-service",
        "kafka": "connected" if kafka_connected else "disconnected",
        "timestamp": datetime.utcnow().isoformat()
    }

@app.post("/notify")
def manual_notify(message: dict):
    """Manual notification endpoint for testing"""
    send_notification(message)
    return {"status": "notification sent", "message": message}