import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../application/controllers/app_controller.dart';
import '../../application/controllers/auth_controller.dart';
import '../../application/controllers/theme_controller.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';

class WorkPulseApp extends StatefulWidget {
  const WorkPulseApp({super.key});

  @override
  State<WorkPulseApp> createState() => _WorkPulseAppState();
}

class _WorkPulseAppState extends State<WorkPulseApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthController>();
      await auth.init();
      if (!mounted) return;
      if (auth.authenticated) {
        await context.read<AppController>().load();
      } else {
        context.read<AppController>().clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final auth = context.watch<AuthController>();

    final textTheme = GoogleFonts.plusJakartaSansTextTheme();

    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFF2B31A),
      brightness: Brightness.light,
      primary: const Color(0xFFF2B31A),
      onPrimary: const Color(0xFF2F3449),
      secondary: const Color(0xFF4A4F66),
      onSecondary: Colors.white,
      surface: const Color(0xFFFFFFFF),
      onSurface: const Color(0xFF404459),
      onSurfaceVariant: const Color(0xFF7D8091),
      outline: const Color(0xFFD8D9E3),
      outlineVariant: const Color(0xFFE7E8EF),
      surfaceContainerHighest: const Color(0xFFF1F0F7),
    );

    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFF2B31A),
      brightness: Brightness.dark,
      primary: const Color(0xFFF2B31A),
      onPrimary: const Color(0xFF2A2E43),
      secondary: const Color(0xFFAEB2C7),
      onSecondary: const Color(0xFF2F3449),
      surface: const Color(0xFF34384F),
      onSurface: const Color(0xFFE7E5F1),
      onSurfaceVariant: const Color(0xFFABAFC1),
      outline: const Color(0xFF4A4E65),
      outlineVariant: const Color(0xFF41455E),
      surfaceContainerHighest: const Color(0xFF3A3E57),
    );

    ThemeData buildTheme(ColorScheme scheme, Brightness brightness) {
      return ThemeData(
        useMaterial3: true,
        brightness: brightness,
        colorScheme: scheme,
        scaffoldBackgroundColor: brightness == Brightness.light
            ? const Color(0xFFF5F3F8)
            : const Color(0xFF2C3147),
        textTheme: textTheme.copyWith(
          bodyLarge: textTheme.bodyLarge?.copyWith(
            fontSize: 13.2,
            color: scheme.onSurface,
          ),
          bodyMedium: textTheme.bodyMedium?.copyWith(
            fontSize: 12.2,
            color: scheme.onSurface,
          ),
          bodySmall: textTheme.bodySmall?.copyWith(
            fontSize: 10.8,
            color: scheme.onSurfaceVariant,
          ),
          titleMedium: textTheme.titleMedium?.copyWith(
            fontSize: 14.2,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: brightness == Brightness.dark
              ? const Color(0xFF2C3147)
              : const Color(0xFFF5F3F8),
          surfaceTintColor: Colors.transparent,
          foregroundColor: scheme.onSurface,
          systemOverlayStyle: brightness == Brightness.dark
              ? SystemUiOverlayStyle.light.copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: const Color(0xFF2C3147),
                  systemNavigationBarIconBrightness: Brightness.light,
                )
              : SystemUiOverlayStyle.dark.copyWith(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.dark,
                  statusBarBrightness: Brightness.light,
                  systemNavigationBarColor: const Color(0xFFF5F3F8),
                  systemNavigationBarIconBrightness: Brightness.dark,
                ),
          titleTextStyle: textTheme.titleMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: brightness == Brightness.light ? 1.4 : 0,
          color: brightness == Brightness.light ? Colors.white : const Color(0xFF34384F),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: brightness == Brightness.light
                  ? const Color(0xFFE7E8EF)
                  : const Color(0xFF4A4E65),
            ),
          ),
          margin: EdgeInsets.zero,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: brightness == Brightness.light
              ? Colors.white
              : const Color(0xFF34384F),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: BorderSide(
              color: brightness == Brightness.light
                  ? const Color(0xFFE7E8EF)
                  : const Color(0xFF4A4E65),
            ),
          ),
          titleTextStyle: textTheme.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
          contentTextStyle: textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            color: scheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          filled: true,
          fillColor: brightness == Brightness.light
              ? Colors.white
              : const Color(0xFF3A3E57),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          hintStyle: TextStyle(
            fontSize: 11.8,
            color: scheme.onSurfaceVariant,
          ),
          labelStyle: TextStyle(
            fontSize: 11.8,
            color: scheme.onSurfaceVariant,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.primary, width: 1.4),
          ),
        ),
        chipTheme: ChipThemeData(
          side: BorderSide(color: scheme.outlineVariant),
          labelStyle: TextStyle(fontSize: 10.8, color: scheme.onSurface),
          backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            elevation: 0,
            backgroundColor: scheme.primary,
            foregroundColor: const Color(0xFF2F3449),
            textStyle: const TextStyle(fontSize: 12.2, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: scheme.outlineVariant),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          ),
        ),
        listTileTheme: ListTileThemeData(
          dense: true,
          textColor: scheme.onSurface,
          iconColor: scheme.onSurfaceVariant,
          visualDensity: const VisualDensity(vertical: -1.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          indicatorColor: brightness == Brightness.light
              ? const Color(0xFFFFE5A6)
              : const Color(0xFF42465D),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: states.contains(WidgetState.selected)
                  ? scheme.onSurface
                  : scheme.onSurfaceVariant,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              size: 22,
              color: states.contains(WidgetState.selected)
                  ? scheme.onSurface
                  : scheme.onSurfaceVariant,
            ),
          ),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 68,
        ),
      );
    }

    final isDark = themeController.mode == ThemeMode.dark;
    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: const Color(0xFF2C3147),
            systemNavigationBarIconBrightness: Brightness.light,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: const Color(0xFFF5F3F8),
            systemNavigationBarIconBrightness: Brightness.dark,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'WorkPulse',
        themeMode: themeController.mode,
        theme: buildTheme(lightScheme, Brightness.light),
        darkTheme: buildTheme(darkScheme, Brightness.dark),
        home: auth.authenticated ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }
}
