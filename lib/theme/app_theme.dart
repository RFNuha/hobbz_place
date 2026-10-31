import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';     
import 'app_colors.dart';                            

class _Palette {
  final Brightness brightness;  
  final Color background, surface, surfaceVariant, primaryContainer, outline;
  final Color primary, primaryLight, accent, onPrimary, cardLink;
  final Color textPrimary, textSecondary, textMuted;
  final Color navBackground, navSelected, navUnselected;
  final Color fabBackground, fabForeground;

  const _Palette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.primaryContainer,
    required this.outline,
    required this.primary,
    required this.primaryLight,
    required this.accent,
    required this.onPrimary,
    required this.cardLink,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.navBackground,
    required this.navSelected,
    required this.navUnselected,
    required this.fabBackground,
    required this.fabForeground,
  });
}

class AppTheme {
  AppTheme._();  

  // Dark Theme
  static ThemeData get darkTheme => _buildTheme(const _Palette(
        brightness: Brightness.dark,
        background: DarkColors.background,
        surface: DarkColors.surface,
        surfaceVariant: DarkColors.surfaceVariant,
        primaryContainer: DarkColors.primaryContainer,
        outline: DarkColors.outline,
        primary: DarkColors.primary,
        primaryLight: DarkColors.primaryLight,
        accent: DarkColors.accent,
        onPrimary: DarkColors.onPrimary,
        cardLink: DarkColors.cardLink,
        textPrimary: DarkColors.textPrimary,
        textSecondary: DarkColors.textSecondary,
        textMuted: DarkColors.textMuted,
        navBackground: DarkColors.navBackground,
        navSelected: DarkColors.navSelected,
        navUnselected: DarkColors.navUnselected,
        fabBackground: DarkColors.fabBackground,
        fabForeground: DarkColors.fabForeground,
      ));

  // Light Theme
  static ThemeData get lightTheme => _buildTheme(const _Palette(
        brightness: Brightness.light,
        background: LightColors.background,
        surface: LightColors.surface,
        surfaceVariant: LightColors.surfaceVariant,
        primaryContainer: LightColors.primaryContainer,
        outline: LightColors.outline,
        primary: LightColors.primary,
        primaryLight: LightColors.primaryLight,
        accent: LightColors.accent,
        onPrimary: LightColors.onPrimary,
        cardLink: LightColors.cardLink,
        textPrimary: LightColors.textPrimary,
        textSecondary: LightColors.textSecondary,
        textMuted: LightColors.textMuted,
        navBackground: LightColors.navBackground,
        navSelected: LightColors.navSelected,
        navUnselected: LightColors.navUnselected,
        fabBackground: LightColors.fabBackground,
        fabForeground: LightColors.fabForeground,
      ));

  static ThemeData _buildTheme(_Palette p) {
    final colorScheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,                  
      onPrimary: p.onPrimary,                
      primaryContainer: p.primaryContainer, 
      onPrimaryContainer: p.textPrimary,
      secondary: p.accent,                   
      onSecondary: p.onPrimary,
      secondaryContainer: p.surfaceVariant,
      onSecondaryContainer: p.textPrimary,
      tertiary: p.cardLink,

      onTertiary: p.onPrimary,
      error: const Color(0xFFE5484D),
      onError: Colors.white,
      surface: p.surface,                   
      onSurface: p.textPrimary,              
      onSurfaceVariant: p.textSecondary,     
      surfaceContainerLowest: p.background,
      surfaceContainerLow: p.background,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surface,
      surfaceContainerHighest: p.surfaceVariant,
      outline: p.outline,                    
      outlineVariant: p.outline.withValues(alpha: 0.5),
      surfaceTint: Colors.transparent,
    );

    // Text
    final bodyText = GoogleFonts.poppinsTextTheme(TextTheme(
      titleMedium: TextStyle(
        color: p.textPrimary,
        fontWeight: FontWeight.w500, 
        fontSize: 16,
      ),
      titleSmall: TextStyle(
        color: p.textPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      bodyLarge: TextStyle(color: p.textPrimary, fontSize: 16),
      bodyMedium: TextStyle(color: p.textSecondary, fontSize: 14),
      bodySmall: TextStyle(color: p.textMuted, fontSize: 12),
      labelLarge: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600),
    ));

    final textTheme = bodyText.copyWith(
      headlineLarge: GoogleFonts.lora(
        color: p.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 30,
      ),
      headlineMedium: GoogleFonts.lora(
        color: p.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 26,
      ),
      headlineSmall: GoogleFonts.lora(
        color: p.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 22,
      ),
      titleLarge: GoogleFonts.lora(
        color: p.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    );

    return ThemeData(
      useMaterial3: true,           
      brightness: p.brightness,    
      colorScheme: colorScheme,
      textTheme: textTheme,

      scaffoldBackgroundColor: p.background,

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary, 
        elevation: 0,                    
        scrolledUnderElevation: 0,       
        centerTitle: true,               
        titleTextStyle: GoogleFonts.lora(
          color: p.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: p.surface,          
        elevation: 2,              
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), 
          side: BorderSide(color: p.outline),
        ),
      ),

      // NavigationBar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.navBackground,
        indicatorColor: p.navSelected.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? p.navSelected
              : p.navUnselected,
        )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? p.navSelected
              : p.navUnselected,
        )),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.fabBackground,
        foregroundColor: p.fabForeground,
        shape: const CircleBorder(),     
      ),

      // filled buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,                    
        fillColor: p.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.primary, width: 2),
        ),
        hintStyle: TextStyle(color: p.textMuted),
        labelStyle: TextStyle(color: p.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceVariant,
        selectedColor: p.primary,
        checkmarkColor: p.onPrimary,
        labelStyle: TextStyle(color: p.textPrimary),
        side: BorderSide(color: p.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Checkboxes
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? p.primaryContainer : null),
        checkColor: WidgetStatePropertyAll(p.primary),
      ),

      // Dividers
      dividerTheme: DividerThemeData(color: p.outline, thickness: 1),
    );
  }
}
