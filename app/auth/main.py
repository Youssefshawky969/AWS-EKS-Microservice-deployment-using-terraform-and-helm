from fastapi import FastAPI, HTTPException
import os
import time

app = FastAPI(title="Auth Service")

SERVICE_NAME = "auth"
ENV = os.getenv("ENV", "dev")

@app.get("/health")
def health():
    return {"status": "ok", "service": SERVICE_NAME}

@app.get("/ready")
def ready():
    return {"ready": True}

@app.post("/login")
def login(username: str):
    if not username:
        raise HTTPException(status_code=400, detail="Username required")

    # Fake token simulation
    token = f"token-{username}-{int(time.time())}"

    return {
        "service": SERVICE_NAME,
        "env": ENV,
        "token": token
    }
