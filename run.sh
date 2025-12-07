#!/bin/bash
set -e

cd "$(dirname "$0")"

# Generate fresh load_data.sql from input files
echo "Generating load_data.sql..."
python3 generate_data_sql.py

# Stop and remove existing container (fresh start with new data)
echo "Starting fresh PostgreSQL container..."
docker-compose down -v 2>/dev/null || true
docker-compose up -d

# Wait for Postgres to be ready
echo "Waiting for PostgreSQL to be ready..."
until docker exec aoc_postgres pg_isready -U postgres > /dev/null 2>&1; do
    sleep 1
done
sleep 2  # Extra wait for init scripts to complete

echo ""
echo "=== Running Solutions ==="
echo ""

# Run all days that have solutions (auto-detect up to day 25)
for day in $(seq 1 25); do
    solution="day-${day}/solution.sql"
    if [ -f "$solution" ]; then
        echo "--- Day $day ---"
        docker exec -i aoc_postgres psql -U postgres -d aoc < "$solution"
        echo ""
    fi
done

echo "=== Done ==="
