import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
     await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found or could not be loaded. Ensure it exists in root.");
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl != null && supabaseKey != null) {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );
  } else {
      debugPrint("Warning: Supabase credentials not found in .env");
  }

  configureDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Littlewin',
          theme: AppTheme.lightTheme, // Default to light theme as per Explore design
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light, // Force light mode for now to match the request
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
