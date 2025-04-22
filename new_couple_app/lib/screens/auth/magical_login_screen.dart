import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_couple_app/config/app_theme.dart';
import 'package:new_couple_app/services/auth_service.dart';
import 'package:new_couple_app/widgets/common/loading_indicator.dart';
import 'package:new_couple_app/widgets/couple_room/components/stars_background.dart';
import 'package:new_couple_app/widgets/couple_room/components/meteor_effect.dart';

class MagicalLoginScreen extends StatefulWidget {
  const MagicalLoginScreen({Key? key}) : super(key: key);

  @override
  State<MagicalLoginScreen> createState() => _MagicalLoginScreenState();
}

class _MagicalLoginScreenState extends State<MagicalLoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    
    // Basic email validation
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }
  
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final authService = Provider.of<AuthService>(context, listen: false);
    
    final bool success = await authService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    
    if (success && mounted) {
      // Navigate to the appropriate screen
      if (authService.isPartnerConnected) {
        // Partner is already connected, navigate to main screen
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        // Partner is not connected, navigate to couple connect screen
        Navigator.pushReplacementNamed(context, '/couple-connect');
      }
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${authService.error}'),
          backgroundColor: Colors.redAccent.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
  
  void _navigateToRegister() {
    Navigator.pushNamed(context, '/register');
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final size = MediaQuery.of(context).size;
    
    if (authService.isLoading) {
      return Scaffold(
        body: Stack(
          children: [
            // Starry background
            const StarsBackground(
              starDensity: 0.0002,
              minTwinkleSpeed: 0.3,
              maxTwinkleSpeed: 1.5,
            ),
            
            // Loading indicator
            const LoadingIndicator(message: 'Connecting to the stars...'),
          ],
        ),
      );
    }
    
    return Scaffold(
      body: Stack(
        children: [
          // Cosmic background
          const StarsBackground(
            starDensity: 0.0002,
            minTwinkleSpeed: 0.3,
            maxTwinkleSpeed: 1.5,
          ),
          
          // Meteor effect
          const MeteorEffect(
            number: 12,
            color: Colors.white,
          ),
          
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _animationController.value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - _animationController.value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // App logo with cosmic glow
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black12,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite,
                          size: 64,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // App title with animated background
                      ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: [
                              Colors.deepPurple,
                              Colors.pinkAccent,
                              Colors.purpleAccent,
                            ],
                            tileMode: TileMode.mirror,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds);
                        },
                        child: const Text(
                          'Cosmic Couples',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Where love transcends space and time',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Login form with frosted glass effect
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            width: size.width > 500 ? 500 : size.width,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Email field
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: _buildInputDecoration(
                                      label: 'Email',
                                      icon: Icons.email_outlined,
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: _validateEmail,
                                    cursorColor: Colors.white,
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Password field
                                  TextFormField(
                                    controller: _passwordController,
                                    decoration: _buildInputDecoration(
                                      label: 'Password',
                                      icon: Icons.lock_outline,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.white70,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible = !_isPasswordVisible;
                                          });
                                        },
                                      ),
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                    obscureText: !_isPasswordVisible,
                                    textInputAction: TextInputAction.done,
                                    validator: _validatePassword,
                                    onFieldSubmitted: (_) => _login(),
                                    cursorColor: Colors.white,
                                  ),
                                  const SizedBox(height: 30),
                                  
                                  // Login button with cosmic gradient
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF8A2BE2), // Deep purple
                                          const Color(0xFFFF69B4), // Hot pink
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF8A2BE2).withOpacity(0.5),
                                          blurRadius: 10,
                                          spreadRadius: 0,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(vertical: 15),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: const Text(
                                        'Journey to the Stars',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Register link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'New to our cosmic journey?',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _navigateToRegister,
                                        child: const Text(
                                          'Create Account',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.white.withOpacity(0.7),
      ),
      prefixIcon: Icon(
        icon,
        color: Colors.white70,
      ),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.white,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Colors.redAccent.withOpacity(0.8),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Colors.redAccent.withOpacity(0.8),
          width: 2,
        ),
      ),
      errorStyle: const TextStyle(
        color: Colors.redAccent,
      ),
      filled: true,
      fillColor: Colors.black12,
    );
  }
}
