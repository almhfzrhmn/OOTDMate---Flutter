# OOTDMate - Smart Virtual Wardrobe (Frontend)

OOTDMate is an intelligent virtual wardrobe application designed to help users manage their clothing collections and generate Outfit of the Day (OOTD) recommendations using visual similarity-based AI.

This repository contains the **Frontend** of the OOTDMate ecosystem, built with Flutter. It seamlessly integrates with a FastAPI backend powered by a MobileNetV2 deep learning model for cross-category semantic similarity processing.

---

## 🚀 Features

- **Intuitive Wardrobe Management**: Seamlessly add, view, edit, and delete clothing items. Includes high-resolution image support, personal annotations, and AI-generated confidence scores from auto-tagging.
- **Insights Dashboard**: A comprehensive home screen featuring a custom interactive Wardrobe Donut Chart and statistical breakdowns of the user's clothing composition.
- **AI-Powered OOTD Matcher**:
  - **Anchor-Based Selection**: Users select a single "anchor" item.
  - **Cross-Category Similarity**: The system queries the backend to find the best visually compatible items from other categories (e.g., matching a selected top with bottoms and footwear).
  - **Compatibility Metrics**: Real-time display of the outfit's similarity score (Confidence/Compatibility Percentage).
  - **Instant Local Shuffle**: Cycle through Top-K alternative recommendations instantly with zero network latency.
- **Saved Outfits (Favorites)**: Persist generated outfit combinations to a dedicated favorites board for future reference and easy management.
- **Modern Cyberpunk Aesthetic**: A meticulously crafted dark-mode UI utilizing a design system based on Acid Green, Neon Blue, and Glitch Magenta accents with glassmorphism elements.

---

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Architecture Pattern**: MVCS (Model-View-Controller-Service) / Feature-first structure
- **Networking**: [Dio](https://pub.dev/packages/dio) with custom interceptors for robust error handling and automated JWT injection.
- **State Management**: Stateful component architecture optimized for minimal rebuilds.
- **UI/UX**: Custom painting (`CustomPainter`) and theme tokenization (`AppTheme`).

---

## 📂 Project Structure

```text
lib/
├── core/
│   ├── constants/        # API configurations, Base URLs, and Dio Client
│   ├── theme/            # Centralized Design System (Colors, Typography, Styles)
│   └── utils/            # Helper classes and formatting utilities
├── models/               # Data Transfer Objects (DTOs) and entity models
├── screens/
│   ├── auth/             # Authentication screens (Login, Register)
│   └── core/             # Main application features
│       ├── home/         # Insights Dashboard
│       ├── wardrobes/    # Wardrobe inventory and item details
│       ├── recommendation/ # AI OOTD Matcher Engine
│       └── favorite/     # Saved Outfits Management
├── services/
│   ├── api-services/     # HTTP communication layers for business logic
│   └── auth-services/    # Session management and credential storage
└── widgets/              # Reusable UI components (NavBars, Cards, Charts)
```

---

## ⚙️ Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Version 3.19.0 or higher recommended)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- A running instance of the **OOTDMate Backend**

### Installation & Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/ootdmate_frontend.git
   cd ootdmate_frontend
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Environment / Base URL**
   Locate `lib/core/constants/dio_client.dart` and update the `baseUrl` to point to your backend instance. If running on a physical device, use your machine's local IPv4 address instead of `localhost`.

4. **Run the application**
   ```bash
   flutter run
   ```

---

## 📐 UI/UX Design Guidelines

Contributors must adhere to the established design system found in `lib/core/theme/app_theme.dart`:
- **Backgrounds**: Utilize `AppTheme.primary` (Main background) and `AppTheme.secondary` (Cards/Containers).
- **Primary Actions**: Use `AppTheme.acidGreen` for positive actions and primary CTAs.
- **Secondary Actions & Feedback**: Use `AppTheme.neonBlue` or `AppTheme.glitchMagenta` for status indicators, loading pulses, and secondary accents.
- **Component Styling**: Prioritize subtle translucent borders and rounded corners (16px) over heavy drop shadows to maintain the modern/cyberpunk aesthetic.

---

## 📄 License

This project is proprietary and developed as part of an academic thesis. Unauthorized copying, modification, or distribution is strictly prohibited unless explicitly stated otherwise.
