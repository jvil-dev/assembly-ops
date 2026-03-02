/**
 * CSV String Parser
 *
 * Parses CSV data from a string (not a file) for use in the admin import pipeline.
 * Handles quoted fields containing commas. Returns parsed rows with headers,
 * plus any parsing errors.
 *
 * Used by: services/adminService.ts
 */

export interface CSVParseResult {
  headers: string[];
  rows: Record<string, string>[];
  errors: string[];
}

/**
 * Parse a CSV string into headers + rows.
 * Returns empty rows array with an error if the CSV is empty or has no data rows.
 */
export function parseCSVString(csvData: string): CSVParseResult {
  const errors: string[] = [];
  const trimmed = csvData.trim();

  if (!trimmed) {
    return { headers: [], rows: [], errors: ['CSV data is empty'] };
  }

  const lines = trimmed.split('\n');
  const headerLine = lines[0];
  const headers = parseLine(headerLine);

  if (headers.length === 0) {
    return { headers: [], rows: [], errors: ['No headers found in CSV'] };
  }

  const rows: Record<string, string>[] = [];

  for (let i = 1; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;

    const values = parseLine(line);
    if (values.length !== headers.length) {
      errors.push(`Row ${i}: expected ${headers.length} columns, got ${values.length}`);
      continue;
    }

    const record: Record<string, string> = {};
    headers.forEach((header, idx) => {
      record[header] = values[idx] ?? '';
    });
    rows.push(record);
  }

  return { headers, rows, errors };
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
