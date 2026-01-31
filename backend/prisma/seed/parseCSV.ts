/**
 * parseCSV.ts
 *
 * Shared CSV parser for seed scripts.
 * Reads a CSV file and returns an array of key-value records
 * using the first row as column headers.
 * Handles quoted fields containing commas (e.g., "Natick, MA").
 * No external dependencies — uses only Node built-ins.
 */

import { readFileSync } from 'fs';
export function parseCSV(filePath: string): Record<string, string>[] {
  const content = readFileSync(filePath, 'utf-8').trim();
  const [headerLine, ...rows] = content.split('\n');
  const headers = parseLine(headerLine);

  return rows
    .filter((row) => row.trim())
    .map((row) => {
      const values = parseLine(row);
      const record: Record<string, string> = {};
      headers.forEach((header, i) => {
        record[header] = values[i] ?? '';
      });
      return record;
    });
}

/**
 * Parse a single CSV line, respecting quoted fields.
 * "value with, comma" → ["value with, comma"]
 */
function parseLine(line: string): string[] {
  const fields: string[] = [];
  let current = '';
  let inQuotes = false;

  for (let i = 0; i < line.length; i++) {
    const char = line[i];

    if (char === '"') {
      inQuotes = !inQuotes;
    } else if (char === ',' && !inQuotes) {
      fields.push(current.trim());
      current = '';
    } else {
      current += char;
    }
  }

  fields.push(current.trim());
  return fields;
}
