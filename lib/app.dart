import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import 'core/theme.dart';
import 'features/onboarding/splash_page.dart';
import 'features/onboarding/welcome_page.dart';
import 'features/shell/app_shell.dart';
import 'state/app_state.dart';

class ClimaAgoraApp extends StatelessWidget {
  const ClimaAgoraApp({super.key, required this.state});
  final AppState state;

  static final _light = AppTheme.light();
  static final _dark = AppTheme.dark();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => MaterialApp(
          title: 'Clima Agora',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: state.messengerKey,
          theme: _light,
          darkTheme: _dark,
          themeMode: state.settings.themeMode,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          // Na web, permite arrastar listas (ex.: as horas) também com o mouse.
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: PointerDeviceKind.values.toSet(),
          ),
          home: const _Root(),
        ),
      ),
    );
  }
}

/// Splash → Boas-vindas (1ª vez) → app.
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  int _startTab = 0;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final Widget child;
    if (!app.bootstrapped) {
      child = const SplashPage(key: ValueKey('splash'));
    } else if (!app.onboarded) {
      child = WelcomePage(
        key: const ValueKey('welcome'),
        onDone: ({required manual}) => setState(() => _startTab = manual ? 1 : 0),
      );
    } else {
      child = AppShell(key: ValueKey('shell-$_startTab'), initialIndex: _startTab);
    }
    return AnimatedSwitcher(duration: const Duration(milliseconds: 400), child: child);
  }
}
