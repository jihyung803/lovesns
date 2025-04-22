import 'package:flutter/material.dart';

class AppTheme {
  // App Colors
  static const Color primaryColor = Color(0xFFFF6B6B);
  static const Color secondaryColor = Color(0xFF4ECDC4);
  static const Color accentColor = Color(0xFFFFD166);
  static const Color textColor = Color(0xFF2D3142);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color errorColor = Color(0xFFFF5252);
  static const Color successColor = Color(0xFF69F0AE);
  static const Color warningColor = Color(0xFFFFD54F);
  static const Color disabledColor = Color(0xFFBDBDBD);
  
  // Mystical Colors
  static const Color cosmicPurple = Color(0xFF8A2BE2);
  static const Color deepSpace = Color(0xFF191230);
  static const Color starGlow = Color(0xFFFFF8E1);
  static const Color cosmicPink = Color(0xFFFF69B4);
  static const Color nebulaTeal = Color(0xFF40E0D0);
  static const Color galaxyBlue = Color(0xFF0066FF);
  static const Color celestialIndigo = Color(0xFF4B0082);
  static const Color meteorOrange = Color(0xFFFF7F50);
  static const Color voidBlack = Color(0xFF0F0A1F);

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textColor,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textColor,
  );

  static const TextStyle captionStyle = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 12,
    fontWeight: FontWeight.w300,
    color: textColor,
  );
  
  // Mystical Text Styles
  static const TextStyle cosmicHeadingStyle = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 0.5,
    shadows: [
      Shadow(
        color: Color(0xFFFF69B4),
        blurRadius: 10,
        offset: Offset(0, 2),
      ),
    ],
  );
  
  static const TextStyle cosmicSubheadingStyle = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );
  
  static const TextStyle cosmicBodyStyle = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.white,
  );

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      background: backgroundColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: primaryColor,
      unselectedLabelColor: Colors.grey,
      indicatorSize: TabBarIndicatorSize.tab,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
    ),
    fontFamily: 'Montserrat',
  );

  // Dark Theme with Cosmic Enhancement
  static final ThemeData darkTheme = ThemeData(
    primaryColor: cosmicPink,
    colorScheme: ColorScheme.dark(
      primary: cosmicPink,
      secondary: nebulaTeal,
      error: errorColor,
      background: deepSpace,
      surface: voidBlack,
    ),
    scaffoldBackgroundColor: deepSpace,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: cosmicHeadingStyle.copyWith(fontSize: 20),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: cosmicPink,
      unselectedLabelColor: Colors.grey,
      indicatorSize: TabBarIndicatorSize.tab,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: voidBlack.withOpacity(0.7),
      selectedItemColor: cosmicPink,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: cosmicPink,
      foregroundColor: Colors.white,
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: cosmicPink,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cosmicPink,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        elevation: 8,
        shadowColor: cosmicPink.withOpacity(0.5),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: starGlow,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: voidBlack.withOpacity(0.6),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cosmicPink, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
    ),
    textTheme: TextTheme(
      displayLarge: cosmicHeadingStyle.copyWith(fontSize: 28),
      displayMedium: cosmicHeadingStyle,
      displaySmall: cosmicHeadingStyle.copyWith(fontSize: 20),
      headlineMedium: cosmicSubheadingStyle,
      bodyLarge: cosmicBodyStyle,
      bodyMedium: cosmicBodyStyle,
    ),
    fontFamily: 'Montserrat',
    cardTheme: CardTheme(
      color: voidBlack.withOpacity(0.6),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      shadowColor: cosmicPurple.withOpacity(0.3),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.white.withOpacity(0.1),
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: voidBlack.withOpacity(0.9),
      contentTextStyle: const TextStyle(
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: deepSpace,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      titleTextStyle: cosmicSubheadingStyle,
      contentTextStyle: cosmicBodyStyle,
    ),
  );
}