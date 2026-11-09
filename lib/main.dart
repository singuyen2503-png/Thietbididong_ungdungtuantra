import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'data/datasources/local_store.dart';
import 'presentation/features/auth/login_screen.dart';
import 'presentation/state/manager_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase chưa sẵn sàng, chỉ lưu cục bộ: $e');
  }
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final store = LocalStore(await SharedPreferences.getInstance());
  await store.migrate();
  runApp(
    ProviderScope(
      overrides: [localStoreProvider.overrideWithValue(store)],
      child: const PatrolApp(),
    ),
  );
}

class PatrolApp extends StatelessWidget {
  const PatrolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tactical Patrol Ops',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const LoginScreen(),
    );
  }
}
