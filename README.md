# 👁️ TheOne — Offline Evidence-First Multimodal Accessibility Assistant

> **"Accessibility AI should not invent the world for its users."**

**TheOne** is a 100% offline, edge-AI accessibility assistant for Android built for **Sustainverse 2K26 (PS-04)**. It bridges Vision, Hearing, and Communication needs for Blind, Deaf, and Non-Speaking users using a deterministic, explainable **Zero-Assumption Engine**.

---

## 🎯 Core Pitch & Problem Statement

Most accessibility AI applications rely on cloud LLMs (like GPT-4 Vision) that hallucinate when sensor data is weak. For a visually impaired or deaf person, an AI guessing a room number, an obstacle, or an alarm is dangerous.

**TheOne solves this by enforcing a Zero-Assumption Architecture:**
- **No Internet Required:** Runs 100% locally on Android hardware (TensorFlow Lite, Google ML Kit, native STT/TTS).
- **No Invented Reality:** Every answer is grounded in verifiable sensor evidence.
- **Conflict Resolution:** If two sensors disagree (e.g., Camera OCR reads `ROOM 204` vs Audio reads `ROOM 302`), it halts and explicitly reports a **Conflict** instead of guessing.

---

## 🏗️ System Architecture

```
                  USER QUERY / SENSOR INPUT
                              │
     ┌────────────────────────┼────────────────────────┐
     ▼                        ▼                        ▼
CAMERA FRAME              MICROPHONE              TEXT INPUT
(Google ML Kit OCR / (Streaming STT / (Code-Mixed
ML Kit Objects) Audio Danger Listener) Tamil-English)
│ │ │
└────────────────────────┼────────────────────────┘
▼
STRUCTURED EVIDENCE
{ source, type, value, confidence, timestamp }
│
▼
RELEVANCE ENGINE
(Tamil + English Keyword Ranking)
│
▼
ZERO-ASSUMPTION ENGINE
(Verified / Uncertain / Insufficient / Conflict)
│
┌────────────────────────┼────────────────────────┐
▼ ▼ ▼
HIGH-CONTRAST UI ON-DEVICE TTS HAPTIC VIBRATION
(Evidence Cards) (Android Speech) (Custom Vibration Language)
```
---

## ⚡ Zero-Assumption Verification Matrix

| State | Evidence Condition | App Response | Haptic Feedback |
|---|---|---|---|
| 🟢 **VERIFIED** | Confidence $\ge 80\%$ | Direct verified answer | 1 Short Pulse |
| 🟡 **UNCERTAIN** | Confidence $50\% - 79\%$ | States uncertainty explicitly | 2 Short Pulses |
| 🔴 **INSUFFICIENT** | Confidence $< 50\%$ | *"I can't verify that. Please scan again."* | Long Warning Pulse |
| ⚪ **CONFLICT** | Sources disagree | *"Conflicting information: 204 vs 302."* | 3 Rapid Pulses |

---

## 📱 Feature Matrix

### 👁️ 1. Vision Assist (Blind / Low Vision)
- **Live Camera Scanning:** On-device OCR reads signs, room numbers, and notices.
- **Auto Low-Light Torch:** Automatically toggles camera LED flash when darkness ($< 55\%$ brightness) is detected.
- **Obstacle Awareness:** Real-time bounding-box proximity scoring with variable vibration alerts.
- **Flagship Room Verification Demo:** Interactive verification flow testing Room 204 (Verified) vs Room 204/302 (Conflict).

### 🎧 2. Hearing Assist (Deaf / Hard of Hearing)
- **Streaming Live Captions:** Real-time spoken speech transcription with auto-scrolling caption cards.
- **Low-Confidence Badging:** Words transcribed below 70% confidence are visually flagged with an amber warning badge.
- **Speaker Tracker:** Automatically tags and color-codes alternating speakers (*Speaker 1*, *Speaker 2*).
- **Emotional Tone Classifier:** Classifies caption lines as *Neutral*, *Friendly*, or *Urgent*.
- **Ambient Danger Listener:** Detects sudden loud sounds or danger words (*"Stop!"*, *"Help!"*) and triggers an emergency full-screen banner + alert vibration.

### 🗣️ 3. Communication Assist (Non-Speaking / Mute)
- **Quick Phrase Categories:** Categorized tappable chips (*Greetings*, *Café/Food*, *Emergency*, *Custom*) with instant Tap-to-Speak TTS.
- **Situational Camera Photo Assist:** Point camera at a café menu or notice board $\rightarrow$ extracts OCR text $\rightarrow$ auto-surfaces contextual phrase suggestions (*"Order Hot Chai"*, *"Ask Price"*).
- **Code-Mixed Intent Transformer:** Restructures fragmented Tamil/English input (e.g., *"registration enga irukku nu kekkanum"*) into polite spoken sentences (*"Excuse me, could you please tell me where the registration desk is located?"*).
- **Capture Speaker Reply:** Transcribes incoming spoken responses from vendors/people into large readable text.

### 🚨 4. Safety & Core
- **Auto-SOS Emergency Alert:** Monitors battery state and high-accuracy GPS coordinates; pre-fills an emergency Google Maps SMS ready to send.
- **Session-Only Storage:** SQLite local memory auto-clears on demand with zero cloud syncing for 100% privacy.

---

## 🛠️ Tech Stack

- **Framework:** Flutter 3.47 / Dart 3.13
- **Edge Vision:** Google ML Kit Text Recognition (`google_mlkit_text_recognition`), Google ML Kit Object Detection (`google_mlkit_object_detection`)
- **Speech & Audio:** Android Native Speech-to-Text (`speech_to_text`), Android Native Text-to-Speech (`flutter_tts`)
- **Sensors:** `camera`, `vibration`, `permission_handler`
- **Local Database:** SQLite (`sqflite`), `path_provider`
- **Safety:** `battery_plus`, `geolocator`, `url_launcher`

---

## 🚀 Building & Running

### Prerequisites
- Flutter SDK $\ge 3.10.0$
- Android SDK API Level 24+ (Android 7.0+)
- Physical Android Device with camera and microphone

### Run in Debug Mode
```bash
git clone https://github.com/NarenXO/TheOne.git
cd TheOne
flutter pub get
flutter run -d <your-device-id>
```

### Build Release APK
```bash
flutter build apk --release
```
Compiled APK location: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📜 License & Credits

Built for Sustainverse 2K26 Hackathon (PS-04 Accessibility Assistant).
Developer: Naren & Team (TheOne)
