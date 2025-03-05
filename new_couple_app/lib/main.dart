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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    // Firebase 초기화
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'AIzaSyAwDYwDnv-YDC_sWz7fhlOPnAKbhenVsI8',
      appId: '1:969309172686:ios:3a25572e57038c1f58319f',
      messagingSenderId: '969309172686',
      projectId: 'lovestar-778ec',
      storageBucket: 'lovestar-778ec.firebasestorage.app',
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
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.login,
        routes: AppRoutes.routes,
        home: Consumer<AuthService>(
          builder: (context, authService, _) {
            return authService.isLoggedIn ? const MainScreen() : const LoginScreen();
          },
        ),
      ),
    );
  }
}