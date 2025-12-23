import time
import pandas as pd
import firebase_admin
from firebase_admin import credentials, db
from collections import deque

cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(
    cred,
    {"databaseURL": "https://shapeos-smarthome-default-rtdb.firebaseio.com/"}
)

CSV_PATH = "data/iot_data.csv"
TARGET_DEVICES = ["bulb", "fan", "pump", "bell"]
MAX_HISTORY = 50
DEFAULT_TEMPERATURE = 25

def push_device_data(device, row):
    ref = db.reference(f"appliances_by_type/{device}")
    snapshot = ref.get() or {}

    power = float(row["power"])
    voltage = float(row["voltage"])
    current = float(row["current"])
    temperature = float(row.get("temperature", DEFAULT_TEMPERATURE))

    for key, value in {
        "power": power,
        "voltage": voltage,
        "current": current,
        "temperature": temperature
    }.items():
        history = deque(snapshot.get(f"{key}_history", []), maxlen=MAX_HISTORY)
        history.append(value)

        snapshot[key] = value
        snapshot[f"{key}_history"] = list(history)

    ref.update(snapshot)

def main_loop():
    index_tracker = {d: 0 for d in TARGET_DEVICES}

    while True:
        try:
            df = pd.read_csv(CSV_PATH)
            df["device"] = df["device"].str.lower()

            for device in TARGET_DEVICES:
                device_rows = df[df["device"] == device]

                if device_rows.empty:
                    continue

                idx = index_tracker[device] % len(device_rows)
                row = device_rows.iloc[idx]

                push_device_data(device, row)
                index_tracker[device] += 1

                print(f"{device.capitalize()} data pushed")

            print("-" * 50)

        except Exception as e:
            print("CSV Streamer Error:", e)

        time.sleep(5)

if __name__ == "__main__":
    main_loop()
