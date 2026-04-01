package com.assemblyops.api.config;

import javax.sql.DataSource;

import java.sql.Connection;
import java.time.Instant;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {
    private final DataSource dataSource;

    public HealthController(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        String dbStatus;
        try (Connection conn = dataSource.getConnection()) {
            conn.createStatement().execute("SELECT 1");
            dbStatus = "connected";
        } catch (Exception e) {
            dbStatus = "disconnected";
        }

        return ResponseEntity.ok(Map.of(
            "status", "healthy",
            "timestamp", Instant.now().toString(),
            "services", Map.of("database", dbStatus)
        ));
    }
}