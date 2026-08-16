import 'package:flutter/material.dart';
import 'package:ootdmate_frontend/models/user_model.dart';
import 'package:ootdmate_frontend/screens/core/favorite/favorite_screen.dart';
import 'package:ootdmate_frontend/screens/core/recommendation/recommendation_screen.dart';
import 'package:ootdmate_frontend/services/auth-services/auth_services.dart';
import 'package:ootdmate_frontend/widgets/ui/custom_navbar_curved.dart';

import "package:ootdmate_frontend/screens/core/home/home_screen.dart";
import "package:ootdmate_frontend/screens/core/wardrobes/wardrobe_screen.dart";


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AuthServices _authServices = AuthServices();
  UserModel? _userProfile;
  bool _isLoadingProfile = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async{
    final profile = await _authServices.getProfile();
    if(!mounted) return;
    setState(() {
      _userProfile = profile;
      _isLoadingProfile = false;
    });
  }

  void _onProfileUpdated(UserModel updatedUser) {
    setState(() {
      _userProfile = updatedUser;
    });
  }

  List<Widget> get _pages => [
    HomeScreen(userProfile: _userProfile, avatarUrl: _userProfile?.avatarUrl, onProfileUpdated: _onProfileUpdated),
    WardrobeScreen(userProfile: _userProfile, avatarUrl: _userProfile?.avatarUrl, onProfileUpdated: _onProfileUpdated),
    RecommendationScreen(),
    FavoriteScreen()
  ];

  @override
  Widget build(BuildContext context) {

    if (_isLoadingProfile) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      
      extendBody: true, // DELETE IF DONT GIVE ANY EFFECT
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomNavBarCurved(
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}