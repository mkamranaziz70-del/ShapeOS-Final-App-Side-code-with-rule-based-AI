import time
import joblib
import pandas as pd
import firebase_admin
from firebase_admin import credentials, db

cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred, {"databaseURL": "https://shapeos-smarthome-default-rtdb.firebaseio.com/"})

bundle = joblib.load("model.pkl")
model = bundle["model"]
device_encoder = bundle["device_encoder"]
label_encoder = bundle["label_encoder"]

TARGET_DEVICES = ["bulb", "fan", "pump", "bell"]
DEFAULT_TEMPERATURE = 25
DEFAULT_POWER = 0

def map_prediction_to_message(status):
    mapping = {
        "low_usage": "Device usage is low. Consider scheduling usage.",
        "normal_usage": "Device is operating efficiently.",
        "high_usage": "Device is consuming high power. Maintenance recommended."
    }
    return mapping.get(status, "No recommendation available")

def main_loop():
    appliances_ref = db.reference("appliances_by_type")
    recommendations_ref = db.reference("ai/ml_recommendation")
    
    last_readings = {}

    while True:
        try:
            appliances = appliances_ref.get() or {}

            for device_name in TARGET_DEVICES:
                readings = appliances.get(device_name, {})
                
                power = readings.get("power", last_readings.get(device_name, {}).get("power", DEFAULT_POWER))
                temperature = readings.get("temperature", last_readings.get(device_name, {}).get("temperature", DEFAULT_TEMPERATURE))
                
                last_readings[device_name] = {"power": power, "temperature": temperature}

                if device_name in device_encoder.classes_:
                    device_encoded = device_encoder.transform([device_name])[0]
                    input_df = pd.DataFrame([[device_encoded, power, temperature]], columns=["device", "power", "temperature"])
                    prediction = model.predict(input_df)[0]
                    confidence = max(model.predict_proba(input_df)[0])
                    status = label_encoder.inverse_transform([prediction])[0]
                else:
                    status = "normal_usage"
                    confidence = 0.5

                message = map_prediction_to_message(status)

                recommendations_ref.child(device_name).set({
                    "status": status,
                    "confidence": round(float(confidence), 2),
                    "recommendation": message,
                    "power": power,
                    "temperature": temperature
                })

                print(f"{device_name.capitalize()} ML recommendation updated: status={status}, confidence={round(float(confidence),2)}, power={power}, temp={temperature}")

            print("-" * 50)
        except Exception as e:
            print("Error:", e)

        time.sleep(5)

if __name__ == "__main__":
    main_loop()
