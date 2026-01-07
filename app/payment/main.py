from fastapi import FastAPI, HTTPException
import random
import time

app = FastAPI(title="Payment Service")

SERVICE_NAME = "payment"

@app.get("/health")
def health():
    return {"status": "ok", "service": SERVICE_NAME}

@app.get("/ready")
def ready():
    return {"ready": True}

@app.post("/pay")
def process_payment(amount: float):
    # Simulate latency
    time.sleep(random.uniform(0.5, 2.0))

    # Simulate random failure
    if random.random() < 0.3:
        raise HTTPException(status_code=500, detail="Payment provider error")

    return {
        "service": SERVICE_NAME,
        "status": "payment successful",
        "amount": amount
    }
