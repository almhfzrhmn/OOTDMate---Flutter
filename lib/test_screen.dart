import 'package:flutter/material.dart';
import 'package:ootdmate_frontend/widgets/ui/flip_card.dart';
// import 'package:ootdmate_frontend/core/theme/app_theme.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child : Center(
          child : Column(
            children : [
              SizedBox(height: 20),
              Text(
                "Flip Card Test",
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(height: 20),
              FlipCard(),
            ]
          )
        )
      )
    );
  }
}