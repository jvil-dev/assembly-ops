package com.assemblyops.api.config;

/**
 * Custom Hibernate PhysicalNamingStrategy that preserves Prisma's naming conventions
 * 
 * Prisma generates PascalCase table names ("User", "Event") and camelCase column names
 * ("firstName", "eventType"). Hibernate's default strategy converts these to snake_case
 * ("user", "first_name"), which breaks ddl-auto: validate. This strategy returns all
 * identifiers unchanged
 */

import java.io.Serializable;

import org.hibernate.boot.model.naming.Identifier;
import org.hibernate.boot.model.naming.PhysicalNamingStrategy;
import org.hibernate.engine.jdbc.env.spi.JdbcEnvironment;

public class PrismaNamingStrategy implements PhysicalNamingStrategy, Serializable {

    private static final long serialVersionUID = 1L;

    @Override
    public Identifier toPhysicalCatalogName(Identifier name, JdbcEnvironment env) {
        return name;
    }

    @Override
    public Identifier toPhysicalSchemaName(Identifier name, JdbcEnvironment env) {
        return name;
    }

    @Override
    public Identifier toPhysicalTableName(Identifier name, JdbcEnvironment env) {
        return name;
    }

    @Override
    public Identifier toPhysicalSequenceName(Identifier name, JdbcEnvironment env) {
        return name;
    }

    @Override
    public Identifier toPhysicalColumnName(Identifier name, JdbcEnvironment env) {
        return name;
    }
}