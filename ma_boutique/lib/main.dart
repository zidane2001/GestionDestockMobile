import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
import 'core/theme.dart';
import 'data/database.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/verrouillage_screen.dart';
import 'services/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!supabaseUrl.startsWith('REMPLACEZ-MOI') && !supabaseAnonKey.startsWith('REMPLACEZ-MOI')) {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  }
  await _demanderPermissions();
  final provider = AppProvider(sync: SyncService(DatabaseHelper.instance));
  await provider.initialize();
  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: const MaBoutiqueApp(),
    ),
  );
}

Future<void> _demanderPermissions() async {
  await [
    Permission.camera,
    Permission.photos,
    Permission.notification,
  ].request();
}

class MaBoutiqueApp extends StatelessWidget {
  const MaBoutiqueApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return MaterialApp(
      title: 'Ma Boutique',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(AppColors.clair, Brightness.light),
      darkTheme: buildTheme(AppColors.sombre, Brightness.dark),
      themeMode: provider.sombre ? ThemeMode.dark : ThemeMode.light,
      home: provider.session == null
          ? const SplashScreen()
          : provider.verrouille
              ? const VerrouillageScreen()
              : const HomeScreen(),
    );
  }
}