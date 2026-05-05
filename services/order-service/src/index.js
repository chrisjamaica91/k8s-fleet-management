const express = require('express');
const { Kafka } = require('kafkajs');
const { v4: uuidv4 } = require('uuid');

const app = express();
app.use(express.json());

// Kafka configuration
const kafka = new Kafka({
  clientId: 'order-service',
  brokers: [process.env.KAFKA_BROKERS || 'fleet-kafka-kafka-bootstrap:9092']
});

const producer = kafka.producer();

// Connect to Kafka on startup
let isKafkaConnected = false;
producer.connect()
  .then(() => {
    console.log('✅ Connected to Kafka');
    isKafkaConnected = true;
  })
  .catch(err => {
    console.error('❌ Kafka connection failed:', err);
  });

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'order-service',
    kafka: isKafkaConnected ? 'connected' : 'disconnected',
    timestamp: new Date().toISOString()
  });
});

// Create order endpoint
app.post('/orders', async (req, res) => {
  try {
    const { product, quantity, customerId, email } = req.body;

    // Validate input
    if (!product || !quantity || !customerId) {
      return res.status(400).json({
        error: 'Missing required fields: product, quantity, customerId'
      });
    }

    // Create order object
    const order = {
      orderId: uuidv4(),
      product,
      quantity,
      customerId,
      email: email || `customer-${customerId}@example.com`,
      timestamp: new Date().toISOString(),
      status: 'created'
    };

    // Publish to Kafka
    await producer.send({
      topic: 'orders',
      messages: [{
        key: order.orderId,
        value: JSON.stringify(order)
      }]
    });

    console.log(`📦 Order created: ${order.orderId}`);

    res.status(201).json({
      message: 'Order created successfully',
      order
    });

  } catch (error) {
    console.error('Error creating order:', error);
    res.status(500).json({
      error: 'Failed to create order',
      details: error.message
    });
  }
});

// Get service info
app.get('/', (req, res) => {
  res.json({
    service: 'Order Service',
    version: '1.0.0',
    endpoints: {
      health: 'GET /health',
      createOrder: 'POST /orders',
      info: 'GET /'
    }
  });
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`🚀 Order Service running on port ${PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, closing Kafka producer...');
  await producer.disconnect();
  process.exit(0);
});