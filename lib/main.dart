import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/note.dart';
import 'providers/note_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(DesignerNotesApp(prefs: prefs));
}

class DesignerNotesApp extends StatelessWidget {
  final SharedPreferences prefs;
  
  const DesignerNotesApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(prefs),
        ),
        ChangeNotifierProvider(
          create: (_) => NoteProvider(prefs),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Designer Notes',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: _createLightTheme(),
            darkTheme: _createDarkTheme(),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }

  ThemeData _createLightTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'SF Pro Display', // iOS風のフォント
      colorScheme: const ColorScheme.light(
        // shadcn/ui風のカラーパレット
        primary: Color(0xFF09090B),
        onPrimary: Color(0xFFFAFAFA),
        secondary: Color(0xFFF1F5F9),
        onSecondary: Color(0xFF0F172A),
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF09090B),
        surfaceContainerHighest: Color(0xFFF8FAFC),
        outline: Color(0xFFE2E8F0),
        outlineVariant: Color(0xFFF1F5F9),
        surfaceVariant: Color(0xFFF8FAFC),
        onSurfaceVariant: Color(0xFF64748B),
        error: Color(0xFFEF4444),
        onError: Color(0xFFFFFFFF),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        color: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        foregroundColor: Color(0xFF09090B),
        titleTextStyle: TextStyle(
          color: Color(0xFF09090B),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF09090B),
          foregroundColor: const Color(0xFFFAFAFA),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          foregroundColor: const Color(0xFF09090B),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF09090B),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF09090B), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.02,
          color: Color(0xFF09090B),
        ),
        displayMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02,
          color: Color(0xFF09090B),
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.01,
          color: Color(0xFF09090B),
        ),
        headlineLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF09090B),
        ),
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF09090B),
        ),
        headlineSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF09090B),
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF09090B),
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF09090B),
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF64748B),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFF09090B),
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF09090B),
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0xFF64748B),
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF09090B),
        ),
        labelMedium: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFF64748B),
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  ThemeData _createDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'SF Pro Display',
      colorScheme: const ColorScheme.dark(
        // shadcn/ui ダークモードのカラーパレット
        primary: Color(0xFFFAFAFA),
        onPrimary: Color(0xFF09090B),
        secondary: Color(0xFF1E293B),
        onSecondary: Color(0xFFF8FAFC),
        surface: Color(0xFF09090B),
        onSurface: Color(0xFFFAFAFA),
        surfaceContainerHighest: Color(0xFF1E293B),
        outline: Color(0xFF334155),
        outlineVariant: Color(0xFF1E293B),
        surfaceVariant: Color(0xFF0F172A),
        onSurfaceVariant: Color(0xFF94A3B8),
        error: Color(0xFFF87171),
        onError: Color(0xFF09090B),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
        color: const Color(0xFF09090B),
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Color(0xFF09090B),
        surfaceTintColor: Colors.transparent,
        foregroundColor: Color(0xFFFAFAFA),
        titleTextStyle: TextStyle(
          color: Color(0xFFFAFAFA),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFFFAFAFA),
          foregroundColor: const Color(0xFF09090B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF334155)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          foregroundColor: const Color(0xFFFAFAFA),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFFAFAFA),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFFAFAFA), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.02,
          color: Color(0xFFFAFAFA),
        ),
        displayMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02,
          color: Color(0xFFFAFAFA),
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.01,
          color: Color(0xFFFAFAFA),
        ),
        headlineLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFFFAFAFA),
        ),
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFFFAFAFA),
        ),
        headlineSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFFFAFAFA),
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFFFAFAFA),
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFFFAFAFA),
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF94A3B8),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFFFAFAFA),
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFFFAFAFA),
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0xFF94A3B8),
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFFFAFAFA),
        ),
        labelMedium: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFF94A3B8),
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
