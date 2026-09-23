import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/favorite_provider.dart';
import 'providers/settings_provider.dart';
import 'widgets/pokedex_frame.dart';
import 'services/authentication_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // โหลด Settings ที่เคยบันทึกไว้ก่อนเปิดแอป
  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(
          create: (context) {
            return FavoriteProvider();
          },
        ),
      ],
      child: const PokedexApp(),
    ),
  );
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<SettingsProvider>().themeMode;

    return MaterialApp(
      title: 'Pokédec',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: pokedexTheme(Brightness.light),
      darkTheme: pokedexTheme(Brightness.dark),
      //* ครอบทุกหน้าด้วยกรอบเครื่อง Pokédec
      builder: (context, child) {
        return PokedexFrame(child: child!);
      },
      //* login แล้วไป Home, ยังไม่ login ไป LoginPage (สลับอัตโนมัติ)
      home: StreamBuilder<User?>(
        stream: AuthenticationService().authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: Icon(Icons.catching_pokemon, size: 96, color: Colors.red)),
            );
          }
          return snapshot.hasData ? const HomePage() : const LoginPage();
        },
      ),
    );
  }
}
