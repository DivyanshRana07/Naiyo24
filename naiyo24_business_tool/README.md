# Naiyo24 Business Tool: Flutter Frontend Client

A responsive, high-performance Flutter Web and Mobile client application for the **Naiyo24** business suite. It is designed to consume the FastAPI backend endpoints, manage application state seamlessly using **Riverpod**, and provide a visually premium Dark/Light mode UI layout.

---

## 🎨 Tech Stack & Dependencies

- **Flutter SDK**: Stable channel configuration
- **State Management**: `flutter_riverpod` + Notifier model
- **Routing**: `go_router` for deep-link paths and page routing
- **HTTP Client**: `dio` with modular API routing configuration
- **Local Storage**: `shared_preferences` for quick auth-state caching
- **Aesthetic UI Icons**: Modern Cupertino & Material icon packs

---

## 📂 Project Structure

```text
lib/
├── api_services/         # Remote API service interface layers
│   ├── api_client.dart   # Shared Dio instance configuration
│   ├── api_routes.dart   # All API endpoint routes definition
│   └── services/         # Sub-services (Invoice, Customer, Lead, PO, etc.)
├── models/               # JSON-serializable Dart data models
├── notifiers/            # Riverpod state managers (holds app business state)
├── providers/            # App providers (auth, shared_preferences, etc.)
├── routes/               # GoRouter paths & authorization redirect middleware
├── screens/              # UI Screen View components
├── theme/                # Custom dark/light mode styles (AppColors, spacing, text styles)
└── widgets/              # Reusable widget components grouped by feature area
```

---

## 🚀 Getting Started

### 📋 Prerequisites
Ensure the Flutter SDK is installed and configured on your path:
```bash
flutter doctor
```

### 1. Configure the API Endpoint URL
Open [`lib/api_services/api_routes.dart`](file:///c:/Users/NITRO/Desktop/Final/Naiyo24/naiyo24_business_tool/lib/api_services/api_routes.dart) and configure the `baseUrl` matching your running FastAPI backend server (default is `http://localhost:8000/api/v1`).

### 2. Fetch Dependencies
Run the command below from the frontend directory:
```bash
flutter pub get
```

### 3. Run the Application
Start the Flutter app on Chrome (Web dev browser):
```bash
flutter run -d chrome
```

For production builds (e.g. static host packaging):
```bash
flutter build web --release
```
