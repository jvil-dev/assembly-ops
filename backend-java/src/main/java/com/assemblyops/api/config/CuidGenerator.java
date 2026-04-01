package com.assemblyops.api.config;

/**
 * Hibernate BeforeExecutionGenerator that produces CUID1-format identifiers
 * 
 * CUID1 format: 'c' + timestamp(8) + counter(4) + fingerprint(4) + random(8) = 25 chars
 * All segments are base36-encoded. This matches the format produced by Prisma's cuid()
 * 
 * Implements BeforeExecutionGenerator - the ID is generated in Java before the INSERT
 * SQL is sent to the database (as opposed to database-generated IDs like sequences)
 */

import java.lang.management.ManagementFactory;
import java.security.SecureRandom;
import java.util.EnumSet;
import java.util.concurrent.atomic.AtomicInteger;

import org.hibernate.engine.spi.SharedSessionContractImplementor;
import org.hibernate.generator.BeforeExecutionGenerator;
import org.hibernate.generator.EventType;

public class CuidGenerator implements BeforeExecutionGenerator {

    private static final int BASE = 36;
    private static final int BLOCK_SIZE = 4;
    private static final int DISCRETE_VALUES = (int) Math.pow(BASE, BLOCK_SIZE);

    private static final AtomicInteger COUNTER = new AtomicInteger(0);
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final String FINGERPRINT = generateFingerprint();

    @Override
    public EnumSet<EventType> getEventTypes() {
        return EnumSet.of(EventType.INSERT);
    }

    @Override
    public Object generate(SharedSessionContractImplementor session, Object owner, Object currentValue,
            EventType eventType) {
        return generateCuid();
    }

    private String generateCuid() {
        var sb = new StringBuilder(25);

        // Prefix
        sb.append('c');

        // Timestamp in base36 (8 chars)
        sb.append(padBase36(System.currentTimeMillis(), 8));

        // Counter (4 chars, wraps at base36^4)
        int count = COUNTER.getAndUpdate(c -> (c + 1) % DISCRETE_VALUES);
        sb.append(padBase36(count, BLOCK_SIZE));

        // Fingerprint (4 chars)
        sb.append(FINGERPRINT);

        // Random block (8 chars)
        sb.append(padBase36(RANDOM.nextInt(DISCRETE_VALUES), BLOCK_SIZE));
        sb.append(padBase36(RANDOM.nextInt(DISCRETE_VALUES), BLOCK_SIZE));

        return sb.toString();
    }

    private static String padBase36(long value, int length) {
        var base36 = Long.toString(value, BASE);
        if (base36.length() >= length) {
            return base36.substring(base36.length() - length);
        }
        return "0".repeat(length - base36.length()) + base36;
    }

    private static String generateFingerprint() {
        // PID + hostname hash, matching CUID1 spec
        long pid = ProcessHandle.current().pid();
        String hostname = getHostname();
        int hostnameHash = hostname.chars().reduce(0, (acc, c) -> acc + c);
        var pidPart = padBase36(pid, 2);
        var hostPart = padBase36(hostnameHash, 2);
        return pidPart + hostPart;
    }

    private static String getHostname() {
        try {
            return ManagementFactory.getRuntimeMXBean().getName().split("@")[1];
        } catch (Exception e) {
            return "localhost";
        }
    }
}
