import pandas as pd
import pickle
from firebase_admin import credentials, initialize_app, db

# -------------------------------
# Firebase initialization
# -------------------------------
cred = credentials.Certificate("path/to/your-firebase-adminsdk.json")  # Update this
initialize_app(cred, {
    'databaseURL': 'https://your-firebase-database-url.firebaseio.com/'  # Update this
})

# -------------------------------
# Load AI model
# -------------------------------
with open("energy_model.pkl", "rb") as f:  # Update path if needed
    model = pickle.load(f)

# -------------------------------
# Load IoT CSV data
# -------------------------------
data = pd.read_csv("iotdata.csv")  # Update if your CSV has a different name/path

# Preprocess features for the model
# Ensure same order as model trained
features = ['current', 'energy', 'voltage', 'isOn', 'power', 'hour']  # Exclude 'date' & 'device'
X = data[features]

# Predict optimized energy usage / recommendation
data['recommendation'] = model.predict(X)

# -------------------------------
# Upload to Firebase
# -------------------------------
ref = db.reference('recommendations')  # Firebase node

# Convert to dict with device names as keys
recommendations = {}
for _, row in data.iterrows():
    device = str(row['device'])  # Keep device names as strings
    recommendations[device] = {
        'current': float(row['current']),
        'energy': float(row['energy']),
        'voltage': float(row['voltage']),
        'isOn': bool(row['isOn']),
        'power': float(row['power']),
        'hour': int(row['hour']),
        'date': row['date'],
        'recommendation': float(row['recommendation'])
    }

# Upload all recommendations at once
ref.set(recommendations)

print("✅ AI recommendations uploaded to Firebase successfully!")
