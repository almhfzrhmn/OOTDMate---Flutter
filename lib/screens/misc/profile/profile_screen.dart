import 'package:flutter/material.dart';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';
import 'package:ootdmate_frontend/models/user_model.dart';
import 'package:ootdmate_frontend/services/auth-services/auth_services.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel? user;

  const ProfileScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    const Color headerGradientStart = AppTheme.primary;
    const Color headerGradientEnd = AppTheme.surface;

    final displayName = user?.fullName ?? 'Guest';
    final email = user?.email ?? '';
    final avatarUrl = user?.avatarUrl;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(
                top: 50.0,
                left: 20.0,
                right: 20.0,
                bottom: 30.0,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [headerGradientStart, headerGradientEnd],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(36.0),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildIconButton(
                        icon: Icons.arrow_back_ios_new,
                        onTap: () => Navigator.pop(context),
                      ),
                      Text(
                        "Profile",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 44), // For balance with back button
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.acidGreen,
                        width: 2.0,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 50.0,
                      backgroundColor: AppTheme.primarySecond,
                      backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? const Icon(
                              Icons.person_2,
                              size: 50,
                              color: AppTheme.acidGreen,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 4.0),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.settings,
                    title: "Settings",
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings coming soon')),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: "Help & Support",
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Help & Support coming soon')),
                      );
                    },
                  ),
                  const SizedBox(height: 10.0),
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: "Logout",
                    isDestructive: true,
                    onTap: () async {
                      await AuthServices().signOut();
                      if (context.mounted) {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(30),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: AppTheme.secondary,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDestructive ? AppTheme.error.withAlpha(50) : Colors.transparent,
          width: 1,
        )
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDestructive 
              ? AppTheme.error.withAlpha(30)
              : AppTheme.primary.withAlpha(80),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isDestructive ? AppTheme.error : AppTheme.acidGreen, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? AppTheme.error : AppTheme.textPrimary,
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(80),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondary, size: 16),
        ),
      ),
    );
  }
}
