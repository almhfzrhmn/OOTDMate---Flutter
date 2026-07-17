// import 'package:flutter/material.dart';
// import 'services/api-services/api_services.dart';

// class TestScreen extends StatefulWidget {
//   const TestScreen({super.key});

//   @override
//   State<TestScreen> createState() => _TestScreenState();
// }

// class _TestScreenState extends State<TestScreen> {

//   final ApiServices _apiServices = ApiServices();
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _showData();
//   }

//   Future<void> _showData() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       await _apiServices.getUsers();
//     } catch (e) {
//       if(!mounted) return;
//       _showError("Error saat mengambil data! : ${e.toString()}");
//     } finally {
//       if(!mounted) return;
//       _isLoading = false;
//     }
//   }

//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//       )
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: SafeArea(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Center(
//                 child: Text("debug Screen"),
//               ), 
//               // Expanded(
//               //   child: ListView.builder(
//               //     itemCount: ,
//               //     itemBuilder: ,
//               //   ),
//               // )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }