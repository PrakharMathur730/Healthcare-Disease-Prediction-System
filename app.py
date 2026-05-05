import streamlit as st
import pandas as pd
import numpy as np
import joblib

# Load model files
model = joblib.load("model.pkl")
encoders = joblib.load("encoders.pkl")
disease_encoder = joblib.load("disease_encoder.pkl")
most_common = joblib.load("most_common.pkl")

symptom_columns = list(encoders.keys())

st.set_page_config(page_title="Disease Predictor", layout="centered")

st.title("🏥 Healthcare Disease Prediction System")
st.write("Select symptoms or type manually")

# ---- collect all valid symptoms ----
all_valid_symptoms = set()
for col in symptom_columns:
    all_valid_symptoms.update(encoders[col].classes_)

# ---- UI ----
selected_symptoms = []

for i, col in enumerate(symptom_columns[:5]):
    st.subheader(f"Symptom {i+1}")

    option = st.selectbox(
        f"Choose from list {i+1}",
        ["None"] + list(encoders[col].classes_)
    )

    manual = st.text_input(f"Or type symptom {i+1} (optional)")

    # priority: manual input > dropdown
    if manual.strip() != "":
        selected_symptoms.append(manual.strip().lower().replace(" ", "_"))
    else:
        selected_symptoms.append(option)

# ---- PREDICT ----
if st.button("🔍 Predict"):

    # ✅ VALIDATION
    invalid = []
    for s in selected_symptoms:
        if s == "None":
            continue
        if s not in all_valid_symptoms:
            invalid.append(s)

    if invalid:
        st.error(f"❌ Invalid symptom: '{invalid[0]}'")
        st.stop()

    # ---- encoding ----
    input_data = []

    for i, col in enumerate(symptom_columns):
        if i < len(selected_symptoms):
            val = selected_symptoms[i]
        else:
            val = most_common[col]

        le = encoders[col]

        if val in le.classes_:
            encoded = le.transform([val])[0]
        else:
            encoded = le.transform([most_common[col]])[0]

        input_data.append(encoded)

    input_df = pd.DataFrame([input_data], columns=symptom_columns)

    # ---- prediction ----
    probs = model.predict_proba(input_df)[0]
    top_indices = np.argsort(probs)[::-1][:3]

    st.subheader("Prediction Results")

    for i, idx in enumerate(top_indices):
        disease = disease_encoder.inverse_transform([idx])[0]
        confidence = probs[idx] * 100
        st.success(f"{i+1}. {disease} ({confidence:.2f}%)")

st.caption("⚠️ For educational purposes only")