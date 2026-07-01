import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: AppColors.lightPrimary,
          secondary: AppColors.lightSecondary,
          surface: AppColors.lightSurface,
          onPrimary: AppColors.white,
          onSecondary: AppColors.white,
          onSurface: AppColors.lightText,
        ),
        scaffoldBackgroundColor: AppColors.lightBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.lightSurface,
          foregroundColor: AppColors.lightText,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.lightSurface,
          selectedItemColor: AppColors.lightPrimary,
          unselectedItemColor: AppColors.lightSubtitle,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: AppColors.lightCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.lightSecondary;
            return AppColors.lightSubtitle;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.lightSecondary.withOpacity(0.4);
            }
            return AppColors.lightSubtitle.withOpacity(0.3);
          }),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.lightDivider,
          thickness: 0.5,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          hintStyle: TextStyle(color: AppColors.lightSubtitle.withOpacity(0.7)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.white,
          elevation: 4,
          shape: CircleBorder(),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.lightPrimary,
          selectionColor: AppColors.lightSecondary,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.darkPrimary,
          secondary: AppColors.darkSecondary,
          surface: AppColors.darkSurface,
          onPrimary: AppColors.darkBackground,
          onSecondary: AppColors.darkBackground,
          onSurface: AppColors.darkText,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkSurface,
          foregroundColor: AppColors.darkText,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.darkSurface,
          selectedItemColor: AppColors.darkText,
          unselectedItemColor: AppColors.darkSubtitle,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: AppColors.darkCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.darkAccent;
            return AppColors.darkSubtitle;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.darkAccent.withOpacity(0.4);
            }
            return AppColors.darkSubtitle.withOpacity(0.3);
          }),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.darkDivider,
          thickness: 0.5,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          hintStyle: TextStyle(color: AppColors.darkSubtitle.withOpacity(0.7)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkBackground,
          elevation: 4,
          shape: CircleBorder(),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.darkPrimary,
          selectionColor: AppColors.darkSecondary,
        ),
      );
}
