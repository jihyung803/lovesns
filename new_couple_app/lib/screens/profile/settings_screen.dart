import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:new_couple_app/config/app_theme.dart';
import 'package:new_couple_app/services/auth_service.dart';
import 'package:new_couple_app/widgets/common/loading_indicator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _usernameController = TextEditingController();
  DateTime? _relationshipStartDate;
  DateTime? _partnerBirthday;
  DateTime? _menstrualCycleStart;
  int _menstrualCycleDuration = 28;
  bool _isLoading = false;
  File? _profileImage;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
  
  void _loadUserData() {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      setState(() {
        _usernameController.text = user.username;
        _relationshipStartDate = user.relationshipStartDate;
        _partnerBirthday = user.partnerBirthday;
        _menstrualCycleStart = user.menstrualCycleStart;
        _menstrualCycleDuration = user.menstrualCycleDuration;
      });
    }
  }
  
  Future<void> _selectDate(BuildContext context, String type) async {
    DateTime initialDate;
    DateTime firstDate;
    
    switch (type) {
      case 'relationship':
        initialDate = _relationshipStartDate ?? DateTime.now();
        firstDate = DateTime(2000);
        break;
      case 'birthday':
        initialDate = _partnerBirthday ?? DateTime.now().subtract(const Duration(days: 365 * 25));
        firstDate = DateTime(1950);
        break;
      case 'menstrual':
        initialDate = _menstrualCycleStart ?? DateTime.now();
        firstDate = DateTime.now().subtract(const Duration(days: 31));
        break;
      default:
        initialDate = DateTime.now();
        firstDate = DateTime(2000);
    }
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        switch (type) {
          case 'relationship':
            _relationshipStartDate = picked;
            break;
          case 'birthday':
            _partnerBirthday = picked;
            break;
          case 'menstrual':
            _menstrualCycleStart = picked;
            break;
        }
      });
    }
  }
  
  Future<void> _pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }
  
  Future<String?> _uploadProfileImage() async {
    if (_profileImage == null) return null;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id;
    
    if (userId == null) return null;
    
    try {
      // Upload image to Firebase Storage
      final Reference ref = FirebaseStorage.instance.ref().child('profile/$userId.jpg');
      await ref.putFile(_profileImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }
  
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Upload profile image if selected
      String? profileImageUrl;
      if (_profileImage != null) {
        profileImageUrl = await _uploadProfileImage();
      }
      
      // Update user profile
      final bool success = await authService.updateUserProfile(
        username: _usernameController.text.trim(),
        profileImageUrl: profileImageUrl,
        relationshipStartDate: _relationshipStartDate,
        partnerBirthday: _partnerBirthday,
        menstrualCycleStart: _menstrualCycleStart,
        menstrualCycleDuration: _menstrualCycleDuration,
      );
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings saved successfully')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save settings: ${authService.error}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final bool success = await authService.logout();
      
      if (success && mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to logout: ${authService.error}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to logout: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }
    
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Saving settings...'),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile image
            Center(
              child: GestureDetector(
                onTap: _pickProfileImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!) as ImageProvider
                          : user.profileImageUrl != null
                              ? NetworkImage(user.profileImageUrl!) as ImageProvider
                              : null,
                      child: user.profileImageUrl == null && _profileImage == null
                          ? Text(
                              user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Username
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            
            // Relationship start date
            ListTile(
              title: const Text('Relationship Start Date'),
              subtitle: Text(_relationshipStartDate != null
                  ? DateFormat('MMM d, yyyy').format(_relationshipStartDate!)
                  : 'Not set'),
              leading: const Icon(Icons.favorite),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, 'relationship'),
            ),
            const Divider(),
            
            // Partner birthday
            ListTile(
              title: const Text('Partner\'s Birthday'),
              subtitle: Text(_partnerBirthday != null
                  ? DateFormat('MMM d, yyyy').format(_partnerBirthday!)
                  : 'Not set'),
              leading: const Icon(Icons.cake),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, 'birthday'),
            ),
            const Divider(),
            
            // Menstrual cycle (optional)
            ExpansionTile(
              title: const Text('Menstrual Cycle Settings'),
              leading: const Icon(Icons.calendar_month),
              children: [
                ListTile(
                  title: const Text('Last Period Start Date'),
                  subtitle: Text(_menstrualCycleStart != null
                      ? DateFormat('MMM d, yyyy').format(_menstrualCycleStart!)
                      : 'Not set'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, 'menstrual'),
                ),
                ListTile(
                  title: const Text('Cycle Duration (Days)'),
                  subtitle: Slider(
                    value: _menstrualCycleDuration.toDouble(),
                    min: 21,
                    max: 35,
                    divisions: 14,
                    label: _menstrualCycleDuration.toString(),
                    onChanged: (value) {
                      setState(() {
                        _menstrualCycleDuration = value.toInt();
                      });
                    },
                  ),
                ),
              ],
            ),
            const Divider(),
            
            // Save button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Save Settings',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            
            // Logout button
            TextButton(
              onPressed: _logout,
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}