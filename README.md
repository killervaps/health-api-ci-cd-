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

