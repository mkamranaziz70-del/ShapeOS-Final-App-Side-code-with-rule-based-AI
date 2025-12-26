import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
import joblib

# Define limits for generating labels
DEVICE_LIMITS = {
    "bulb": {"low": 20, "high": 60},
    "fan": {"low": 50, "high": 120},
    "pump": {"low": 200, "high": 800},
    "bell": {"low": 10, "high": 30}
}

# Generate training dataset
data = []
for device, limits in DEVICE_LIMITS.items():
    for power in range(limits["low"] - 20, limits["high"] + 200, 10):
        temperature = 20 + (power % 15)  # some variation
        if power < limits["low"]:
            label = "low_usage"
        elif power <= limits["high"]:
            label = "normal_usage"
        else:
            label = "high_usage"
        data.append([device, power, temperature, label])

df = pd.DataFrame(data, columns=["device", "power", "temperature", "label"])

# Encode categorical values
device_encoder = LabelEncoder()
label_encoder = LabelEncoder()

df["device"] = device_encoder.fit_transform(df["device"])
df["label"] = label_encoder.fit_transform(df["label"])

# Split dataset
X = df[["device", "power", "temperature"]]
y = df["label"]
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Train model
model = LogisticRegression(max_iter=1000)
model.fit(X_train, y_train)

# Test accuracy
y_pred = model.predict(X_test)
accuracy = accuracy_score(y_test, y_pred)
print(f"Model trained with accuracy: {accuracy*100:.2f}%")

# Save model
joblib.dump({
    "model": model,
    "device_encoder": device_encoder,
    "label_encoder": label_encoder
}, "model.pkl")
print("Model saved as model.pkl")
