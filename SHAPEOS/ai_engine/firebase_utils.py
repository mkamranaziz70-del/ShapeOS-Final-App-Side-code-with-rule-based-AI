import firebase_admin
from firebase_admin import credentials, db
from datetime import datetime

cred = credentials.Certificate('serviceAccountKey.json')

if not firebase_admin._apps:
    firebase_admin.initialize_app(cred, {
        'databaseURL': 'https://shapeos-smarthome-default-rtdb.firebaseio.com/'
    })

def upload_recommendations(ai_data):
    try:
        today = datetime.now().strftime("%Y-%m-%d")
        timestamp = datetime.now().strftime("%H:%M:%S")
        ref = db.reference('/recommendations')
        ref.child(today).child(timestamp).set(ai_data)
        print(f"Recommendations for {today} at {timestamp} uploaded successfully!")
    except Exception as e:
        print("Error uploading data:", e)

def fetch_latest_iot_data():
    try:
        ref = db.reference('/iot_data')
        data = ref.get()
        if data is None:
            data = {}  # return empty dict if no data
        return data
    except Exception as e:
        print("Error fetching IoT data:", e)
        return {}
