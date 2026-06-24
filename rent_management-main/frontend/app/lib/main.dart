import 'package:flutter/material.dart';
import 'routes/app_routes.dart';

void main() {
  runApp( MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rent Management',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: AppRoutes.routes,
    );
  }
}