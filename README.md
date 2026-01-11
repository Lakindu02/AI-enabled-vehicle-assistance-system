#Frontend 

# 🚗 AI-Powered Vehicle Assistance Platform – Frontend

## 📖 Project Overview

This project is a **mobile-based intelligent vehicle assistance application** designed to support vehicle owners, insurance companies, service providers, and emergency responders. The frontend provides users with real-time access to vehicle damage assessment, repair cost estimation, emergency assistance, and location-based service support.

The application allows users to capture vehicle damage using a mobile device, interact with an AI-powered chatbot for roadside diagnostics, receive emergency alerts, and locate nearby service or garage facilities. All information is securely synchronized with cloud services to ensure real-time availability and reliability.

The frontend is developed using **Flutter**, enabling a responsive, cross-platform mobile experience with a modern and user-friendly interface.

---

## ❓ What is the Project?

This is a **Flutter-based mobile frontend application** that provides:

- Vehicle damage capture and submission
- AI-based damage analysis results
- Repair cost estimation reports
- Emergency alerts and notifications
- Interactive roadside assistance chatbot
- Location-based service and garage finder
- Secure user authentication and data access

---

## 🏗️ Architecture Diagram

```
┌────────────────────────── Mobile Frontend (Flutter) ──────────────────────────┐
│                                                                                │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐                       │
│  │  UI Screens │  │ Navigation   │  │  UI Components │                       │
│  │ (Dashboard, │  │ (Routes)     │  │ (Cards, Maps, │                       │
│  │ Damage,     │  │              │  │ Chatbot)      │                       │
│  │ Emergency)  │  └──────────────┘  └────────────────┘                       │
│                                                                                │
│  ┌──────────────────────── Feature Modules ─────────────────────────┐         │
│  │ - Damage Capture & Upload                                          │         │
│  │ - AI Result Display                                                │         │
│  │ - Emergency Alerts                                                 │         │
│  │ - Service / Garage Finder                                          │         │
│  │ - NLP Chatbot Interface                                            │         │
│  └───────────────────────────────────────────────────────────────────┘         │
│                                                                                │
└────────────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
                     ┌────────────────────────┐
                     │ Backend APIs (Python)  │
                     │ - FastAPI              │
                     │ - AI / ML Models       │
                     └────────────────────────┘
                                │
                                ▼
                     ┌────────────────────────┐
                     │ Firebase Cloud Services │
                     │ - Auth                  │
                     │ - Firestore             │
                     │ - Storage               │
                     │ - Notifications (FCM)  │
                     └────────────────────────┘
```

---

## 🛠️ Technology Stack

| **Category**         | **Technology**           | **Version** | **Purpose**                                   |
| -------------------- | ------------------------ | ----------- | --------------------------------------------- |
| Frontend Framework   | Flutter                  | Latest      | Cross-platform mobile application             |
| Programming Language | Dart                     | Latest      | Frontend application logic                    |
| Backend Framework    | FastAPI                  | Latest      | REST API and AI service handling              |
| Backend Language     | Python                   | 3.10+       | AI processing and backend logic               |
| AI / ML Framework    | TensorFlow / PyTorch     | Latest      | Damage detection and severity analysis        |
| Computer Vision      | OpenCV                   | Latest      | Image preprocessing and damage identification |
| NLP Engine           | spaCy / Transformers     | Latest      | Roadside assistance chatbot                   |
| Database             | Firebase Firestore       | Latest      | Cloud-based NoSQL data storage                |
| Authentication       | Firebase Authentication  | Latest      | Secure user authentication                    |
| Cloud Storage        | Firebase Storage         | Latest      | Image and video storage                       |
| Notifications        | Firebase Cloud Messaging | Latest      | Emergency alerts and push notifications       |
| Location Services    | Google Maps API          | Latest      | Service and garage finder                     |
| API Communication    | HTTP / Dio               | Latest      | Frontend–backend communication                |
| Hosting / Cloud      | Firebase / Google Cloud  | Latest      | Scalable cloud infrastructure                 |

---

## ⚙️ Development Dependencies

