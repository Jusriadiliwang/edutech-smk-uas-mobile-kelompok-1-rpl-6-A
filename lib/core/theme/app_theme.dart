import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Brand Colors ──
  static const Color primary       = Color(0xFF2563EB);
  static const Color primaryDark   = Color(0xFF1D4ED8);
  static const Color primaryLight  = Color(0xFFEFF6FF);
  static const Color secondary     = Color(0xFF10B981);
  static const Color accent        = Color(0xFF6366F1);
  static const Color warning       = Color(0xFFF59E0B);
  static const Color danger        = Color(0xFFEF4444);
  static const Color info          = Color(0xFF06B6D4);

  // ── Neutral ──
  static const Color bg            = Color(0xFFF8FAFC);
  static const Color surface       = Colors.white;
  static const Color border        = Color(0xFFE2E8F0);
  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted     = Color(0xFF94A3B8);

  // ── Role Colors ──
  static const Color colorSiswa    = Color(0xFF3B82F6);
  static const Color colorGuru     = Color(0xFF7C3AED);
  static const Color colorWali     = Color(0xFFF59E0B);
  static const Color colorBK       = Color(0xFFEC4899);
  static const Color colorPiket    = Color(0xFF10B981);
  static const Color colorAdmin    = Color(0xFF6366F1);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: bg,
        error: danger,
      ),
      scaffoldBackgroundColor: bg,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: border,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // InputDecoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: danger),
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Inter', color: textMuted, fontSize: 14,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Inter', color: textSecondary, fontSize: 14,
        ),
      ),

      // Card
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
        margin: const EdgeInsets.symmetric(vertical: 5),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: primaryLight,
        labelStyle: const TextStyle(
          fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600,
          color: primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: border, thickness: 1, space: 1,
      ),

      // BottomNavigationBar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 11),
      ),

      // ListTile
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // Text
      textTheme: const TextTheme(
        displayLarge:   TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, color: textPrimary),
        displayMedium:  TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, color: textPrimary),
        headlineLarge:  TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: textPrimary),
        headlineMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: textPrimary),
        headlineSmall:  TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge:     TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: textPrimary),
        titleMedium:    TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: textPrimary),
        titleSmall:     TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge:      TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, color: textPrimary),
        bodyMedium:     TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, color: textSecondary),
        bodySmall:      TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, color: textMuted),
        labelLarge:     TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: textPrimary),
        labelMedium:    TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, color: textSecondary),
        labelSmall:     TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, color: textMuted),
      ),
    );
  }
}

/// Helper widget: kartu dengan border standard
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            )
          : Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
    );
  }
}

/// Helper widget: badge status berwarna
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor ?? color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
