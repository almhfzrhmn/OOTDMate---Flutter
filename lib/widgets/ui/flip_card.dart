import 'package:flutter/material.dart';
import 'dart:math';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';
import 'package:ootdmate_frontend/widgets/charts/wardrobe_donut_chart.dart';

class FlipCard extends StatefulWidget {
  const FlipCard({super.key});

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>  with SingleTickerProviderStateMixin{
  late AnimationController _controller;

  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration : const Duration(milliseconds: 500),
    );
  }

  void _flipCard() {
    if (_controller.isAnimating) return;

    if (_showFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }

    setState(() {
      _showFront = !_showFront;
    });
  }

  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap : _flipCard,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * pi;

          return Transform(
            alignment : Alignment.center,
            transform : Matrix4.identity()
              ..setEntry(3, 2 ,0.001)
              ..rotateX(angle),
            child : _controller.value <= 0.5
              ? _buildFront()
              : Transform(
                alignment : Alignment.center,
                transform : Matrix4.rotationX(pi),
                child : _buildBack(),
              ),
          );
        },
      ),
    );
  }
  Widget _buildFront() {
    return Container(
      height : 400, 
      width : 300,
      decoration: BoxDecoration(
        color: AppTheme.secondary,
        borderRadius : BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: WardrobeDonutChart(
          categories: {"T-shirt": 5, "Pants": 4, "Jacket": 3},
          totalItems: 12,
        ),
      )
    );
  }

  Widget _buildBack() {
    return Container(
      height : 200,
      width : 300,
      decoration : BoxDecoration(
        color : AppTheme.deepTeal,
        borderRadius : BorderRadius.circular(20),
      ),
      child : Center(
        child: Text(
          "BACK",
          style : Theme.of(context).textTheme.labelSmall,
        ),
      )
    );
  }
}