```json
{
  "Build": "Flutter + Dart",
  "State Management": "Provider / Bloc",
  "Linting": "Flutter Lints",
  "Formatting": "Dart Formatter",
  "API Communication": "Dio / HTTP",
  "Cloud Services": "Firebase (Auth, Firestore, Storage)",
  "Notifications": "Firebase Cloud Messaging"
}
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- Dart SDK
- Android Studio or VS Code
- Android Emulator or physical device
- Firebase project setup
- Internet connection

---

## 🛠️ Installation

```bash
git clone <frontend-repo-url>
cd vehicle-assistance-frontend
flutter pub get
flutter run
```

---

## 📁 Project Structure

```
vehicle-assistance-frontend/
├── lib/
│   ├── screens/
│   ├── widgets/
│   ├── services/
│   ├── models/
│   ├── utils/
│   └── main.dart
├── assets/
├── pubspec.yaml
└── README.md
```

---

## ✨ Features

- 🚗 Vehicle Damage Capture & Analysis
- 🧠 AI-Based Severity Detection
- 💰 Repair Cost Estimation
- 📍 Service & Garage Finder
- 🚨 Emergency Detection & Alerts
- 💬 NLP-Based Roadside Chatbot
- ☁️ Cloud Data Synchronization

---

## 🔮 Upcoming Features

- iOS platform support
- Multi-language support (Sinhala & English)
- Offline emergency mode
- Insurance claim integration

---

## 🤝 Contributing

Contributions are welcome. Please submit pull requests for improvements or bug fixes.





#Backend 


# 🖥️ AI-Powered Vehicle Assistance Platform – Backend

## 📖 Project Overview

The backend of the AI-Powered Vehicle Assistance Platform provides RESTful APIs and AI/ML integrations to support intelligent vehicle damage analysis, emergency detection, and real-time assistance services.

The backend is responsible for handling user requests from the mobile application, processing vehicle damage data using AI models, managing emergency alerts, and securely storing data in cloud services.

Key backend functionalities include:

- AI-based vehicle damage identification and severity analysis  
- Repair cost estimation and report generation  
- Emergency detection and alert triggering  
- NLP-based chatbot support for roadside diagnostics  
- Integration with Firebase for authentication, storage, and notifications  

The backend is developed using **Python (FastAPI)** and integrates AI/ML models with cloud-based services for scalability and reliability.

---

## 🏗️ Architecture Diagram

```
┌────────────────────────── Backend Architecture ──────────────────────────┐
│                                                                           │
│  ┌───────────────┐     ┌────────────────────┐     ┌──────────────────┐  │
│  │ FastAPI APIs  │     │ Authentication     │     │ Controllers /    │  │
│  │ Endpoints     │────▶│ (Firebase Auth)    │────▶│ Business Logic   │  │
│  │ - /damage     │     └────────────────────┘     └──────────────────┘  │
│  │ - /estimate   │                                                    │
│  │ - /emergency  │                                                    │
│  │ - /chatbot    │                                                    │
│  └───────────────┘                                                    │
│          │                                                             │
│          ▼                                                             │
│  ┌──────────────────────────┐      ┌──────────────────────────────┐  │
│  │ AI / ML Processing Layer │      │ Firebase Cloud Services       │  │
│  │ - Damage Detection (CV)  │      │ - Firestore Database          │  │
│  │ - Severity Analysis     │      │ - Firebase Storage            │  │
│  │ - Cost Estimation       │      │ - Cloud Messaging (FCM)       │  │
│  │ - NLP Chatbot Models    │      │ - Authentication              │  │
│  └──────────────────────────┘      └──────────────────────────────┘  │
│          │                                                             │
│          └───────────────┬─────────────────────────────────────────────┘
│                          ▼
│                   API Responses
│          (Reports, Alerts, Predictions)
└───────────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Technologies & Dependencies

| Category            | Technology                    | Version | Purpose                                      |
|---------------------|-------------------------------|---------|----------------------------------------------|
| **Language**        | Python                        | 3.10+   | Backend and AI development                   |
| **Framework**       | FastAPI                       | Latest  | REST API framework                           |
| **AI / ML**         | TensorFlow / PyTorch          | Latest  | Damage detection & severity analysis         |
| **Computer Vision** | OpenCV                        | Latest  | Image preprocessing and feature extraction  |
| **NLP**             | spaCy / Transformers          | Latest  | Chatbot and text understanding               |
| **Database**        | Firebase Firestore            | Latest  | Cloud-based NoSQL database                  |
| **Storage**         | Firebase Storage              | Latest  | Image and video storage                     |
| **Authentication**  | Firebase Authentication       | Latest  | Secure user authentication                  |
| **Notifications**   | Firebase Cloud Messaging      | Latest  | Emergency alerts & notifications            |
| **Maps Integration**| Google Maps API               | Latest  | Location-based services                     |
| **Server**          | Uvicorn                       | Latest  | ASGI server for FastAPI                     |

---

## 🚀 Getting Started

### Prerequisites

- Python 3.10 or higher  
- pip (Python package manager)  
- Virtual environment (venv or conda)  
- Firebase project with Auth, Firestore, Storage, and FCM enabled  
- Internet connection  

---

## 🛠️ Installation

```bash
git clone <backend-repo-url>
cd vehicle-assistance-backend
python -m venv venv
# Activate environment and install dependencies
pip install -r requirements.txt
uvicorn main:app --reload
```

---

## 📁 Project Structure

```
vehicle-assistance-backend/
├── app/
│   ├── api/
│   ├── controllers/
│   ├── services/
│   ├── models/
│   ├── utils/
│   └── main.py
├── ai_models/
│   ├── damage_detection/
│   ├── severity_analysis/
│   └── chatbot/
├── requirements.txt
├── .env
└── README.md
```

---

## ✨ Features

- AI-Based Vehicle Damage Detection  
- Repair Cost Estimation  
- Emergency Detection & Alerts  
- NLP-Based Roadside Assistance Chatbot  
- Secure Cloud Data Storage  

---

## 🔮 Upcoming Features

- Automated AI model retraining  
- Insurance system integration  
- Multi-language chatbot support  

---

## 🤝 Contributing

Contributions are welcome. Please submit pull requests for improvements or bug fixes.

