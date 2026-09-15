# TheOne — Shared Core Integration Contracts

## Core Evidence Model
All modules must emit sensor observations as `Evidence` objects:

```dart
Evidence(
  source: EvidenceSource.camera / microphone / ocr / speech / soundClassification,
  type: EvidenceType.ocr / object / obstacle / speech / sound / speaker / tone / translation,
  value: "Extracted Text or Label",
  confidence: 0.95, // 0.0 to 1.0
)
```

## Zero-Assumption Verification Engine
Bundle all observations into an `EvidenceBundle` and verify against user query:

```dart
final engine = ZeroAssumptionEngine();
final result = engine.verify(query: userQuery, bundle: bundle);
// Returns VerificationResult with state: verified | uncertain | insufficient | conflict
```

## Shared Service Contracts (Implementations in `lib/core/services/impl/`)
- `TtsService`: Spoken responses (`speak(text)`)
- `HapticService`: Vibration language (`verified()`, `uncertain()`, `conflict()`, `warning()`)
- `OcrService`: ML Kit local OCR (`extractText(image)`)
- `SpeechInputService`: Local STT listening (`listen()`)
- `SessionStorage`: SQLite session store (`saveEvidence()`, `clearSession()`)
