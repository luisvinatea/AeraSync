import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primary = Color(0xFF1E40AF);
  static const Color primaryDark = Color(0xFF141F41);

  // Background colors
  static const Color backgroundGradientStart = Color(0xFF60A5FA);
  static const Color backgroundGradientEnd = Color(0xFF1E40AF);
  static const Color cardBackground =
      Color(0xE6FFFFFF); // White with 90% opacity
  static const Color transparentBackground = Colors.transparent;

  // Text colors
  static const Color textPrimary = Color.fromARGB(255, 73, 120, 208);
  static const Color textSecondary =
      Color.fromARGB(186, 46, 92, 171); // White with 75% opacity
  static const Color textDark = Color(0xFF333333);
  static const Color textMuted = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);

  // Chart colors
  static const List<Color> chartColors = [
    Color(0xFF60A5FA), // blue
    Color(0xFF10B981), // green
    Color(0xFFFF9500), // orange
    Color(0xFF8B5CF6), // purple
    Color(0xFF0D9488), // teal
    Color(0xFFEC4899), // pink
    Color(0xFF4F46E5), // indigo
    Color(0xFFFCD34D), // amber
    Color(0xFF06B6D4), // cyan
    Color(0xFF84CC16), // lime
  ];

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFFCD34D);
  static const Color error = Colors.red;
  static const Color errorLight = Color(0x1AFF0000); // Red with 10% opacity
  static const Color successLight =
      Color(0x1A10B981); // Success with 10% opacity
  static const Color warningLight =
      Color(0x1AFCD34D); // Warning with 10% opacity

  // Input field colors
  static const Color inputBorder = Colors.transparent;
  static const Color inputFocused = Colors.transparent;
  static const Color inputBackground = Colors.transparent;

  // Button colors
  static const Color buttonPrimary = Color(0xFF1E40AF);
  static const Color buttonSuccess = Color(0xFF10B981);
  static const Color buttonDanger = Color(0xFFEF4444);
  static const Color buttonWarning = Color(0xFFF59E0B);

  // Slider colors
  static const Color sliderActive = Color(0xFF3B82F6);
  static const Color sliderInactive =
      Color(0x803B82F6); // Primary with 50% opacity

  // Shadow colors
  static const Color shadowColor = Color(0x40000000); // Black with 25% opacity

  // Border colors
  static const Color borderPrimary = Colors.transparent;
  static const Color borderLight = Colors.transparent;

  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 20.0;

  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Elevation
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;

  // Font sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 20.0;
  static const double fontSizeXLarge = 24.0;

  // Animation durations
  static const Duration animationShort = Duration(milliseconds: 300);
  static const Duration animationMedium = Duration(milliseconds: 500);
  static const Duration animationLong = Duration(milliseconds: 800);

  // Gradients
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundGradientStart, backgroundGradientEnd],
  );

  // Font families
  static const String fontFamilyHeadings = 'NotoSerif';
  static const String fontFamilyBody = 'NotoSans';
  static const String fontFamilyNumbers = 'Roboto';
  static const String fontFamilyLabels = 'DejaVuSans';

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontFamily: fontFamilyHeadings,
    fontSize: fontSizeXLarge,
    fontWeight: FontWeight.bold,
    color: textDark,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontFamily: fontFamilyHeadings,
    fontSize: fontSizeLarge,
    fontWeight: FontWeight.w500,
    color: textDark,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: fontSizeMedium,
    color: textDark,
  );

  static const TextStyle captionStyle = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: fontSizeSmall,
    color: textMuted,
  );

  static const TextStyle linkStyle = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: fontSizeMedium,
    color: primary,
    decoration: TextDecoration.underline,
  );

  static const TextStyle numberStyle = TextStyle(
    fontFamily: fontFamilyNumbers,
    fontSize: fontSizeMedium,
    fontWeight: FontWeight.w500,
    color: textDark,
  );

  static const TextStyle labelStyle = TextStyle(
    fontFamily: fontFamilyLabels,
    fontSize: fontSizeMedium,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  // Card styles
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(borderRadiusMedium),
    boxShadow: [
      BoxShadow(
        color: shadowColor,
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Text contrast rules
  static const Color darkBackgroundTextColor = Colors.white;
  static const Color lightBackgroundTextColor = primary;

  // Get text color based on background brightness
  static Color getTextColorForBackground(Color backgroundColor) {
    return backgroundColor.computeLuminance() < 0.5 
        ? darkBackgroundTextColor 
        : lightBackgroundTextColor;
  }

  // Button styles
  static ButtonStyle primaryButtonStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.all(buttonPrimary),
    foregroundColor: WidgetStateProperty.all(darkBackgroundTextColor),
    padding: WidgetStateProperty.all(
      const EdgeInsets.symmetric(
        horizontal: paddingLarge,
        vertical: paddingMedium,
      ),
    ),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
      ),
    ),
  );

  static ButtonStyle secondaryButtonStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.all(cardBackground),
    foregroundColor: WidgetStateProperty.all(buttonPrimary),
    padding: WidgetStateProperty.all(
      const EdgeInsets.symmetric(
        horizontal: paddingLarge,
        vertical: paddingMedium,
      ),
    ),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
      ),
    ),
  );

  static ButtonStyle successButtonStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.all(buttonSuccess),
    foregroundColor: WidgetStateProperty.all(darkBackgroundTextColor),
    padding: WidgetStateProperty.all(
      const EdgeInsets.symmetric(
        horizontal: paddingLarge,
        vertical: paddingMedium,
      ),
    ),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
      ),
    ),
  );

  static ButtonStyle dangerButtonStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.all(buttonDanger),
    foregroundColor: WidgetStateProperty.all(darkBackgroundTextColor),
    padding: WidgetStateProperty.all(
      const EdgeInsets.symmetric(
        horizontal: paddingLarge,
        vertical: paddingMedium,
      ),
    ),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
      ),
    ),
  );

  // Card styles as method
  static BoxDecoration getCardDecoration({double? elevation}) {
    return BoxDecoration(
      color: cardBackground,
      borderRadius: BorderRadius.circular(borderRadiusMedium),
      boxShadow: [
        BoxShadow(
          color: shadowColor.withAlpha(
              ((elevation != null ? 0.1 * elevation / elevationMedium : 0.1) * 255).toInt()).withAlpha(255),
          blurRadius: elevation ?? elevationMedium * 2,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Input decoration theme
  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    labelStyle: TextStyle(color: const Color.fromARGB(255, 41, 119, 220), fontWeight: FontWeight.bold),
    hintStyle: TextStyle(color: const Color.fromARGB(186, 42, 94, 198), fontWeight: FontWeight.bold),
    fillColor: const Color.fromARGB(0, 252, 247, 247).withAlpha(0),
    filled: true,
    errorStyle: TextStyle(color: error, fontSize: fontSizeSmall),
    contentPadding:
        EdgeInsets.symmetric(horizontal: paddingLarge, vertical: paddingMedium),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadiusSmall),
      borderSide: BorderSide(color: inputBorder, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadiusSmall),
      borderSide: BorderSide(color: inputBorder, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadiusSmall),
      borderSide: BorderSide(color: inputFocused, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadiusSmall),
      borderSide: BorderSide(color: error, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadiusSmall),
      borderSide: BorderSide(color: error, width: 1),
    ),
    floatingLabelBehavior: FloatingLabelBehavior.always,
  );
}
