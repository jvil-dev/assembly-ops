/**
 * Time Utilities
 *
 * Helper functions for converting between time formats.
 * PostgreSQL TIME columns require full Date objects, but only the time portion is used.
 *
 * Functions:
 *   - timeStringToDate: "HH:MM" string → Date object (for database writes)
 *   - dateToTimeString: Date object → "HH:MM" string (for API responses)
 *
 * Note: Uses epoch date (1980-01-01) as base for time-only Date objects.
 *
 * Used by: Session service
 */

/**
 * Converts HH:MM string to a Date object with just the time component
 * PostgreSQL TIME columns need a full Date but only use the time part
 */
export function timeStringToDate(timeStr: string): Date {
  const [hours, minutes] = timeStr.split(':').map(Number);
  const date = new Date(1980, 0, 1, hours, minutes, 0, 0);
  return date;
}

/**
 * Formats a Date to HH:MM string
 */

export function dateToTimeString(date: Date): string {
  const hours = date.getHours().toString().padStart(2, '0');
  const minutes = date.getMinutes().toString().padStart(2, '0');
  return `${hours}:${minutes}`;
}
