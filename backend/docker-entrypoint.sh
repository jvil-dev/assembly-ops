#!/bin/sh
set -e

echo "Running database migrations..."
if npx prisma migrate deploy 2>&1; then
  echo "Migrations complete."
else
  echo "WARNING: Migration failed (may need DIRECT_URL for non-pooler connection). Starting server anyway."
fi

echo "Starting server..."
exec node dist/server.js
