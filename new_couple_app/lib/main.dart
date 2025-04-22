import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:new_couple_app/config/app_theme.dart';
import 'package:new_couple_app/config/routes.dart';
import 'package:new_couple_app/services/auth_service.dart';
import 'package:new_couple_app/services/post_service.dart';
import 'package:new_couple_app/services/story_service.dart';
import 'package:new_couple_app/services/calendar_service.dart';
import 'package:new_couple_app/services/decoration_service.dart';
import 'package:new_couple_app/screens/auth/login_screen.dart';
import 'package:new_couple_app/screens/auth/magical_login_screen.dart';
import 'package:new_couple_app/screens/auth/magical_couple_connect_screen.dart';
import 'package:new_couple_app/screens/mystical_main_screen.dart';
import 'package:new_couple_app/services/notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Load environment variables
  try {
    await dotenv.load();
    print("Environment variables loaded successfully!");
  } catch (e) {
    print("Failed to load environment variables: $e");
    // App continues but OpenAI functionality won't be available
  }

  // Initialize Firebase
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'AIzaSyBjRHZFLtDOyK2Y_xdEYBXGxznef8w0h8w',
      appId: '1:1082138474791:ios:1fe1ed8997b92498615102',
      messagingSenderId: '1082138474791',
      projectId: 'lovesns-116e5',
      storageBucket: 'lovesns-116e5.firebasestorage.app',
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(
          create: (context) => PostService(
            authService: Provider.of<AuthService>(context, listen: false)
          )
        ),
        ChangeNotifierProvider(
          create: (context) => StoryService(
            Provider.of<AuthService>(context, listen: false)
          )
        ),
        ChangeNotifierProvider(
          create: (context) => CalendarService(
            authService: Provider.of<AuthService>(context, listen: false)
          )
        ),
        ChangeNotifierProvider(
          create: (context) => DecorationService(
            authService: Provider.of<AuthService>(context, listen: false)
          )
        ),
      ],
      child: MaterialApp(
        title: 'Cosmic Couples',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark, // Set default theme mode to dark for cosmic feel
        debugShowCheckedModeBanner: false,
        routes: AppRoutes.routes,
        home: Consumer<AuthService>(
          builder: (context, authService, _) {
            if (!authService.isLoggedIn) {
              return const MagicalLoginScreen();
            } else if (!authService.isPartnerConnected) {
              return const MagicalCoupleConnectScreen();
            } else {
              return const MysticalMainScreen();
            }
          },
        ),
      ),
    );
  }
}
