import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens do Design System "Clima Agora" (coleção Clima/Tokens no Figma).
class ClimaTokens {
  static const bgBase = Color(0xFF0A1233);
  static const surfaceSolid = Color(0xFF141E4A);
  static const surfaceSolid2 = Color(0xFF1C2860);
  static const brandPrimary = Color(0xFFA8C7FA);
  static const brandOnPrimary = Color(0xFF062E6F);
  static const accentSun = Color(0xFFFFC23D);
  static const accentRain = Color(0xFF5CC8FF);
  static const statusGood = Color(0xFF4ADE80);
  static const statusWarning = Color(0xFFFFB020);
  static const statusDanger = Color(0xFFFF5A5F);

  // Versões claras (tema "Claro").
  static const lightBgBase = Color(0xFFF2F5FC);
  static const lightSurfaceSolid = Color(0xFFFFFFFF);
  static const lightSurfaceSolid2 = Color(0xFFE6ECF8);
  static const lightBrandPrimary = Color(0xFF2F5FC4);
}

/// Cores semânticas que mudam com o tema (claro/escuro). Os widgets leem
/// sempre daqui, nunca de cores fixas, para que o tema funcione em tudo.
@immutable
class ClimaColors extends ThemeExtension<ClimaColors> {
  const ClimaColors({
    required this.bgBase,
    required this.surface,
    required this.surface2,
    required this.glassFill,
    required this.glassStroke,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.brand,
    required this.onBrand,
  });

  final Color bgBase;
  final Color surface;
  final Color surface2;
  final Color glassFill;
  final Color glassStroke;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color brand;
  final Color onBrand;

  static const dark = ClimaColors(
    bgBase: ClimaTokens.bgBase,
    surface: ClimaTokens.surfaceSolid,
    surface2: ClimaTokens.surfaceSolid2,
    glassFill: Color(0x1FFFFFFF), // 12%
    glassStroke: Color(0x2EFFFFFF), // 18%
    divider: Color(0x14FFFFFF), // 8%
    textPrimary: Colors.white,
    textSecondary: Color(0xBDFFFFFF), // 74%
    textTertiary: Color(0x8AFFFFFF), // 54%
    brand: ClimaTokens.brandPrimary,
    onBrand: ClimaTokens.brandOnPrimary,
  );

  static const light = ClimaColors(
    bgBase: ClimaTokens.lightBgBase,
    surface: ClimaTokens.lightSurfaceSolid,
    surface2: ClimaTokens.lightSurfaceSolid2,
    glassFill: Color(0x140A1233),
    glassStroke: Color(0x1F0A1233),
    divider: Color(0x140A1233),
    textPrimary: Color(0xFF0A1233),
    textSecondary: Color(0xBD0A1233),
    textTertiary: Color(0x8A0A1233),
    brand: ClimaTokens.lightBrandPrimary,
    onBrand: Colors.white,
  );

  static ClimaColors of(BuildContext context) =>
      Theme.of(context).extension<ClimaColors>() ?? dark;

  @override
  ClimaColors copyWith() => this;

  @override
  ClimaColors lerp(ClimaColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return ClimaColors(
      bgBase: l(bgBase, other.bgBase),
      surface: l(surface, other.surface),
      surface2: l(surface2, other.surface2),
      glassFill: l(glassFill, other.glassFill),
      glassStroke: l(glassStroke, other.glassStroke),
      divider: l(divider, other.divider),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      brand: l(brand, other.brand),
      onBrand: l(onBrand, other.onBrand),
    );
  }
}

/// Fundos dinâmicos conforme o tempo (gradiente vertical, 3 paradas).
enum Sky {
  sunny('Ensolarado', [Color(0xFF0B2A7A), Color(0xFF1F5FD0), Color(0xFF4C9BEA)]),
  partly('Parcialmente nublado', [Color(0xFF0B1646), Color(0xFF1D3FA0), Color(0xFF3C7FD8)]),
  cloudy('Nublado', [Color(0xFF1E293B), Color(0xFF334155), Color(0xFF64748B)]),
  rain('Chuva', [Color(0xFF0B1026), Color(0xFF1A2A5E), Color(0xFF34518F)]),
  storm('Tempestade', [Color(0xFF0B0A1F), Color(0xFF2A1B5E), Color(0xFF4C2C8F)]),
  night('Noite', [Color(0xFF020617), Color(0xFF131A45), Color(0xFF27306B)]);

