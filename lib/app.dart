import 'package:flutter/material.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
 
class FerreteriaApp extends StatelessWidget {
  const FerreteriaApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'POS Ferretería',
      theme: AppTheme.light,        // ✅ Tema centralizado
      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}
 