# Nivaran - Civic Issue Reporting & Management App

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.x-blue.svg)](https://dart.dev)
[![License: Custom](https://img.shields.io/badge/License-Custom-blue.svg)](#license)

Nivaran is a Flutter-based mobile application designed to bridge the gap between citizens and local authorities by providing a platform for reporting, tracking, and resolving civic issues.

## Overview

Nivaran empowers citizens to report various local problems such as potholes, garbage dumping, street light outages, and more, directly from their mobile devices. These reports, enriched with details, images, and geo-location, are then accessible to concerned officials for timely acknowledgement and resolution. The app aims to foster transparency and efficiency in addressing public grievances.

## Features

1. **Secure User Authentication**: Multi-factor authentication with biometric support ensures robust security for user accounts. Users can sign up via email, social media, or phone verification, with automatic session management and secure password recovery options.

2. **AI-Powered Issue Categorization**: Leveraging advanced machine learning algorithms, the app automatically categorizes reported issues into predefined categories like infrastructure, sanitation, or public safety. This feature includes smart suggestions for issue resolution based on historical data and similar cases.

3. **Real-Time Collaboration Platform**: Citizens and officials can collaborate seamlessly on issue resolution through integrated live chat, document sharing, and progress tracking. This fosters transparent communication and accelerates problem-solving processes.

4. **Predictive Maintenance Alerts**: Using AI-driven analytics, the app predicts potential civic issues before they escalate. Based on patterns in reported data, users receive proactive alerts about areas prone to problems, enabling preventive measures.

5. **Offline Reporting Capability**: Full offline functionality allows users to capture and store issue reports without internet connectivity. Reports are automatically synchronized when connectivity is restored, ensuring no data loss in remote or low-signal areas.

6. **Integrated Map Visualization**: Interactive maps with customizable heatmaps display issue density, resolution status, and geographic trends. Users can zoom, filter, and overlay data layers for comprehensive spatial analysis of civic challenges.

7. **Community Impact Tracking**: Detailed dashboards provide analytics on community engagement, issue resolution rates, and overall impact. Citizens can view their contribution to local improvements, while officials track performance metrics and resource allocation.

8. **Multi-Language Support**: Comprehensive localization supports multiple languages, making the app accessible to diverse user groups. Voice commands, text input, and notifications are available in regional languages, promoting inclusivity and wider adoption.

## 📸 App Screenshots

Here’s an overview of the **Nivaran** app’s key screens and features:

| **Splash Screen** | **Public Dashboard** | **Officials Issue Dashboard** |
| --- | --- | --- |
| ![](assets/icon/1.jpg) | ![](assets/icon/2.jpg) | ![](assets/icon/3.jpg) |

| **Officials Statistics 1** | **Officials Statistics 2** | **Officials Alerts** |
| --- | --- | --- |
| ![](assets/icon/4-1.jpg) | ![](assets/icon/4-2.jpg) | ![](assets/icon/5.jpg) |

| **Officials Profile 1** | **Officials Profile 2** | **User Issue Dashboard** |
| --- | --- | --- |
| ![](assets/icon/6-1.jpg) | ![](assets/icon/6-2.jpg) | ![](assets/icon/7-1.jpg) |

| **AI Prediction** | **User Captures Image** | **Report an Issue** |
| --- | --- | --- |
| ![](assets/icon/7-2.jpg) | ![](assets/icon/8-1.jpg) | ![](assets/icon/8-2.jpg) |

| **Voice Reporting on Issue** | **Map View** | **Map Zoom & Marker** |
| --- | --- | --- |
| ![](assets/icon/8-3.jpg) | ![](assets/icon/9-1.jpg) | ![](assets/icon/9-2.jpg) |

| **User Alerts** | **User Profile** | **Comments** |
| --- | --- | --- |
| ![](assets/icon/10.jpg) | ![](assets/icon/11.jpg) | ![](assets/icon/12.jpg) |

### Detailed Screen Descriptions

1. **Splash Screen**: The initial loading screen displayed when the app launches, featuring the Nivaran logo prominently centered on a clean background. It likely includes a progress indicator or animation while the app initializes authentication, loads local data, and prepares the main interface. This screen sets the app's branding tone with a professional, civic-focused design.

2. **Public Dashboard**: The main home screen for public users, displaying a feed of reported civic issues in the local area. It shows issue cards with titles, categories (e.g., infrastructure, sanitation), status indicators (pending, in progress, resolved), and thumbnails of attached images. Includes navigation tabs for different views (all issues, nearby, trending) and a floating action button for quick reporting.

3. **Officials Issue Dashboard**: A comprehensive dashboard for government officials, showing all reported issues filtered by jurisdiction or department. Displays issue statistics, priority levels, and assignment status. Features include bulk actions for updating multiple issues, filtering by category or location, and quick access to detailed issue views for resolution tracking.

4. **Officials Statistics 1**: The first part of an analytics dashboard for officials, presenting key performance metrics through interactive charts and graphs. Likely includes bar charts showing issue resolution rates by category, pie charts for issue distribution, and line graphs tracking resolution times over periods. Uses the fl_chart package for visualization.

5. **Officials Statistics 2**: Continuation of the statistics dashboard, focusing on deeper analytics such as geographic heatmaps of issue density, trend analysis for recurring problems, and resource allocation metrics. May include comparative data between different time periods or regions, helping officials identify patterns and optimize response strategies.

6. **Officials Alerts**: A notification center for officials displaying urgent alerts about high-priority issues, system updates, or escalated complaints. Shows alert types (emergency, deadline approaching, public safety), timestamps, and direct links to affected issues. Includes filtering options and mark-as-read functionality for efficient alert management.

7. **Officials Profile 1**: The first section of an official's profile screen, displaying personal information, department affiliation, and contact details. Includes profile photo, name, role (e.g., municipal engineer), and jurisdiction area. May show basic statistics like issues handled and resolution rate.

8. **Officials Profile 2**: The second section of the official's profile, focusing on professional details and settings. Likely includes work history, specializations, notification preferences, and account security options. May also show recent activity or achievements in issue resolution.

9. **User Issue Dashboard**: A personalized dashboard for regular users showing their reported issues. Displays issue status, submission dates, and progress updates. Includes options to edit pending reports, view resolution details, and track the impact of their contributions to community improvements.

10. **AI Prediction**: A screen showcasing AI-driven insights and predictions based on reported data patterns. Displays predictive alerts for potential future issues in specific areas, risk assessments for infrastructure problems, and suggested preventive measures. Uses machine learning algorithms to analyze historical data and provide proactive recommendations.

11. **User Captures Image**: The camera interface for users to capture photos when reporting issues. Features a full-screen camera view with controls for flash, zoom, and image quality. Includes real-time preview, capture button, and options to retake or proceed to the next step in the reporting process.

12. **Report an Issue**: The main form screen for submitting new civic issue reports. Contains fields for issue title, detailed description, category selection (dropdown), location (auto-detected or manual), and image attachment. Includes validation for required fields and a submit button that triggers offline sync if needed.

13. **Voice Reporting on Issue**: An alternative input method allowing users to report issues via voice recording. Features a microphone button for recording, real-time audio waveform visualization, and speech-to-text conversion. Supports multiple languages for accessibility and includes playback options for review before submission.

14. **Map View**: An interactive map screen displaying reported issues as markers across the user's location. Uses Google Maps integration to show issue density, with color-coded markers indicating status (red for urgent, yellow for in progress, green for resolved). Includes search functionality and filtering by category or date range.

15. **Map Zoom & Marker**: A detailed view of the map with enhanced zoom capabilities and individual issue markers. When a marker is tapped, it shows a popup with issue summary, photo thumbnail, and quick actions. Supports multi-touch gestures for zooming and panning, with options to view issue details or navigate to the location.

16. **User Alerts**: A notifications screen for regular users displaying updates on their reported issues, system announcements, and community alerts. Shows alert types (issue update, resolution complete, new feature), timestamps, and direct links to relevant screens. Includes swipe-to-dismiss and mark-all-as-read functionality.

17. **User Profile**: The user's personal profile screen showing account information, reporting history, and app preferences. Displays profile photo, name, contact details, and statistics like total issues reported and resolution success rate. Includes settings for notifications, language, and account management options.

18. **Comments**: A discussion screen for collaborative issue resolution, showing threaded comments between users and officials. Displays user avatars, timestamps, and comment content with support for text, images, and attachments. Includes options to reply, like comments, and moderate content for maintaining constructive dialogue.

## Tech Stack

* **Frontend:** Flutter
* **Backend & Database:** Firebase
    * **Authentication:** Firebase Auth (Email/Password, Google,)
    * **Database:** Cloud Firestore (for storing user data, issues, comments, etc.)
    * **Storage:** Firebase Storage (for image uploads)
    * **Push Notifications:** Firebase Cloud Messaging (FCM)
* **State Management:** Provider
* **Mapping:** Google Maps Flutter
* **Location:** Geolocator, Geocoding
* **Image Handling:** Image Picker, Camera, Photo View, Image Cropper
* **HTTP Client:** `http` package
* **Local Notifications:** `flutter_local_notifications`
* **Charting:** `fl_chart` (for official statistics)

## Project Structure

The project follows a standard Flutter project structure with detailed focus on the lib/ directory:

```
lib/
├── main.dart                     # Application entry point
├── common/                       # Shared widgets and utilities
│   └── app_logo.dart             # App logo widget
├── l10n/                         # Localization files
│   ├── app_localizations.dart    # Main localization class
│   ├── app_localizations_en.dart # English translations
│   ├── app_localizations_gu.dart # Gujarati translations
│   └── app_localizations_hi.dart # Hindi translations
├── models/                       # Data models
│   ├── app_user_model.dart       # User data model
│   ├── category_model.dart       # Issue category model
│   ├── comment_model.dart        # Comment data model
│   ├── issue_model.dart          # Issue data model
│   ├── local_issue_model.dart    # Local issue model
│   └── notification_model.dart   # Notification model
├── screens/                      # UI screens organized by feature
│   ├── auth/                     # Authentication screens
│   │   ├── auth_options_screen.dart
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   └── verify_email_screen.dart
│   ├── feed/                     # Issue feed screens
│   │   ├── issue_collaboration_screen.dart
│   │   ├── issue_details_screen_simple.dart
│   │   ├── issue_details_screen.dart
│   │   └── issues_list_screen.dart
│   ├── impact/                   # Impact tracking screens
│   │   └── community_impact_screen.dart
│   ├── map/                      # Map-related screens
│   │   └── map_view_screen.dart
│   ├── notifications/            # Notification screens
│   │   └── notifications_screen.dart
│   ├── profile/                  # User profile screens
│   │   ├── account_screen.dart
│   │   ├── my_reported_issues_screen.dart
│   │   └── unsynced_issues_screen.dart
│   ├── report/                   # Issue reporting screens
│   │   ├── camera_capture_screen.dart
│   │   └── report_details_screen.dart
│   ├── full_screen_image_view.dart
│   ├── home_screen.dart
│   ├── initial_route_manager.dart
│   ├── language_selection_screen.dart
│   ├── main_app_scaffold.dart
│   ├── public_dashboard_screen.dart
│   ├── report_screen.dart
│   └── role_selection_screen.dart
├── services/                     # Business logic and external services
│   ├── app_check_test_service.dart
│   ├── auth_service.dart
│   ├── connectivity_service.dart
│   ├── duplicate_detection_service.dart
│   ├── fcm_token_refresh_service.dart
│   ├── fcm_token_service.dart
│   ├── firestore_service.dart
│   ├── image_comparison_service.dart
│   ├── image_upload_service.dart
│   ├── local_data_service.dart
│   ├── locale_provider.dart
│   ├── location_service.dart
│   ├── notification_service.dart
│   ├── offline_sync_service.dart
│   ├── optimized_provider_wrapper.dart
│   ├── performance_monitor_service.dart
│   └── predictive_maintenance_service.dart
├── utils/                        # Utility functions and helpers
└── widgets/                      # Reusable custom widgets
```

## Getting Started

### Prerequisites

* Flutter SDK (version 3.x recommended)
* Dart SDK (version 3.x recommended)
* An IDE like Android Studio or VS Code with Flutter plugins.
* Firebase account and a new Firebase project.

### Setup

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/your-username/nivaran.git](https://github.com/your-username/nivaran.git) # Replace with your repo URL
    cd nivaran
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Firebase Configuration:**
    * Set up a Firebase project at [console.firebase.google.com](https://console.firebase.google.com/).
    * Add an Android app and an iOS app to your Firebase project.
    * **Android:**
        * Download the `google-services.json` file from your Firebase project settings.
        * Place it in the `android/app/` directory.
        * Ensure your Android package name in `android/app/build.gradle.kts` matches the one in Firebase.
    * **iOS:**
        * Download the `GoogleService-Info.plist` file from your Firebase project settings.
        * Open the `ios/Runner.xcworkspace` in Xcode and add this file to the `Runner` target.
        * Ensure your iOS bundle ID in Xcode matches the one in Firebase.
    * **Enable Firebase Services:**
        * **Authentication:** Enable Email/Password, Google, and Facebook sign-in methods in the Firebase console. For Facebook login, additional setup on the Facebook Developer portal is required.
        * **Cloud Firestore:** Create a Firestore database. Set up appropriate security rules.
        * **Firebase Storage:** Set up Firebase Storage. Configure security rules (e.g., allow authenticated users to write to specific paths).
        * **Firebase Cloud Messaging (FCM):** No specific enablement needed in console for basic setup, but ensure API is enabled if using legacy protocols.

4.  **Google Maps API Key:**
    * Obtain a Google Maps API key from the [Google Cloud Console](https://console.cloud.google.com/apis/library/maps-android-sdk-backend.googleapis.com). Ensure "Maps SDK for Android" and "Maps SDK for iOS" are enabled.
    * **Android:** Add the API key to `android/app/src/main/AndroidManifest.xml`:
        ```xml
        <meta-data android:name="com.google.android.geo.API_KEY"
                   android:value="YOUR_ANDROID_MAPS_API_KEY"/>
        ```
    * **iOS:** Add the API key to `ios/Runner/AppDelegate.swift`:
        ```swift
        import UIKit
        import Flutter
        import GoogleMaps // Add this import

        @UIApplicationMain
        @objc class AppDelegate: FlutterAppDelegate {
          override func application(
            _ application: UIApplication,
            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
          ) -> Bool {
            GMSServices.provideAPIKey("YOUR_IOS_MAPS_API_KEY") // Add this line
            GeneratedPluginRegistrant.register(with: self)
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
          }
        }
        ```

5.  **Environment Variables (Optional but Recommended):**
    * If using `flutter_dotenv`, create a `.env` file in the root of your project:
        ```
        # Example .env file
        # API_KEY_EXAMPLE=your_api_key_here
        ```
    * Add `.env` to your `.gitignore` file.
    * Load these in your `main.dart` or service files.

6.  **Run the app:**
    ```bash
    flutter run
    ```
    Or use your IDE's run button.

## Contributing

Contributions are welcome! If you'd like to contribute, please follow these steps:

1.  Fork the repository.
2.  Create a new branch (`git checkout -b feature/your-feature-name`).
3.  Make your changes.
4.  Commit your changes (`git commit -m 'Add some feature'`).
5.  Push to the branch (`git push origin feature/your-feature-name`).
6.  Open a Pull Request.

Please make sure to update tests as appropriate.

## 👥 Contributors

| [<img src="https://github.com/ekank123.png" width="100px;"/><br />@ekank123](https://github.com/ekank123) | [<img src="https://github.com/vaibhav2195.png" width="100px;"/><br />@vaibhav2195](https://github.com/vaibhav2195) | [<img src="https://github.com/Deva3664.png" width="100px;"/><br />@Deva3664](https://github.com/Deva3664) | [<img src="https://github.com/Alexa88879.png" width="100px;"/><br />@Alexa88879](https://github.com/Alexa88879) |
| :---: | :---: | :---: | :---: |

## 📄 License

This project is licensed under the terms specified in the [LICENSE](LICENSE.md) file. Please refer to the `LICENSE.md` file in the root of the repository for full details.



## Acknowledgements

* Flutter team for the amazing framework.
* Firebase team for the robust backend services.
* Contributors to all the open-source packages used.

---
