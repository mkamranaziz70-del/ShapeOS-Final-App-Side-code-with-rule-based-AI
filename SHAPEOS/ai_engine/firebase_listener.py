import firebase_admin
from firebase_admin import credentials, db
from datetime import datetime
import time

SERVICE_ACCOUNT_PATH = "serviceAccountKey.json"

DATABASE_URL = "https://shapeos-smarthome-default-rtdb.firebaseio.com/"

POWER_THRESHOLD = {
    "1": 50,
    "2": 50,
    "3": 50,
    "4": 50
}

DEVICE_MAP = {
    "1": "Fan",
    "2": "Bulb",
    "3": "Pump",
    "4": "Bell"
}

cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
firebase_admin.initialize_app(cred, {'databaseURL': DATABASE_URL})

def get_date():
    return datetime.now().strftime("%Y-%m-%d")

def get_hour():
    return datetime.now().strftime("%H")

def store_history(device_id, data):
    device_name = DEVICE_MAP.get(device_id, "Unknown")
    today = get_date()
    hour = get_hour()
    path = f"/devices_data/{device_name}/{today}/{hour}"
    db.reference(path).set(data)
    if data.get("power", 0) > POWER_THRESHOLD.get(device_id, 1000):
        notif_path = f"/notifications/{device_name}"
        db.reference(notif_path).set({
            "title": "Power Alert",
            "message": f"{device_name} power is high! Check graphs.",
            "timestamp": str(datetime.now())
        })
        print(f"[ALERT] {device_name} exceeded power threshold.")

def appliance_listener(event):
    try:
        snapshot = db.reference("/appliances").get()
        if not snapshot:
            return
        for device_id, values in snapshot.items():
            if not isinstance(values, dict):
                continue
            if all(k in values for k in ["voltage", "current", "power"]):
                store_history(device_id, {
                    "voltage": values["voltage"],
                    "current": values["current"],
                    "power": values["power"]
                })
    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    print("Firebase listener started...")
    ref = db.reference("/appliances")
    ref.listen(appliance_listener)
    while True:
        time.sleep(1)
