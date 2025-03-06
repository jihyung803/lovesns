import 'package:flutter/material.dart';
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
import 'package:new_couple_app/screens/feed/feed_screen.dart';
import 'package:new_couple_app/screens/main_screen.dart';
import 'package:new_couple_app/screens/auth/couple_connect_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    // Firebase 초기화
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
        ChangeNotifierProvider(
          create: (context) => PostService(
            authService: Provider.of<AuthService>(context, listen: false)
          )
        ),
        ChangeNotifierProvider(
          create: (context) => StoryService(
            authService: Provider.of<AuthService>(context, listen: false)
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
        title: 'Couple SNS',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.login,
        routes: AppRoutes.routes,
        home: Consumer<AuthService>(
          builder: (context, authService, _) {
            if (!authService.isLoggedIn) {
              return const LoginScreen();
            } else if (!authService.isPartnerConnected) {
              return const CoupleConnectScreen();
            } else {
              return const MainScreen();
            }
          },
        ),
      ),
    );
  }
}