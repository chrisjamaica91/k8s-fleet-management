package com.fleet.inventory;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

@RestController
public class HealthController {

    @GetMapping("/health")
    public Map<String, Object> health() {
        Map<String, Object> health = new HashMap<>();
        health.put("status", "healthy");
        health.put("service", "inventory-service");
        health.put("timestamp", Instant.now().toString());
        return health;
    }
    
    @GetMapping("/")
    public Map<String, Object> info() {
        Map<String, Object> info = new HashMap<>();
        info.put("service", "Inventory Service");
        info.put("version", "1.0.0");
        info.put("description", "Consumes orders from Kafka and manages inventory");
        return info;
    }
}