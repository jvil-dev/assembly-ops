/**
 * Structured Logging Utility
 *
 * Provides consistent, structured logging for the application.
 * Logs are formatted as JSON in production for easy parsing by log aggregators.
 * In development, logs are human-readable.
 *
 * Log Levels:
 *   - error: Application errors, exceptions
 *   - warn: Warning conditions
 *   - info: Informational messages (startup, shutdown, key events)
 *   - debug: Detailed debugging information (disabled in production)
 *
 * Usage:
 *   logger.info('Server started', { port: 4000 });
 *   logger.error('Database connection failed', { error: err.message });
 */

type LogLevel = 'error' | 'warn' | 'info' | 'debug';

interface LogContext {
  [key: string]: unknown;
}

class Logger {
  private isDevelopment = process.env.NODE_ENV !== 'production';

  private formatMessage(level: LogLevel, message: string, context?: LogContext): string {
    const timestamp = new Date().toISOString();

    if (this.isDevelopment) {
      // Human-readable format for development
      const contextStr = context ? ` ${JSON.stringify(context)}` : '';
      return `[${timestamp}] ${level.toUpperCase()}: ${message}${contextStr}`;
    } else {
      // JSON format for production (easier to parse with log aggregators)
      return JSON.stringify({
        timestamp,
        level,
        message,
        ...context,
      });
    }
  }

  error(message: string, context?: LogContext): void {
    console.error(this.formatMessage('error', message, context));
  }

  warn(message: string, context?: LogContext): void {
    console.warn(this.formatMessage('warn', message, context));
  }

  info(message: string, context?: LogContext): void {
    console.log(this.formatMessage('info', message, context));
  }

  debug(message: string, context?: LogContext): void {
    // Skip debug logs in production
    if (this.isDevelopment) {
      console.debug(this.formatMessage('debug', message, context));
    }
  }
}

export const logger = new Logger();
