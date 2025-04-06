# ========== STAGE 1: BUILD ==========
FROM python:3.10-slim AS builder

WORKDIR /app

# Salin file requirements
COPY requirements.txt .

# Install dependencies ke folder terpisah
RUN pip install --upgrade pip && \
    pip install --prefix=/install -r requirements.txt

# Salin source code
COPY mainn.py .

# ========== STAGE 2: RUNTIME ==========
FROM python:3.10-slim

WORKDIR /app

# Salin hasil instalasi dari stage builder
COPY --from=builder /install /usr/local
COPY main.py .

# Jalankan aplikasi
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
