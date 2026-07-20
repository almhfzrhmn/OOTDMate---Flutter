import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';
import 'package:ootdmate_frontend/models/user_model.dart';
import 'package:ootdmate_frontend/services/auth-services/auth_services.dart';
import 'package:ootdmate_frontend/widgets/app_header.dart';
import 'package:ootdmate_frontend/screens/core/wardrobes/wardrobe_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthServices _authServices = AuthServices();
  UserModel? _userProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final profile = await _authServices.getProfile();
    if (!mounted) return;
    setState(() {
      _userProfile = profile;
      _isLoadingProfile = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.glitchMagenta),
        ),
      );
    }
    final String name = _userProfile?.fullName ?? "Guest";
    final String? avatarUrl = _userProfile?.avatarUrl;

    return Scaffold(
      appBar: AppHeader(
        title: "Hi, ${name[0].toUpperCase() + name.substring(1)}",
        subTitle: "Let's create your stylish look for today",
        avatarUrl: avatarUrl,
        username: name,
        currentUser: _userProfile,
      ),
    );
  }
}
