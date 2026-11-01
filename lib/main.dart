import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/datasources/local_store.dart';
import 'presentation/features/auth/login_screen.dart';
import 'presentation/state/manager_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E17),
        primaryColor: const Color(0xFF00FF9D),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0E17),
          elevation: 0,
        ),
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}
