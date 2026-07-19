#!/bin/bash
set -e

echo "=== DWMB Meta-System Startup ==="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: Docker is not running. Please start Docker first."
    exit 1
fi

echo "Starting services..."
docker compose up -d

echo "Waiting for PostgreSQL to be ready..."
sleep 5

# Wait for DB to be healthy
for i in {1..30}; do
    if docker compose exec db pg_isready -U dwmb > /dev/null 2>&1; then
        echo "PostgreSQL is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "ERROR: PostgreSQL failed to start"
        exit 1
    fi
    sleep 1
done

echo "Running seed data..."
pip install asyncpg "passlib[bcrypt]==1.7.4" "bcrypt==4.0.1" > /dev/null 2>&1 || true
python db/seeds/02_seed_data.py

echo ""
echo "=== DWMB is running! ==="
echo "  Web UI:  http://localhost:8000"
echo "  API Doc: http://localhost:8000/docs"
echo "  Admin:   admin / admin123"
echo "  User:    user / user123"
echo ""
