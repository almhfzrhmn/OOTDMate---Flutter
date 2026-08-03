import 'package:flutter/material.dart';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';

class NeumorphicTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final IconData prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const NeumorphicTextField({
    super.key,
    this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(borderRadius: BorderRadius.circular(200.0), boxShadow: [
        BoxShadow(
          color: AppTheme.textPrimary.withAlpha(100),
          blurRadius: 3,
          spreadRadius: 2,
          offset: const Offset(0.2, 0.3),
        ),
        BoxShadow(
          color: AppTheme.textPrimary.withAlpha(75),
          blurRadius: 2,
          spreadRadius: 2,
          blurStyle: BlurStyle.inner,
          offset: Offset(-2.0, -1.0)
        )
        
        
      ]),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,

        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,

        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          fillColor: AppTheme.mediumGrey,
          hintText: hintText,
          hintStyle: Theme.of(context).textTheme.labelMedium
        ),
      ),
    );
  }
}
