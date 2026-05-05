package com.fleet.inventory;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
public class OrderConsumer {

    private static final Logger logger = LoggerFactory.getLogger(OrderConsumer.class);
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final KafkaTemplate<String, String> kafkaTemplate;

    public OrderConsumer(KafkaTemplate<String, String> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    @KafkaListener(topics = "orders", groupId = "inventory-service-group")
    public void consumeOrder(String message) {
        try {
            JsonNode order = objectMapper.readTree(message);
            
            String orderId = order.get("orderId").asText();
            String product = order.get("product").asText();
            int quantity = order.get("quantity").asInt();
            
            logger.info("📦 Received order: {} - Product: {}, Quantity: {}", 
                       orderId, product, quantity);
            
            // Simulate inventory update
            boolean inventoryUpdated = updateInventory(product, quantity);
            
            if (inventoryUpdated) {
                // Publish inventory update event
                String inventoryUpdate = String.format(
                    "{\"orderId\":\"%s\",\"product\":\"%s\",\"quantityReduced\":%d,\"timestamp\":\"%s\",\"status\":\"updated\"}",
                    orderId, product, quantity, java.time.Instant.now()
                );
                
                kafkaTemplate.send("inventory-updates", orderId, inventoryUpdate);
                logger.info("✅ Inventory updated for order: {}", orderId);
            } else {
                logger.warn("⚠️ Insufficient inventory for order: {}", orderId);
            }
            
        } catch (Exception e) {
            logger.error("❌ Error processing order: {}", e.getMessage(), e);
        }
    }
    
    private boolean updateInventory(String product, int quantity) {
        // Simulate inventory check and update
        logger.info("🔄 Updating inventory: {} units of {}", quantity, product);
        
        // In real app: query database, check stock, reduce quantity
        // For demo: always succeed
        try {
            Thread.sleep(100); // Simulate DB operation
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        
        return true;
    }
}