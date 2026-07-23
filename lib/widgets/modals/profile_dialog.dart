import 'package:flutter/material.dart';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';

class ProfileDialog extends StatelessWidget {
  const ProfileDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsetsGeometry.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primarySecond,
              child: Icon(
                Icons.person_2,
                size: 40,
                color: AppTheme.acidGreen,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Roman",
            ),
            const Text(
              "@gmail.com",
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                //
              },
              child: Text(
                "Logout"
              ),
            ),
          ],
        ),
      ),
    );
  }
}