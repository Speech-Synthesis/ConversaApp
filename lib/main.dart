import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/home/home_screen.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(
    const ProviderScope(
      child: ConversaVoiceApp(),
    ),
  );
}

class ConversaVoiceApp extends ConsumerWidget {
  const ConversaVoiceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'ConversaVoice',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: _buildLightTheme(context),
      darkTheme: _buildDarkTheme(context),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildDarkTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1E1E2E),
      primaryColor: const Color(0xFF6C63FF),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6C63FF),
        secondary: Color(0xFF00BFA5),
        surface: Color(0xFF1E1E2E),
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        Theme.of(context).textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      useMaterial3: true,
    );
  }

  ThemeData _buildLightTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      primaryColor: const Color(0xFF6C63FF),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6C63FF),
        secondary: Color(0xFF00BFA5),
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        Theme.of(context).textTheme.apply(
          bodyColor: const Color(0xFF1E1E2E),
          displayColor: const Color(0xFF1E1E2E),
        ),
      ),
      useMaterial3: true,
    );
  }
}
