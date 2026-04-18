import 'package:flutter/material.dart';
import 'package:ootdmate_frontend/services/auth-services/auth_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authServices = AuthServices();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final _isLogin = false;

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}