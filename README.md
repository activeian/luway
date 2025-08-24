# LuWay - Global Car Search & Marketplace

LuWay is a Flutter mobile application that allows users to search for vehicles by license plate number, contact vehicle owners, create a personal garage, and list vehicles in a marketplace.

## Features

### 🏠 Home Screen
- Universal search by license plate number
- Quick actions (Add Car, Browse Marketplace)
- User statistics and recommendations
- Guest mode with limited features

### 🛒 Marketplace
- Browse cars, accessories, and services
- Filter and search functionality
- Promoted listings
- Star ratings and views counter
- Contact sellers directly

### ➕ Add New Items
- Add cars to personal garage
- Add accessories and services (Premium subscription required)
- Country selection with flags
- License plate validation
- Image upload support

### 💬 Chat System
- Direct messaging between users
- Guest chat mode (temporary, not saved)
- Push notifications support
- License plate-based conversations

### 👤 Profile Management
- User account management
- My Garage (personal vehicles)
- Subscription management (Basic/Premium/Pro)
- Analytics and statistics
- Multi-language support

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── splash_screen.dart        # Initial loading screen
├── login_screen.dart         # Authentication
├── home_screen.dart          # Main navigation with tabs
├── marketplace_screen.dart   # Marketplace listings
├── add_screen.dart          # Add new items
├── chat_screen.dart         # Messaging system
├── profile_screen.dart      # User profile & settings
│
├── components/              # Reusable UI components
│   ├── search_bar.dart
│   ├── vehicle_card.dart
│   └── modal_subscribe.dart
│
├── models/                  # Data models
│   └── vehicle_model.dart
│
└── services/               # Business logic
    ├── firebase_service.dart
    └── api_service.dart
```

## Technologies Used

- **Flutter SDK** (>=3.2.0)
- **Firebase** (Auth, Firestore, Storage, Messaging, Analytics)
- **GetX** - State management
- **ScreenUtil** - Responsive design
- **Hive** - Local storage
- **Country Picker** - Country selection
- **Google Sign-In** - Authentication
- **Image Picker** - Photo uploads

## Subscription Plans

### 🆓 Basic (Free)
- Add cars to garage
- Search vehicles
- Basic chat features

### 💎 Premium (€3.99/month)
- Everything in Basic
- Add accessories & services
- Advanced analytics
- Priority support

### ⭐ Pro (€7.99/month)
- Everything in Premium
- Free promotion (1x/month)
- Advanced marketing tools
- Business insights

## Setup Instructions

### Prerequisites
1. Flutter SDK (>=3.2.0)
2. Android Studio / VS Code
3. Firebase project setup
4. Android/iOS development environment

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd luway
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project at https://console.firebase.google.com
   - Add Android/iOS app to your project
   - Download `google-services.json` (Android) and place in `android/app/`
   - Download `GoogleService-Info.plist` (iOS) and place in `ios/Runner/`
   - Run Firebase CLI to generate firebase_options.dart:
     ```bash
     flutterfire configure
     ```

4. **Enable Firebase Services**
   - Authentication (Email/Password, Google)
   - Cloud Firestore
   - Firebase Storage
   - Firebase Messaging
   - Firebase Analytics

5. **Configure Android**
   - Update `android/app/build.gradle` with your signing configuration
   - Add required permissions in `android/app/src/main/AndroidManifest.xml`

6. **Run the application**
   ```bash
   flutter run
   ```

### Build for Production

1. **Android APK**
   ```bash
   flutter build apk --release
   ```

2. **Android AAB (for Play Store)**
   ```bash
   flutter build appbundle --release
   ```

3. **iOS**
   ```bash
   flutter build ios --release
   ```

## Configuration

### Environment Variables
Create a `.env` file in the root directory:
```
UPLOAD_ENDPOINT=https://wzsgame.com/upload.php
API_BASE_URL=your-api-base-url
STRIPE_PUBLISHABLE_KEY=your-stripe-key
```

### Firebase Collections Structure

#### Users Collection (`users`)
```json
{
  "uid": "string",
  "email": "string",
  "displayName": "string",
  "photoURL": "string",
  "subscription": "basic|premium|pro",
  "fcmToken": "string",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

#### Vehicles Collection (`vehicles`)
```json
{
  "make": "string",
  "model": "string",
  "year": "string",
  "licensePlate": "string",
  "countryCode": "string",
  "countryFlag": "string",
  "ownerId": "string",
  "ownerName": "string",
  "price": "string",
  "images": ["string"],
  "views": "number",
  "rating": "number",
  "isActive": "boolean",
  "isForSale": "boolean",
  "createdAt": "timestamp"
}
```

#### Chats Collection (`chats`)
```json
{
  "vehicleId": "string",
  "participants": ["string"],
  "isGuestChat": "boolean",
  "lastMessage": "string",
  "lastMessageTime": "timestamp",
  "createdAt": "timestamp"
}
```

## Navigation Structure

The app uses a simplified navigation approach with `Navigator.push()` and `MaterialPageRoute` instead of complex routing packages:

1. **SplashScreen** → Checks auth status
2. **LoginScreen** → Authentication (if not logged in)
3. **HomeScreen** → Main app with bottom navigation tabs:
   - Home Tab (search, recommendations)
   - Marketplace Tab (browse listings)
   - Add Tab (add new items)
   - Chat Tab (messages)
   - Profile Tab (account management)

## Key Features Implementation

### Universal Search
- Search vehicles by license plate number
- Country-specific format validation
- Real-time suggestions
- Guest access supported

### Chat System
- Firebase-based real-time messaging
- Guest mode for temporary conversations
- Push notifications via FCM
- File/image sharing support

### Subscription Management
- In-app purchases integration
- Feature gating based on subscription level
- Stripe payment processing
- Google Play billing support

### Image Upload
- Custom upload endpoint integration
- Automatic image compression
- Multiple image support
- Progress tracking

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Email: support@luway.app
- Documentation: https://docs.luway.app
- Issues: GitHub Issues page

## Roadmap

- [ ] iOS app development
- [ ] Web platform support
- [ ] Advanced filtering options
- [ ] Multi-language support
- [ ] Offline mode support
- [ ] Advanced analytics dashboard
- [ ] Business API endpoints
- [ ] White-label solutions
