FROM python:3.11-slim AS builder

WORKDIR /app

# install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# install python requirements first for caching with retry mechanism
COPY requirements.txt ./
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --retries 3 --timeout 1000 -r requirements.txt uvicorn[standard]

# copy source
COPY . .

FROM python:3.11-slim

WORKDIR /app

# copy dependencies from builder
COPY --from=builder /usr/local /usr/local
COPY --from=builder /app /app

# ensure directories exist
RUN mkdir -p /app/logs /app/models

# Set PYTHONPATH to include the current directory so modules can be found
ENV PYTHONPATH=/app:$PYTHONPATH

EXPOSE 8000
CMD ["uvicorn", "api.server:app", "--host", "0.0.0.0", "--port", "8000"]
