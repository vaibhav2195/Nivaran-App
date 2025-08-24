import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // <-- ADDED
import 'package:flutter/material.dart';
import 'package:modern_auth_app/l10n/app_localizations.dart';
import 'package:modern_auth_app/screens/auth/auth_options_screen.dart';
import 'package:modern_auth_app/screens/auth/login_screen.dart';
import 'package:modern_auth_app/screens/auth/signup_screen.dart';
import 'package:modern_auth_app/screens/auth/verify_email_screen.dart';
import 'package:modern_auth_app/screens/feed/issue_details_screen.dart';
import 'package:modern_auth_app/screens/initial_route_manager.dart';
import 'package:modern_auth_app/screens/language_selection_screen.dart';
import 'package:modern_auth_app/screens/main_app_scaffold.dart';
import 'package:modern_auth_app/screens/notifications/notifications_screen.dart';
import 'package:modern_auth_app/screens/official/official_dashboard_screen.dart';
import 'package:modern_auth_app/screens/official/official_details_entry_screen.dart';
import 'package:modern_auth_app/screens/official/official_login_screen.dart';
import 'package:modern_auth_app/screens/official/official_set_password_screen.dart';
import 'package:modern_auth_app/screens/official/official_signup_screen.dart';
import 'package:modern_auth_app/screens/public_dashboard_screen.dart';
import 'package:modern_auth_app/screens/role_selection_screen.dart';
import 'package:modern_auth_app/screens/profile/unsynced_issues_screen.dart';
import 'package:modern_auth_app/services/auth_service.dart';
import 'package:modern_auth_app/services/connectivity_service.dart'; // Add ConnectivityService import
import 'package:modern_auth_app/services/firestore_service.dart'; // Add FirestoreService import
import 'package:modern_auth_app/services/image_upload_service.dart'; // Add ImageUploadService import
import 'package:modern_auth_app/services/locale_provider.dart';
import 'package:modern_auth_app/services/notification_service.dart';
import 'package:modern_auth_app/services/user_profile_service.dart';
import 'package:modern_auth_app/services/local_data_service.dart';
import 'package:modern_auth_app/services/offline_sync_service.dart';
import 'package:provider/provider.dart';

// Top-level background message handler (as required by FCM)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // Ensure Firebase is initialized for background isolates
  developer.log("Handling a background message: ${message.messageId}", name: "MainBGHandler");
}

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Set the background messaging handler for FCM
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<UserProfileService>(create: (_) => UserProfileService()),
        Provider<NotificationService>(create: (_) => NotificationService(navigatorKey: navigatorKey)),
        ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
        ChangeNotifierProvider<ConnectivityService>(create: (_) => ConnectivityService.instance),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<ImageUploadService>(create: (_) => ImageUploadService()),
        Provider<LocalDataService>(create: (_) => LocalDataService()),
        ChangeNotifierProvider<OfflineSyncService>(
          create: (context) => OfflineSyncService(Provider.of<ConnectivityService>(context, listen: false)),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize services after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final notificationService = Provider.of<NotificationService>(context, listen: false);
        await notificationService.initialize().then((_) {
          developer.log("NotificationService initialized from MyApp", name: "MyApp");
        }).catchError((e) {
          developer.log("Error initializing NotificationService from MyApp: $e", name: "MyApp");
        });

        // Initialize ConnectivityService
        final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
        await connectivityService.initialize().then((_) {
          developer.log("ConnectivityService initialized", name: "MyApp");
        }).catchError((e) {
          developer.log("Error initializing ConnectivityService: $e", name: "MyApp");
        });

        // Initialize LocalDataService database
        final localDataService = Provider.of<LocalDataService>(context, listen: false);
        await localDataService.initializeDatabase().then((_) {
          developer.log("LocalDataService database initialized", name: "MyApp");
        }).catchError((e) {
          developer.log("Error initializing LocalDataService database: $e", name: "MyApp");
        });

        // Initialize OfflineSyncService
        final offlineSyncService = Provider.of<OfflineSyncService>(context, listen: false);
        await offlineSyncService.initialize().then((_) {
          developer.log("OfflineSyncService initialized with auto-sync", name: "MyApp");
        }).catchError((e) {
          developer.log("Error initializing OfflineSyncService: $e", name: "MyApp");
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use a Consumer to rebuild only the MaterialApp when the locale changes.
    // This prevents the `home` widget (`InitialRouteManager`) from being rebuilt.
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, homeWidget) {
        TextTheme defaultTextTheme = Theme.of(context).textTheme;
        TextTheme appTextTheme = defaultTextTheme.copyWith(
          displayLarge: defaultTextTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
          displayMedium: defaultTextTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
          headlineMedium: defaultTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.black, fontSize: 26),
          headlineSmall: defaultTextTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 22),
          titleLarge: defaultTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 20),
          bodyLarge: defaultTextTheme.bodyLarge?.copyWith(color: Colors.black87, fontSize: 16),
          bodyMedium: defaultTextTheme.bodyMedium?.copyWith(color: Colors.black54, fontSize: 14),
          labelLarge: defaultTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
        );

        return MaterialApp(
          title: 'Nivaran',
          navigatorKey: navigatorKey,
          theme: ThemeData(
            primaryColor: Colors.black,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black, size: 20),
              titleTextStyle: appTextTheme.titleLarge?.copyWith(fontSize: 18),
              centerTitle: true,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                textStyle: appTextTheme.labelLarge?.copyWith(letterSpacing: 0.5, color: Colors.white),
                minimumSize: const Size(double.infinity, 50),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              textStyle: appTextTheme.labelLarge?.copyWith(color: Colors.black),
              minimumSize: const Size(double.infinity, 50),
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Colors.black, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            )),
            inputDecorationTheme: InputDecorationTheme(
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.black, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.red.shade600, width: 1.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.red.shade600, width: 1.5),
              ),
              prefixIconColor: Colors.grey[700],
            ),
            textTheme: appTextTheme,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal).copyWith(
              secondary: Colors.teal,
              surface: Colors.white,
            ),
          ),
          debugShowCheckedModeBanner: false,
          locale: localeProvider.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: homeWidget, // Use the pre-built child from the Consumer
          routes: {
            '/language_selection': (context) => const LanguageSelectionScreen(),
            '/initial_auth_check': (context) => const InitialAuthCheck(),
            '/role_selection': (context) => const RoleSelectionScreen(),
            '/auth_options': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as String?;
              return AuthOptionsScreen(userType: args ?? 'citizen');
            },
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/verify_email_screen': (context) => const VerifyEmailScreen(),
            '/official_login': (context) => const OfficialLoginScreen(),
            '/official_signup': (context) => const OfficialSignupScreen(),
            '/official_details_entry': (context) => const OfficialDetailsEntryScreen(),
            '/official_set_password': (context) => const OfficialSetPasswordScreen(),
            '/official_dashboard': (context) => const OfficialDashboardScreen(),
            '/app': (context) => const MainAppScaffold(),
            '/notifications': (context) => const NotificationsScreen(),
            '/issue_details': (context) {
              final issueId = ModalRoute.of(context)!.settings.arguments as String?;
              return IssueDetailsScreen(issueId: issueId ?? 'error_no_id');
            },
            '/public_dashboard': (context) => const PublicDashboardScreen(),
            '/unsynced_issues': (context) => const UnsyncedIssuesScreen(),
          },
        );
      },
      // This child is built once and passed to the builder, preventing the loop.
      child: const InitialRouteManager(),
    );
  }
}

