from fastapi import FastAPI
from datetime import datetime, timedelta
import time

start_time = time.time()
app = FastAPI()

@app.get("/health")
def health():
    uptime = str(timedelta(seconds=int(time.time() - start_time)))
    return {
        "nama": "Valensio Arvin Putra Setiawan",
        "nrp": "5025231273",
        "status": "DOWN",
        "timestamp": datetime.now().isoformat(),
        "uptime": uptime
    }
