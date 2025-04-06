# Laporan Penugasan Modul 1

## Nomor 1 - Implementasi API Publik `/health`

API ini dibangun menggunakan framework **FastAPI** dan melalui endpoint /health

![image](https://github.com/user-attachments/assets/913a4b66-4727-4372-97cf-b10955318d5c)

### Cara Kerja API `/health`:

Ketika endpoint `/health` diakses, API akan:
1. Mengambil timestamp saat request diterima `datetime.now()`
2. Menghitung uptime server dengan cara mengurangkan waktu sekarang dengan waktu start `start_time`
3. Menyusun informasi dalam bentuk dictionary berisi:
   - `nama`: Nama lengkap pembuat API
   - `nrp`: Nomor induk mahasiswa
   - `status`: Menunjukkan server aktif `"UP"`
   - `timestamp`: Waktu request
   - `uptime`: Selisih waktu sejak API dimulai

### Modul Python yang Digunakan

| Modul             | Tipe     | Fungsi                                                                 |
|------------------|----------|------------------------------------------------------------------------|
| `fastapi`        | Eksternal| Framework web API utama                                                |
| `uvicorn`        | Eksternal| Web server ASGI untuk menjalankan FastAPI                              |
| `datetime`       | Built-in | Menghitung waktu server dan waktu sekarang                             |
| `time`           | Built-in | Mendapatkan timestamp waktu awal saat aplikasi dijalankan (`perf_counter`) |

---

## Nomor 2 - Deployment Docker Multi-Stage

###  **STAGE 1: `builder`**
Tahap ini hanya untuk menyiapkan dependency, bukan untuk dijalankan.

1. **Gunakan base image ringan:**
   ```dockerfile
   FROM python:3.10-slim AS builder
   ```
   - Image kecil dan cukup untuk membangun env Python
   - Tag `builder` dipakai nanti di `--from=builder`

2. **Buat working directory:**
   ```dockerfile
   WORKDIR /app
   ```

3. **Salin file requirements:**
   ```dockerfile
   COPY requirements.txt .
   ```

4. **Upgrade pip & install dependency ke lokasi terpisah:**
   ```dockerfile
   RUN pip install --upgrade pip && \
       pip install --prefix=/install -r requirements.txt
   ```
   - Pakai `--prefix=/install` supaya hasil instalasi bisa di-copy ke image runtime tanpa cache pip
   - Lebih bersih dan aman

5. **Salin file Python utama:**
   ```dockerfile
   COPY main.py .
   ```

### **STAGE 2: `runtime`**
Ini image akhir yang dijalankan di VPS / Railway.

1. **Gunakan ulang image base:**
   ```dockerfile
   FROM python:3.10-slim
   ```

2. **Buat ulang working directory:**
   ```dockerfile
   WORKDIR /app
   ```

3. **Salin hasil install dari builder stage:**
   ```dockerfile
   COPY --from=builder /install /usr/local
   ```
   - Ini “mengaktifkan” semua dependency dari tahap build

4. **Salin file `main.py` saja:**
   ```dockerfile
   COPY main.py .
   ```
   - Tidak perlu salin `requirements.txt` atau file lain

5. **Jalankan aplikasi saat container di-run:**
   ```dockerfile
   CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
   ```
   
### **Deployment Manual via Web**

1. **Masuk ke Railway**  
   Buka: [https://railway.app/dashboard](https://railway.app/dashboard)
   - Tampilan Dashboard:
     ![image](https://github.com/user-attachments/assets/78ad3d58-4778-45a0-8c3e-914c917186e2)

3. Klik **“New”**

4. Pilih **"Deploy from GitHub Repo"**
   - Tampilan layar project:
     ![image](https://github.com/user-attachments/assets/48d798cc-2207-475b-a6b5-77c056fc8a53)

5. Pilih repository (yang berisi `main.py`, `Dockerfile`, dsb)
    ![image](https://github.com/user-attachments/assets/07a60d7f-0918-4adb-b79c-66073d083a90)

6. Railway akan otomatis:
   - Clone repo
   - Mendeteksi `Dockerfile`
   - Build image
   - Menjalankan container API

7. Setelah selesai akan dapat URL publik seperti:
   ```
   https://<nama-proyek>.up.railway.app
   ```

8. Endpoint `/health` bisa diakses di:
   ```
   https://<nama-proyek>.up.railway.app/health
   ```
9. Link Endpoint `/health`: [https://tugas-1-oprecnetics-valensioarvinps.up.railway.app/health](https://tugas-1-oprecnetics-valensioarvinps.up.railway.app/health)

---

## Nomor 3 - CI/CD menggunakan GitHub Actions

### File: `.github/workflows/deploy.yml`

File ini menjelaskan seluruh alur otomatis yang dijalankan GitHub setiap kali terjadi:
- Push ke `main`
- Atau manual via tombol `Run workflow`

### Struktur CI/CD dibagi ke 3 job:

| Job     | Tujuan                                                      |
|----------|-------------------------------------------------------------|
| `test`  | Menjalankan unit test untuk memastikan API berjalan normal  |
| `build` | Membangun Docker image dari API                             |
| `deploy`| Mengirim aplikasi ke Railway secara otomatis                |

### Konfigurasi

```yaml
name: CI/CD - Deploy FastAPI to Railway
```
Memberi nama workflow agar mudah dikenali di tab **Actions** GitHub.

```yaml
on:
  workflow_dispatch:
  push:
    branches: [main]
  pull_request:
    branches: [main]
```
Trigger:
- `workflow_dispatch` → memungkinkan run manual
- `push` → otomatis dijalankan saat push ke `main`
- `pull_request` → dijalankan saat ada PR ke `main`

```yaml
env:
  PYTHON_VERSION: "3.10"
  RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
```
Variabel global:
- Versi Python default
- Railway token dari GitHub Secrets (tidak terlihat publik)

---

## Job: `test` – Unit Test Aplikasi

```yaml
jobs:
  test:
    name: 🧪 Test
    runs-on: ubuntu-latest
```
Menjalankan test di runner berbasis Ubuntu.

### Step :

#### 1. Clone Kode dari Repository:
```yaml
- name: Checkout code
  uses: actions/checkout@v3
```

#### 2. Setup Python Environment:
```yaml
- name: Setup Python
  uses: actions/setup-python@v4
  with:
    python-version: ${{ env.PYTHON_VERSION }}
```
Mengaktifkan Python 3.10 untuk environment testing.

#### 3. Install Dependencies:
```yaml
- name: Install dependencies
  run: |
    python -m pip install --upgrade pip
    pip install -r requirements.txt
```
Memastikan `pip` terbaru, lalu install dependency (`fastapi`, `pytest`, dll).

#### 4. Jalankan Test:
```yaml
- name: Run pytest
  run: |
    pytest > result.log 
    cat result.log
```
- `pytest` mencari file seperti `test_*.py` dan menjalankan test.
- Hasil disimpan ke `result.log`.

#### 5. Upload Hasil Test:
```yaml
- name: Upload test result
  uses: actions/upload-artifact@v4
  with:
    name: pytest-result
    path: result.log
```
Hasil test di-upload ke GitHub untuk dilihat nanti jika error terjadi.

---

## Job: `build` – Build Docker Image

```yaml
  build:
    name: 🛠️ Build Docker Image
    runs-on: ubuntu-latest
    needs: test
```
Build Docker hanya dilakukan jika **test sukses** (`needs: test`).

### Step :

#### 1. Clone Kode:
```yaml
- name: Checkout code
  uses: actions/checkout@v3
```

#### 2. Siapkan Buildx:
```yaml
- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3
```
Enable fitur **buildx**, yang mendukung cache dan multi-platform build.

#### 3. Build Docker Image:
```yaml
- name: Build Docker image
  run: docker build -t api-health .
```
Docker membangun image dari file `Dockerfile` dengan nama `api-health`.

---

## Job: `deploy` – Deploy ke Railway

```yaml
  deploy:
    name: 🚀 Deploy to Railway
    runs-on: ubuntu-latest
    needs: build
```
Job ini hanya dijalankan jika build berhasil (`needs: build`).

### Step :

#### 1. Clone Kode:
```yaml
- name: Checkout code
  uses: actions/checkout@v3
```

#### 2. Install Railway CLI:
```yaml
- name: Install Railway CLI
  run: npm install -g @railway/cli
```
Railway CLI digunakan untuk **push project** ke VPS Railway.

#### 3. Deploy:
```yaml
- name: Deploy with Railway
  run: railway up --service health-api-ci-cd-
  env:
    RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
```
- `railway up`: Perintah untuk deploy
- `--service`: Menentukan nama servicenya
- `RAILWAY_TOKEN`: Token disimpan di GitHub Secrets