class InitialAuthCheck extends StatefulWidget {
  const InitialAuthCheck({super.key});

  @override
  State<InitialAuthCheck> createState() => _InitialAuthCheckState();
}

class _InitialAuthCheckState extends State<InitialAuthCheck> {
  bool _navigationStarted = false;
  late final ConnectivityService _connectivityService;

  // Define the listener function once
  void _onConnectivityChanged() {
    if (mounted) {
      _performAuthCheck(_connectivityService.isOnline);
    }
  }

  @override
  void initState() {
    super.initState();
    // Get the service once and add the listener
    _connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    _connectivityService.addListener(_onConnectivityChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Perform the initial check
        _performAuthCheck(_connectivityService.isOnline);
      }
    });
  }

  @override
  void dispose() {
    // Remove the listener when the widget is disposed
    _connectivityService.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  Future<void> _performAuthCheck(bool isOnline) async {
    // Prevent navigation logic from running more than once
    if (_navigationStarted) {
      return;
    }
    _navigationStarted = true;

    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    final userProfileService = Provider.of<UserProfileService>(context, listen: false);

    // Use a local variable for the navigator to avoid using context after an async gap
    final navigator = Navigator.of(context);

    if (user != null) {
      // Use timeout for profile fetching to prevent hanging
      try {
        await userProfileService.fetchAndSetCurrentUserProfile().timeout(
          const Duration(seconds: 5),
        );
      } catch (e) {
        developer.log("InitialAuthCheck: Profile fetch timed out or failed: $e", name: "InitialAuthCheck");
        // Continue with null profile - will be handled below
      }
      
      if (!mounted) return;

      final profile = userProfileService.currentUserProfile;

      if (!user.emailVerified) {
        await navigator.pushNamedAndRemoveUntil('/verify_email_screen', (route) => false);
        return;
      }

      if (profile != null) {
        if (profile.isOfficial) {
          if (profile.department == null || profile.department!.isEmpty) {
            await navigator.pushNamedAndRemoveUntil('/official_details_entry', (route) => false);
          } else {
            await navigator.pushNamedAndRemoveUntil('/official_dashboard', (route) => false);
          }
        } else {
          await navigator.pushNamedAndRemoveUntil('/app', (route) => false);
        }
      } else if (isOnline) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not load user profile. Please try again.")));
          await navigator.pushNamedAndRemoveUntil('/role_selection', (route) => false);
        }
      } else {
        // When offline and no profile loaded, still allow access to main app
        developer.log("InitialAuthCheck: Offline mode - allowing access to main app without profile", name: "InitialAuthCheck");
        await navigator.pushNamedAndRemoveUntil('/app', (route) => false);
      }
    } else {
      await navigator.pushNamedAndRemoveUntil('/role_selection', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(semanticsLabel: "Checking authentication..."),
      ),
    );
  }
}
