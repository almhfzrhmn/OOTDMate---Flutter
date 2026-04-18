import 'package:flutter/material.dart';
// import 'dart:ui';

class BackgroundWrapper extends StatelessWidget {
  final Widget child;
  const BackgroundWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/images/main-bg.png',
            fit: BoxFit.cover,
          ),
        ),
        child,
      ],
    );
  }
}