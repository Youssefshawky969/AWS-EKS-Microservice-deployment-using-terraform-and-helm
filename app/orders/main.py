from fastapi import FastAPI, HTTPException
import os
import requests

app = FastAPI(title="Orders Service")

SERVICE_NAME = "orders"
ENV = os.getenv("ENV", "dev")
AUTH_SERVICE_URL = os.getenv("AUTH_SERVICE_URL", "http://localhost:8001")

@app.get("/health")
def health():
    return {"status": "ok", "service": SERVICE_NAME}

@app.get("/ready")
def ready():
    return {"ready": True}

@app.post("/order")
def create_order(username: str):
    # Call auth service
    auth_response = requests.post(
        f"{AUTH_SERVICE_URL}/login",
        params={"username": username},
        timeout=2
    )

    if auth_response.status_code != 200:
        raise HTTPException(status_code=401, detail="Auth failed")

    token = auth_response.json()["token"]

    return {
        "service": SERVICE_NAME,
        "env": ENV,
        "order_id": "ORD-123",
        "user_token": token
    }
