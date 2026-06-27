FROM python:3.12-slim AS base

WORKDIR /app

# System deps for asyncpg
RUN apt-get update && \
    apt-get install -y --no-install-recommends libpq-dev && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

# Listen on 127.0.0.1 — Nginx will proxy from outside.
# In Docker, we need 0.0.0.0 for container networking, but Nginx handles external access.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