  const Sky(this.label, this.colors);
  final String label;
  final List<Color> colors;

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
        stops: const [0, 0.55, 1],
      );
}

/// Estilos de texto Clima/* (Roboto).
class ClimaText {
  static TextStyle _r(double size, FontWeight w, double lh, [double ls = 0]) =>
      TextStyle(fontSize: size, fontWeight: w, height: lh / size, letterSpacing: ls);

  static final display = _r(96, FontWeight.w300, 104, -3);
  static final headlineL = _r(40, FontWeight.w400, 48, -1);
  static final headline = _r(28, FontWeight.w400, 36);
  static final titleL = _r(22, FontWeight.w400, 28);
  static final title = _r(18, FontWeight.w500, 24);
  static final titleS = _r(16, FontWeight.w500, 22);
  static final body = _r(14, FontWeight.w400, 20);
  static final bodyS = _r(12, FontWeight.w400, 16);
  static final label = _r(12, FontWeight.w500, 16, 0.24);
  static final overline = _r(11, FontWeight.w500, 16, 1.1);
}

class AppTheme {
  /// Roboto via google_fonts. Os testes desligam para não acessar a rede.
  static bool useGoogleFonts = true;

  static ThemeData dark() => _build(Brightness.dark, ClimaColors.dark);
  static ThemeData light() => _build(Brightness.light, ClimaColors.light);

  static ThemeData _build(Brightness b, ClimaColors c) {
    final scheme = ColorScheme.fromSeed(
      seedColor: ClimaTokens.brandPrimary,
      brightness: b,
    ).copyWith(
      primary: c.brand,
      onPrimary: c.onBrand,
      surface: c.bgBase,
      onSurface: c.textPrimary,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surface2,
      outline: c.glassStroke,
      outlineVariant: c.divider,
    );
    final base = ThemeData(useMaterial3: true, brightness: b, colorScheme: scheme);
    final textTheme = (useGoogleFonts ? GoogleFonts.robotoTextTheme(base.textTheme) : base.textTheme).apply(
      bodyColor: c.textPrimary,
      displayColor: c.textPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: c.bgBase,
      textTheme: textTheme,
      extensions: [c],
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: c.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: c.textPrimary,
        titleTextStyle: ClimaText.titleL.copyWith(color: c.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: b == Brightness.dark ? const Color(0xF00A1233) : c.surface,
        indicatorColor: c.brand.withValues(alpha: 0.24),
        surfaceTintColor: Colors.transparent,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => ClimaText.label.copyWith(
            color: s.contains(WidgetState.selected) ? c.textPrimary : c.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? c.brand : c.textSecondary,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: b == Brightness.dark ? const Color(0xF00A1233) : c.surface,
        indicatorColor: c.brand.withValues(alpha: 0.24),
        selectedIconTheme: IconThemeData(color: c.brand),
        unselectedIconTheme: IconThemeData(color: c.textSecondary),
        selectedLabelTextStyle: ClimaText.label.copyWith(color: c.textPrimary),
        unselectedLabelTextStyle: ClimaText.label.copyWith(color: c.textSecondary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onBrand : c.textTertiary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.brand : c.glassFill,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.transparent : c.glassStroke,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? c.brand.withValues(alpha: 0.24)
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.brand : c.textSecondary,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: c.glassStroke)),
          textStyle: WidgetStatePropertyAll(ClimaText.label),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.brand,
          foregroundColor: c.onBrand,
          minimumSize: const Size(48, 48),
          shape: const StadiumBorder(),
          textStyle: ClimaText.titleS,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.brand,
          side: BorderSide(color: c.glassStroke),
          minimumSize: const Size(48, 48),
          shape: const StadiumBorder(),
          textStyle: ClimaText.titleS.copyWith(fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.brand,
          minimumSize: const Size(48, 48),
          textStyle: ClimaText.titleS.copyWith(fontSize: 14),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.surface2,
        contentTextStyle: ClimaText.body.copyWith(color: c.textPrimary),
      ),
      dialogTheme: DialogThemeData(backgroundColor: c.surface),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: c.surface),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.brand),
    );
  }
}
