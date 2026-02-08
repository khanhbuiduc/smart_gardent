# 🌱 Smart Garden IoT System

A comprehensive IoT-based smart garden monitoring and automation system built with Flutter and Arduino. This project enables real-time monitoring of environmental conditions and automated plant care through a mobile application connected to hardware sensors via Bluetooth.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)
![Firebase](https://img.shields.io/badge/Firebase-enabled-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [System Architecture](#system-architecture)
- [Tech Stack](#tech-stack)
- [Screenshots](#screenshots)
- [Hardware Requirements](#hardware-requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Data Analytics](#data-analytics)
- [Contributing](#contributing)
- [License](#license)

## 🎯 Overview

The Smart Garden IoT System is a mobile application that bridges the gap between modern IoT technology and traditional gardening. It provides automated irrigation, environmental monitoring, and animal intrusion detection, all controllable from your smartphone.

### Key Highlights

- **Real-time Monitoring**: Track temperature, humidity, soil moisture, and proximity sensors
- **Automated Irrigation**: Smart water pump control based on soil moisture thresholds
- **Animal Detection**: Ultrasonic distance sensor with buzzer alerts for pest deterrence
- **Cloud Data Storage**: Historical data stored in Firebase for trend analysis
- **Data Visualization**: Interactive charts showing 24-hour and weekly trends
- **Dual Control Modes**: Automatic and manual operation modes

## ✨ Features

### 🌡️ Environmental Monitoring

- **Temperature Sensing**: DHT11/DHT22 sensor for ambient temperature
- **Air Humidity**: Real-time atmospheric humidity measurement
- **Soil Moisture**: Capacitive soil moisture sensor for accurate readings
- **Distance Detection**: Ultrasonic sensor for animal/object proximity

### 💧 Automated Irrigation

- **Smart Watering**: Automatic pump activation when soil moisture drops below threshold
- **Threshold Configuration**: Adjustable moisture thresholds (0-100%)
- **Manual Override**: Manual pump control in manual mode
- **Pump Status Monitoring**: Real-time pump state visualization

### 🔔 Alert System

- **Animal Intrusion Alerts**: Buzzer activation when objects detected within configured distance
- **Distance Threshold Control**: Adjustable detection range (5-100 cm)
- **Manual Buzzer Control**: Test and control buzzer manually

### 📊 Data Analytics

- **24-Hour Trends**: Line charts showing hourly sensor data
- **Weekly Averages**: Bar charts displaying daily average values
- **Historical Data**: All sensor readings stored in Firebase Firestore
- **Export Capability**: Data accessible through Firebase console

### 🎮 Control Interface

- **Bluetooth Connectivity**: HC-05 Bluetooth module for wireless communication
- **Device Scanning**: Automatic discovery of nearby HC-05 devices
- **Mode Switching**: Toggle between automatic and manual control modes
- **Real-time Updates**: Instant sensor data updates via Bluetooth

## 🏗️ System Architecture

```
┌─────────────────┐
│  Flutter Mobile │
│   Application   │
└────────┬────────┘
         │ Bluetooth HC-05
         ▼
┌─────────────────┐
│     Arduino     │
│   Microcontroller │
└────────┬────────┘
         │
    ┌────┴────┬────────┬──────────┐
    ▼         ▼        ▼          ▼
┌────────┐ ┌────┐ ┌──────┐ ┌──────────┐
│DHT Sensor│ │Soil│ │Ultra-│ │  Relay   │
│          │ │Moist│ │sonic │ │  Modules │
└──────────┘ └────┘ └──────┘ └──────────┘
                                    │
                          ┌─────────┴────────┐
                          ▼                  ▼
                      ┌──────┐          ┌──────┐
                      │ Pump │          │Buzzer│
                      └──────┘          └──────┘
```

**Data Flow:**
```
Sensors → Arduino → Bluetooth → Flutter App → Firebase Firestore
                                      ↓
                                  Local UI Update
                                      ↓
                                  User Controls
                                      ↓
                                  Bluetooth → Arduino → Actuators
```

## 🛠️ Tech Stack

### Mobile Application

| Technology | Version | Purpose |
|-----------|---------|---------|
| **Flutter** | 3.0+ | Cross-platform mobile framework |
| **Dart** | 3.0+ | Programming language |
| **Material Design 3** | Latest | UI/UX design system |

### Backend & Cloud Services

| Service | Purpose |
|---------|---------|
| **Firebase Core** | Firebase initialization |
| **Cloud Firestore** | NoSQL database for sensor data storage |
| **Firebase Authentication** | User authentication (future feature) |
| **Firebase Analytics** | Usage analytics and tracking |

### Key Dependencies

```yaml
dependencies:
  flutter_bluetooth_serial: ^0.4.0      # Bluetooth HC-05 communication
  cloud_firestore: ^4.8.0               # Cloud database
  firebase_core: ^2.15.0                # Firebase initialization
  firebase_analytics: ^10.10.7          # Analytics
  fl_chart: ^0.63.0                     # Data visualization
  permission_handler: ^10.0.0           # Android permissions
  intl: ^0.18.0                         # Date/time formatting
```

### Hardware Components

- **Microcontroller**: Arduino Uno/Nano/Mega
- **Bluetooth Module**: HC-05 or HC-06
- **Temperature/Humidity Sensor**: DHT11 or DHT22
- **Soil Moisture Sensor**: Capacitive or Resistive
- **Distance Sensor**: HC-SR04 Ultrasonic
- **Water Pump**: 5V/12V DC pump with relay
- **Buzzer**: Active or passive buzzer
- **Relay Modules**: 2-channel relay board
- **Power Supply**: 5V/12V adapter

## 📱 Screenshots

```
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Bluetooth  │  │   Dashboard  │  │   Analytics  │
│   Scanning   │  │   Real-time  │  │    Charts    │
│              │  │   Monitoring │  │              │
└──────────────┘  └──────────────┘  └──────────────┘
```

## 🔧 Hardware Requirements

### Minimum Requirements

- Arduino-compatible board (Uno, Nano, Mega)
- HC-05 Bluetooth module
- DHT11/DHT22 sensor
- Soil moisture sensor
- HC-SR04 ultrasonic sensor
- 2-channel relay module
- 5V water pump
- Buzzer
- Connecting wires
- Power supply (5V/12V)

### Optional Components

- LCD display for standalone operation
- SD card module for offline data logging
- RTC module for accurate timestamps
- Additional sensors (light, pH, etc.)

## 📦 Installation

### Prerequisites

1. **Flutter SDK**: Install Flutter 3.0 or higher
   ```bash
   flutter --version
   ```

2. **Android Studio** or **VS Code** with Flutter extensions

3. **Git**: For cloning the repository
   ```bash
   git --version
   ```

### Step 1: Clone the Repository

```bash
git clone https://github.com/khanhbuiduc/smart_gardent.git
cd smart_gardent
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Configure Firebase

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android app to your Firebase project
3. Download `google-services.json` and place it in `android/app/`
4. Update `lib/firebase_options.dart` with your Firebase configuration

### Step 4: Configure Bluetooth Device

Update the device address in `lib/screens/bluetooth_app.dart`:

```dart
final String _specificDeviceAddress = 'XX:XX:XX:XX:XX:XX'; // Your HC-05 MAC address
final String _specificDeviceName = 'SMART_GARDEN';
```

### Step 5: Build and Run

```bash
# For Android
flutter run

# Or build APK
flutter build apk --release
```

## ⚙️ Configuration

### Bluetooth Setup

1. Pair your HC-05 module with your phone via Settings → Bluetooth
2. Note the MAC address of your HC-05 module
3. Update the `_specificDeviceAddress` in the app code

### Firebase Configuration

The project uses Firebase for cloud data storage. Update `firebase_options.dart` with your credentials:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_STORAGE_BUCKET',
);
```

### Arduino Configuration

Upload the Arduino sketch (not included in this repository) that:
- Reads sensor data from DHT, soil moisture, and ultrasonic sensors
- Sends JSON-formatted data via Bluetooth
- Receives control commands from the Flutter app

**Expected JSON Format:**
```json
{
  "temp": 25.5,
  "humidity": 65.0,
  "soil": 45.0,
  "distance": 15.0,
  "pump": "ON",
  "buzzer": "OFF",
  "mode": "Auto",
  "moisture_threshold": 30,
  "distance_threshold": 20
}
```

## 🚀 Usage

### Initial Setup

1. **Power on Arduino** with all sensors connected
2. **Launch the app** on your Android device
3. **Grant permissions** when prompted (Bluetooth, Location)
4. **Scan for devices** using the "Scan HC-05 Devices" button
5. **Connect** to your HC-05 module

### Daily Operation

#### Automatic Mode (Recommended)

1. Set **moisture threshold** (e.g., 30% - pump activates below this)
2. Set **distance threshold** (e.g., 20cm - buzzer activates when closer)
3. Toggle **Automatic Mode** ON
4. System will automatically:
   - Water plants when soil is dry
   - Sound buzzer when animals detected

#### Manual Mode

1. Toggle **Manual Mode** ON
2. Manually control:
   - Water pump ON/OFF
   - Buzzer ON/OFF
3. Thresholds are ignored in manual mode

### Viewing Analytics

1. Tap **Analytics icon** in the app bar
2. View **24-hour trends** (line charts)
3. Switch to **Weekly Averages** tab (bar charts)
4. Pull down to **refresh** data

## 📂 Project Structure

```
smart_gardent/
├── lib/
│   ├── main.dart                      # App entry point
│   ├── firebase_options.dart          # Firebase configuration
│   │
│   ├── models/
│   │   └── garden_data.dart           # Data model for sensor values
│   │
│   ├── screens/
│   │   ├── bluetooth_app.dart         # Main dashboard screen
│   │   └── analytics_screen.dart      # Data visualization screen
│   │
│   ├── services/
│   │   ├── bluetooth_service.dart     # Bluetooth communication logic
│   │   └── firebase_service.dart      # Firestore operations
│   │
│   └── widgets/
│       ├── sensor_card.dart           # Reusable sensor display widget
│       └── control_widget.dart        # Reusable control widget
│
├── android/                           # Android-specific files
├── ios/                               # iOS-specific files
├── assets/
│   └── images/                        # App images
├── pubspec.yaml                       # Dependencies configuration
└── README.md                          # This file
```

### Key Files Description

| File | Description |
|------|-------------|
| `main.dart` | Initializes Firebase and launches the app |
| `bluetooth_app.dart` | Main UI with sensor data and controls |
| `analytics_screen.dart` | Data visualization with charts |
| `bluetooth_service.dart` | Handles Bluetooth scanning, connection, and data transmission |
| `firebase_service.dart` | Manages Firestore data storage and retrieval |
| `garden_data.dart` | Data model for parsing Arduino JSON data |

## 📊 Data Analytics

### 24-Hour View

- **Temperature Chart**: Line graph showing hourly temperature changes
- **Air Humidity Chart**: Humidity trends over 24 hours
- **Soil Moisture Chart**: Track watering effectiveness

### Weekly View

- **Average Temperature**: Daily average temperatures (bar chart)
- **Average Humidity**: Weekly humidity patterns
- **Average Soil Moisture**: Watering frequency insights

### Data Storage

- Data is saved to Firebase every **5 minutes** while connected
- Queryable through Firebase Console
- Automatic cleanup can be configured with Cloud Functions

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/AmazingFeature
   ```
3. **Commit your changes**
   ```bash
   git commit -m 'Add some AmazingFeature'
   ```
4. **Push to the branch**
   ```bash
   git push origin feature/AmazingFeature
   ```
5. **Open a Pull Request**

### Development Guidelines

- Follow Flutter/Dart style guide
- Write meaningful commit messages
- Add comments for complex logic
- Test on physical devices
- Update documentation as needed

## 🐛 Known Issues

- Bluetooth connection may occasionally drop (reconnection required)
- iOS support not yet implemented (Bluetooth Serial limitation)
- Large data queries may be slow (consider pagination)

## 🔮 Future Enhancements

- [ ] iOS support with alternative Bluetooth library
- [ ] User authentication and multi-user support
- [ ] Push notifications for critical alerts
- [ ] Weather API integration
- [ ] Plant database with care recommendations
- [ ] Voice control integration
- [ ] Multi-language support
- [ ] Dark mode theme
- [ ] Data export to CSV/Excel

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Khanh Bui Duc**
- GitHub: [@khanhbuiduc](https://github.com/khanhbuiduc)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend infrastructure
- Arduino community for hardware inspiration
- fl_chart library for beautiful visualizations

## 📞 Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Contact: [Your Email]

---

**⭐ If you find this project helpful, please give it a star!**

Made with ❤️ and Flutter
