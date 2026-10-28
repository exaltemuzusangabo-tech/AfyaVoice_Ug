# 🎙️ AfyaVoice — Voice-First AI Maternal Triage & Tele-Diagnostics

![License](https://img.shields.io/badge/License-MIT-green.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Gemini 1.5 Flash](https://img.shields.io/badge/Google%20Gemini-1.5%20Flash-4285F4?logo=google)
![SDG Alignment](https://img.shields.io/badge/UN%20SDGs-3%20%7C%205%20%7C%2010-E5243B)

**AfyaVoice** is an edge-resilient, voice-first AI maternal health triage and referral application designed to mitigate the **Three-Delay Obstetric Crisis** across East Africa (Uganda, Kenya, Tanzania). 

By synthesizing **multilingual voice processing (Luganda/Swahili/English)**, a **deterministic WHO-aligned danger sign override engine**, and **risk-weighted geospatial facility routing**, AfyaVoice provides rapid, reliable clinical decision support for expectant mothers and Community Health Workers (CHWs)—even under low-bandwidth and offline conditions.

---

## 📸 Key Features

- **🗣️ Voice-First Multilingual Triage:** Record symptom descriptions naturally in local dialects. Gemini 1.5 Flash parses unstructured speech into structured clinical JSON risk assessments.
- **🛡️ Deterministic WHO Safety Override:** Immediate local pattern-matching engine that detects high-risk obstetric danger signs (e.g., severe hemorrhage, eclampsia, high fever) and forces a `CRITICAL` alert—bypassing LLM API latency for critical emergencies.
- **📍 Risk-Weighted Facility Routing:** Integrated Google Maps Platform to identify nearby health centers (e.g., Health Center IV, Referral Hospitals), calculate distance, and provide turn-by-turn navigation & direct emergency calls.
- **📶 Offline Resilience:** Caches essential triage checklists, emergency phone numbers, and guidelines locally using `shared_preferences` for zero-bandwidth emergency operation.

---

## 🏗️ System Architecture

                   ┌───────────────────────────────────┐
                   │   UNSTRUCTURED VOICE / TEXT INPUT │
                   │    (Luganda / Swahili / English)  │
                   └───────────────────────────────────┘
                                     │
                                     ▼
                   ┌───────────────────────────────────┐
                   │ DETERMINISTIC DANGER SIGN ENGINE  │
                   │ (WHO / MoH Pattern Matcher Rules) │
                   └───────────────────────────────────┘
                               /           \
           [Danger Sign Found] /             \ [No Immediate Override]
                              ▼               ▼
        ┌───────────────────────────┐   ┌───────────────────────────┐
        │  IMMEDIATE SAFETY OVERRIDE│   │   GOOGLE GEMINI 1.5 FLASH │
        │  Level: CRITICAL / HIGH   │   │   Multimodal Voice-to-JSON│
        └───────────────────────────┘   └───────────────────────────┘
                              \               /
                               \             /
                                ▼           ▼
                   ┌───────────────────────────────────┐
                   │    STRUCTURED TRIAGE JSON SCHEMAS │
                   └───────────────────────────────────┘
                                     │
                                     ▼
                   ┌───────────────────────────────────┐
                   │ RISK-WEIGHTED FACILITY ROUTER     │
                   │ (Google Maps SDK + Geolocator)    │
                   └───────────────────────────────────┘

---

## 🛠️ Tech Stack & Dependencies

- **Frontend:** Flutter (Dart) with Material 3 Design
- **AI Engine:** Google Gemini 1.5 Flash API (`google_generative_ai`)
- **Maps & Geolocation:** `google_maps_flutter`, `geolocator`, `url_launcher`
- **Audio Processing:** `record`, `audioplayers`
- **Storage & State:** `shared_preferences`, `path_provider`
- **Build Target:** Android OS (Min SDK 21, Java 11 / Gradle 8.7 compatibility)

---

## 🚀 Getting Started & Local Setup

### Prerequisites
- Flutter SDK (>= 3.0.0)
- Android Studio / VS Code
- Google Gemini API Key ([Get it here](https://aistudio.google.com/))
- Google Maps API Key ([Google Cloud Console](https://console.cloud.google.com/))

### Installation Steps

1. **Clone the Repository**
   ```bash
   git clone [https://github.com/exaltemuzusangabo-tech/afyavoice.git](https://github.com/exaltemuzusangabo-tech/afyavoice.git)
   cd afyavoice
