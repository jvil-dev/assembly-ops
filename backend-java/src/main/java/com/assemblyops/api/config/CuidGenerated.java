package com.assemblyops.api.config;

/**
 * 
 * Meta-annotated with @IdGeneratorType to tell Hibernate which generator class
 * to use. Entities annotate their @Id field with @CuidGenerated instead of
 * @GeneratedValue
 * 
 * Usage: @Id @CuidGenerated private String id;
 */

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

import org.hibernate.annotations.IdGeneratorType;

@IdGeneratorType(CuidGenerator.class)
@Retention(RetentionPolicy.RUNTIME)
@Target({ ElementType.FIELD, ElementType.METHOD })
public @interface CuidGenerated {
}