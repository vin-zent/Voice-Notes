# 🎙️ Voice Note Recorder & Player (SwiftUI)

A lightweight Voice Notes application built with **SwiftUI**, **Combine**, and **AVFoundation** that allows users to:

* Record audio notes
* Pause and resume recordings
* Visualize microphone input with a live animated waveform
* Play recorded audio files
* Seek through recordings
* Manage saved voice notes

---

# 📱 Features

## 🎤 Audio Recording

* Start recording voice notes
* Pause and resume recording
* Cancel recording and discard audio
* Stop recording and save audio
* Automatic microphone permission handling

---

## 🌊 Live Waveform Visualization

* Real-time microphone level monitoring
* Animated sine-wave waveform
* Smooth amplitude and phase transitions
* Audio-reactive visual feedback

---

## ▶️ Audio Playback

* Play recorded audio files
* Pause playback
* Seek to any position
* Track playback progress
* Display current playback time

---

## 📂 Recording Management

* Store recordings locally
* Auto-generate timestamp-based filenames
* Load existing recordings
* Delete recordings
* Sort recordings by latest first

---

## ⚡ Modern Architecture

* SwiftUI UI Layer
* MVVM Architecture
* Combine-based timers and state management
* AVFoundation for audio recording and playback

---

# 🏗️ Architecture

```text
VoiceNoteRecorderPlayer
│
├── View
│   ├── Recording Screen
│   ├── Waveform View
│   └── Playback Controls
│
├── ViewModel
│   └── VNRecorderAndPlayerViewModel
│
└── Services
    ├── AVAudioRecorder
    └── AVAudioPlayer
```

---

# 📦 Requirements

| Requirement | Version |
| ----------- | ------- |
| iOS         | 15.0+   |
| Swift       | 5.9+    |
| Xcode       | 15+     |

---

# 🚀 Setup Instructions

## 1. Clone Repository

```bash
git clone https://github.com/your-username/VoiceNoteRecorderPlayer.git
```

## 2. Open Project

```bash
cd VoiceNoteRecorderPlayer
open VoiceNoteRecorderPlayer.xcodeproj
```

Or open the project manually using Xcode.

---

## 3. Configure Microphone Permission

Add the following key to **Info.plist**:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app requires microphone access to record voice notes.</string>
```

---

## 4. Build & Run

1. Select an iOS Simulator or physical device.
2. Press **⌘ + R**
3. Grant microphone permission when prompted.

> **Note:** Recording functionality works best on a physical device.

---

# 🎤 Recording Flow

## Start Recording

```swift
viewModel.startRecoding()
```

## Pause / Resume Recording

```swift
viewModel.toggleRecodingPause()
```

## Stop Recording

```swift
viewModel.stopRecoding()
```

## Cancel Recording

```swift
viewModel.cancelRecoding()
```

---

# ▶️ Playback Flow

## Play Recording

```swift
viewModel.playPlayer(recordingURL)
```

## Pause Playback

```swift
viewModel.pausePlayer()
```

## Stop Playback

```swift
viewModel.stopPlayer()
```

## Seek Playback

```swift
viewModel.seekPlayer(to: 0.5)
```

Example:

```swift
// Seek to 50% of audio duration
viewModel.seekPlayer(to: 0.5)
```

---

# 🌊 Waveform Visualization

The project includes a custom SwiftUI Shape:

```swift
struct VNWaveView: Shape
```

### Features

* Mathematical sine-wave rendering
* Live amplitude updates from microphone input
* Animated horizontal movement
* Smooth interpolation using `AnimatablePair`

The waveform reacts in real time to microphone volume levels captured from `AVAudioRecorder`.

---

# 💾 Storage

Recordings are stored in:

```text
Application Support/
└── Recordings/
    ├── Voicenote_2026-06-19T18-30-22.m4a
    ├── Voicenote_2026-06-19T18-35-41.m4a
    └── ...
```

Files are saved using the format:

```text
Voicenote_<timestamp>.m4a
```

---

# 🔧 Technologies Used

* SwiftUI
* Combine
* AVFoundation
* MVVM
* Timer Publishers
* FileManager

---

# 📸 Future Enhancements

* Background recording support
* Audio session interruption handling
* Recording rename feature
* Share recordings
* Cloud backup support
* Multiple waveform styles
* Recording duration limit
* Voice transcription using Speech Framework

---

# 🤝 Contributing

Contributions, feature requests, and bug reports are welcome.

### 1. Fork the Repository

### 2. Create a Feature Branch

```bash
git checkout -b feature/new-feature
```

### 3. Commit Changes

```bash
git commit -m "Add new feature"
```

### 4. Push Branch

```bash
git push origin feature/new-feature
```

### 5. Open a Pull Request

---

# 📄 License

This project is available under the **MIT License**.

---

# 👨‍💻 Author

Built with **SwiftUI**, **Combine**, and **AVFoundation** as a modern voice recording and playback solution for iOS.
