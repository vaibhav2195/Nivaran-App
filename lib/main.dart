import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // <-- ADDED
import 'package:modern_auth_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Import ConnectivityResult
import 'models/local_issue_model.dart';
import 'services/locale_provider.dart';
import 'screens/initial_route_manager.dart';
import 'screens/language_selection_screen.dart';
import 'services/auth_service.dart';
import 'services/user_profile_service.dart';
import 'services/notification_service.dart';
import 'services/offline_sync_service.dart';
import 'services/connectivity_service.dart'; // Add ConnectivityService import
import 'services/firestore_service.dart'; // Add FirestoreService import
import 'services/image_upload_service.dart'; // Add ImageUploadService import
import 'screens/role_selection_screen.dart';
import 'screens/auth/auth_options_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/official/official_login_screen.dart';
import 'screens/official/official_signup_screen.dart';
import 'screens/official/official_details_entry_screen.dart';
import 'screens/official/official_set_password_screen.dart';
import 'screens/official/official_dashboard_screen.dart';
import 'screens/main_app_scaffold.dart';
import 'screens/public_dashboard_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/feed/issue_details_screen.dart';
import 'screens/profile/unsynced_issues_screen.dart';
import 'dart:developer' as developer;


// Top-level background message handler (as required by FCM)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // Ensure Firebase is initialized for background isolates
  developer.log("Handling a background message: ${message.messageId}", name: "MainBGHandler");
  // You can add custom logic here if needed, e.g., saving to local DB
  // For now, NotificationService handles most logic, or FCM displays the system notification.
}

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

late Isar isar; // Declare Isar instance globally

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // .env file loading removed - using hardcoded values from secrets.dart
  
  await Firebase.initializeApp();
  
  // Initialize Isar
  final dir = await getApplicationDocumentsDirectory();
  isar = await Isar.open(
    [LocalIssueSchema],
    directory: dir.path,
    inspector: true, // Enable Isar Inspector for debugging
  );

  // Set the background messaging handler for FCM
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<UserProfileService>(create: (_) => UserProfileService()),
        Provider<NotificationService>(create: (_) => NotificationService(navigatorKey: navigatorKey)),
        ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
        Provider<ConnectivityService>(create: (_) => ConnectivityService()), // Add ConnectivityService
        Provider<FirestoreService>(create: (_) => FirestoreService()), // Add FirestoreService
        Provider<ImageUploadService>(create: (_) => ImageUploadService()), // Add ImageUploadService
        ChangeNotifierProxyProvider5<UserProfileService, ConnectivityService, AuthService, FirestoreService, ImageUploadService, OfflineSyncService>(
          create: (context) => OfflineSyncService(
            isar, // Pass the global Isar instance
            Provider.of<ConnectivityService>(context, listen: false),
            Provider.of<AuthService>(context, listen: false),
            Provider.of<FirestoreService>(context, listen: false),
            Provider.of<ImageUploadService>(context, listen: false),
          ),
          update: (context, userService, connectivityService, authService, firestoreService, imageUploadService, offlineService) {
            // No need to set user here, as OfflineSyncService gets Auth and handles it internally
            return offlineService ?? OfflineSyncService(isar, connectivityService, authService, firestoreService, imageUploadService);
          },
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
    // Initialize NotificationService after build, once providers are available
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final notificationService = Provider.of<NotificationService>(context, listen: false);
        await notificationService.initialize().then((_) {
            developer.log("NotificationService initialized from MyApp", name: "MyApp");
        }).catchError((e) {
            developer.log("Error initializing NotificationService from MyApp: $e", name: "MyApp");
        });

        final offlineSyncService = Provider.of<OfflineSyncService>(context, listen: false);
        if (!mounted) return;
        await offlineSyncService.initialize();
        if (!mounted) return;
        await offlineSyncService.refreshCachedIssues();
        developer.log("OfflineSyncService initialized and cached issues refreshed from MyApp", name: "MyApp");
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
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
      navigatorKey: navigatorKey, // Assign the global key
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
          )
        ),
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
      home: const InitialRouteManager(),
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
        '/official_dashboard':(context) => const OfficialDashboardScreen(),

        '/app': (context) => const MainAppScaffold(),
        '/notifications': (context) => const NotificationsScreen(), // Route for notifications screen
        // Placeholder for issue details, ensure you have this screen or a similar one
        '/issue_details': (context) {
            final issueId = ModalRoute.of(context)!.settings.arguments as String?;
            // Replace with your actual IssueDetailsScreen, passing the issueId
            return IssueDetailsScreen(issueId: issueId ?? 'error_no_id');
        },

        '/public_dashboard': (context) => const PublicDashboardScreen(),
        '/unsynced_issues': (context) => const UnsyncedIssuesScreen(),
      },
    );
  }
}

class InitialAuthCheck extends StatefulWidget {
  const InitialAuthCheck({super.key});

  @override
  State<InitialAuthCheck> createState() => _InitialAuthCheckState();
}

class _InitialAuthCheckState extends State<InitialAuthCheck> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAuthChanged();
    });
  }

  Future<void> _handleAuthChanged() async {
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    final offlineSyncService = Provider.of<OfflineSyncService>(context, listen: false);
    final userProfileService = Provider.of<UserProfileService>(context, listen: false);

    final connectivityResult = await connectivityService.checkConnectivity();
    final isOffline = connectivityResult == ConnectivityResult.none;

    if (isOffline) {
      // Try to load cached user profile or issues
      final hasCachedProfile = await userProfileService.hasCachedUserProfile();
      final hasCachedIssues = await offlineSyncService.hasCachedIssues();

      if (hasCachedProfile || hasCachedIssues) {
        // Navigate to the main app or official dashboard if cached data exists
        // This assumes that if a profile is cached, it's a valid one to proceed with.
        // For simplicity, we'll navigate to the main app scaffold.
        // A more robust solution might check the cached user's role.
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/app', (route) => false);
      } else {
        // No cached data, navigate to a screen that doesn't require network
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/role_selection', (route) => false);
      }
      return;
    }

    // If online, proceed with existing Firebase authentication logic
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user != null) {
      // Ensure profile is loaded
      if (userProfileService.currentUserProfile?.uid != user.uid) {
        await userProfileService.fetchAndSetCurrentUserProfile();
      }

      if (!mounted) return;

      final profile = userProfileService.currentUserProfile;

      if (!user.emailVerified) {
        Navigator.of(context).pushNamedAndRemoveUntil('/verify_email_screen', (route) => false);
        return;
      }

      if (profile != null) {
        if (profile.isOfficial) {
          if (profile.department == null || profile.department!.isEmpty) {
            Navigator.of(context).pushNamedAndRemoveUntil('/official_details_entry', (route) => false);
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil('/official_dashboard', (route) => false);
          }
        } else {
          Navigator.of(context).pushNamedAndRemoveUntil('/app', (route) => false);
        }
      } else {
        // Handle profile not loading
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not load user profile. Please try again.")));
        Navigator.of(context).pushNamedAndRemoveUntil('/role_selection', (route) => false);
      }
    } else {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/role_selection', (route) => false);
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
