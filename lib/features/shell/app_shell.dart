import 'package:material_ui/material_ui.dart';

import '../../core/breakpoints.dart';
import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../home/home_page.dart';
import '../places/places_page.dart';
import '../settings/settings_page.dart';

/// Navegação principal adaptável (Material window size classes):
///  * compacto  (< 600)  → NavigationBar inferior
///  * médio  (600–839)   → NavigationRail lateral com FAB de busca
///  * expandido (≥ 840)  → Rail + 2 painéis no Início (locais | detalhes)
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex;
  static final _darkTheme = AppTheme.dark();
  final _searchFocus = FocusNode();

  static const _destinations = [
    (Icons.home_outlined, Icons.home_rounded, 'Início'),
    (Icons.bookmark_border_rounded, Icons.bookmark_rounded, 'Locais'),
    (Icons.settings_outlined, Icons.settings_rounded, 'Ajustes'),
  ];

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  void _go(int i) => setState(() => _index = i);

  void _openSearch(WindowSize size) {
    if (!(size == WindowSize.expanded && _index == 0)) _go(1);
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocus.requestFocus());
  }

  @override
  Widget build(BuildContext context) {
    final size = windowSizeOf(context);
    final c = ClimaColors.of(context);

    final Widget page = switch (_index) {
      0 when size == WindowSize.expanded => Row(children: [
          SizedBox(
            width: 380,
            child: PlacesPage(pane: true, searchFocus: _searchFocus, onOpenPlace: () {}),
          ),
          VerticalDivider(width: 1, color: c.divider),
          Expanded(child: HomePage(onSearch: () => _openSearch(size), showSearchAction: false)),
        ]),
      0 => HomePage(onSearch: () => _openSearch(size)),
      1 => PlacesPage(searchFocus: _searchFocus, onOpenPlace: () => _go(0)),
      _ => const SettingsPage(),
    };

    // Sobre o céu do Início a barra é sempre escura, como no protótipo.
    final skyNav = _index == 0 && AppScope.of(context).settings.dynamicBackground;
    Widget navTheme(Widget child) => skyNav ? Theme(data: _darkTheme, child: child) : child;

    if (size == WindowSize.compact) {
      return Scaffold(
        body: page,
        bottomNavigationBar: navTheme(NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _go,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: d.$3),
          ],
        )),
      );
    }

    return Scaffold(
      body: Row(children: [
        navTheme(NavigationRail(
          selectedIndex: _index,
          onDestinationSelected: _go,
          labelType: NavigationRailLabelType.all,
          groupAlignment: -0.85,
          leading: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: FloatingActionButton(
              heroTag: 'buscar',
              tooltip: 'Buscar cidade',
              elevation: 0,
              backgroundColor: c.brand,
              foregroundColor: c.onBrand,
              onPressed: () => _openSearch(size),
              child: const Icon(Icons.search_rounded),
            ),
          ),
          destinations: [
            for (final d in _destinations)
              NavigationRailDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: Text(d.$3)),
          ],
        )),
        VerticalDivider(width: 1, color: c.divider),
        Expanded(child: page),
      ]),
    );
  }
}
