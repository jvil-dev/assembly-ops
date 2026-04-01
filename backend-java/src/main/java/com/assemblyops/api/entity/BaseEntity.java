package com.assemblyops.api.entity;

/**
   * Mapped superclass providing common fields for most JPA entities.
   *
   * Provides id (CUID), createdAt, and updatedAt with lifecycle callbacks.
   * ~33 of 42 entities extend this. Entities missing updatedAt or createdAt
   * declare their own fields instead.
   *
   * OOP Pattern: Inheritance via @MappedSuperclass — subclasses inherit fields
   * and behavior, but BaseEntity itself has no database table.
*/

import java.time.Instant;

import com.assemblyops.api.config.CuidGenerated;

import jakarta.persistence.Column;
import jakarta.persistence.Id;
import jakarta.persistence.MappedSuperclass;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;

@MappedSuperclass
public abstract class BaseEntity {

    @Id
    @CuidGenerated
    @Column(nullable = false, length = 30)
    private String id;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    @Column(nullable = false)
    private Instant updatedAt;

    @PrePersist
    protected void onCreate() {
        var now = Instant.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = Instant.now();
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }
}
