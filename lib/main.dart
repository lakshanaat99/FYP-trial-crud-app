import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'views/dashboard/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase using the provided URL and Anon Key
  await Supabase.initialize(
    url: 'https://qmxudhipjjijesjtcfzx.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFteHVkaGlwamppamVzanRjZnp4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE0MzEwODIsImV4cCI6MjA5NzAwNzA4Mn0.Dt3uHUkydmltOLiZbYBxnkmGeYUfryu-5IINKfYct80',
  );

  runApp(const SupabaseCrudApp());
}

class SupabaseCrudApp extends StatelessWidget {
  const SupabaseCrudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase CRUD Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DashboardPage(),
    );
  }
}
