import "package:flutter/material.dart";
import "package:ootdmate_frontend/core/theme/app_theme.dart";
import "package:ootdmate_frontend/models/user_model.dart";
import 'package:ootdmate_frontend/widgets/modals/profile_dialog.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subTitle;
  final String? avatarUrl;
  final String? username;
  final VoidCallback? onProfileTap;
  final UserModel? currentUser;
  final bool showAvatar;
  final ValueChanged<UserModel>? onProfileUpdated;

  const AppHeader({
    super.key,
    required this.title,
    required this.subTitle,
    this.currentUser,
    this.avatarUrl,
    this.username,
    this.onProfileTap,
    this.showAvatar = true,
    this.onProfileUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = username ?? currentUser?.fullName ?? 'Guest';
    final displayAvatar = avatarUrl ?? currentUser?.avatarUrl;

    return SafeArea(
      child: Container(
        color: AppTheme.primary,
        padding: const EdgeInsets.only(
          top: 60.0,
          left: 24.0,
          right: 24.0,
          bottom: 16.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(subTitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    letterSpacing: -0.1
                  )),
                ],
              ),
            ),
            if (showAvatar)
              GestureDetector(
                onTap: () {
                  if (onProfileTap != null) {
                    onProfileTap!();
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) => ProfileDialog(
                        user: currentUser,
                        onProfileUpdated: onProfileUpdated,
                      ),
                    );
                  }
                },
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.secondary,
                  backgroundImage:
                      (displayAvatar != null && displayAvatar.isNotEmpty)
                      ? NetworkImage(displayAvatar)
                      : null,
                  child: (displayAvatar == null || displayAvatar.isEmpty)
                      ? Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'G',
                          style: const TextStyle(color: Colors.white),
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(140.0);
}
