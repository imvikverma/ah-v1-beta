# Multi-stage build for AurumHarmony Flask Backend
FROM python:3.11-slim as builder

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Production stage
FROM python:3.11-slim

WORKDIR /app

# Copy Python dependencies from builder
COPY --from=builder /root/.local /root/.local

# Copy application code
COPY aurum_harmony/ ./aurum_harmony/
COPY api/ ./api/
COPY engines/ ./engines/
COPY config/ ./config/
COPY aurum_harmony/master_codebase/Master_AurumHarmony_261125.py ./app.py

# Create logs directory
RUN mkdir -p /app/logs

# Make sure scripts are executable
RUN chmod +x /app/app.py

# Set environment variables
ENV PATH=/root/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app

# Expose ports
EXPOSE 5000 5001

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD python -c "import requests; requests.get('http://localhost:5000/health')" || exit 1

# Run the application
CMD ["python", "app.py"]

