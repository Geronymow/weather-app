import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../core/breakpoints.dart';
import '../../core/theme.dart';
import '../../models/place.dart';
import '../../services/http_json.dart';
import '../../services/location_service.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

/// 05 · Locais e busca.
///
/// [pane] = versão de painel lateral (layout expandido, lista + detalhes).
class PlacesPage extends StatefulWidget {
  const PlacesPage({super.key, required this.onOpenPlace, this.searchFocus, this.pane = false});

  /// Chamado depois de escolher um local (o shell volta para o Início).
  final VoidCallback onOpenPlace;
  final FocusNode? searchFocus;
  final bool pane;

  @override
  State<PlacesPage> createState() => _PlacesPageState();
}

class _PlacesPageState extends State<PlacesPage> {
  final _controller = TextEditingController();
  late final FocusNode _focus = widget.searchFocus ?? FocusNode();
  Timer? _debounce;
  List<Place>? _results;
  bool _searching = false;
  String? _searchError;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.read(context).refreshSaved();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    if (widget.searchFocus == null) _focus.dispose();
    super.dispose();
  }

  void _onQuery(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() {
        _results = null;
        _searching = false;
        _searchError = null;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  Future<void> _search(String q) async {
    final seq = ++_seq;
    try {
      final r = await AppScope.read(context).geocoding.search(q);
      if (!mounted || seq != _seq) return;
      setState(() {
        _results = r;
        _searchError = null;
        _searching = false;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _results = const [];
        _searchError = e is NetworkException ? 'Sem conexão para buscar.' : 'A busca falhou. Tente de novo.';
        _searching = false;
      });
    }
  }

  void _clear() {
    _controller.clear();
    _onQuery('');
  }

  Future<void> _open(Place p, {bool save = false}) async {
    final app = AppScope.read(context);
    if (save) unawaited(app.addPlace(p));
    unawaited(app.selectPlace(p));
    _clear();
    _focus.unfocus();
    widget.onOpenPlace();
  }

  Future<void> _useLocation() async {
    final app = AppScope.read(context);
    final r = await app.locate();
    if (!mounted) return;
    if (r.ok) {
      widget.onOpenPlace();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.message),
        action: r.status == LocationStatus.deniedForever
            ? SnackBarAction(label: 'Configurações', onPressed: app.location.openSettings)
            : null,
      ));
    }
  }

  Future<void> _confirmRemove(Place p) async {
    final app = AppScope.read(context);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.wb_sunny_outlined),
            title: Text('Ver previsão de ${p.name}'),
            onTap: () => Navigator.pop(ctx, false),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: ClimaTokens.statusDanger),
            title: const Text('Remover dos salvos'),
            onTap: () => Navigator.pop(ctx, true),
          ),
        ]),
      ),
    );
    if (ok == true) {
      await app.removePlace(p);
    } else if (ok == false) {
      await _open(p);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = ClimaColors.of(context);
    final searching = _results != null || _searching;
    final saved = app.savedPlaces;
    final gps = app.gpsPlace;
    final suggestions = suggestedPlaces.where((s) => !app.isSaved(s) && s.id != gps?.id).take(5).toList();
    final activeId = app.activePlace?.id;

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.pane)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Locais', style: ClimaText.headline.copyWith(color: c.textPrimary, fontWeight: FontWeight.w500)),
            ),
          // Campo de busca (pílula 56 dp)
          Material(
            color: c.surface2,
            shape: const StadiumBorder(),
            child: SizedBox(
              height: 56,
              child: Row(children: [
                const SizedBox(width: 20),
                Icon(Icons.search_rounded, color: c.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    onChanged: _onQuery,
                    onSubmitted: (q) {
                      final r = _results;
                      if (r != null && r.isNotEmpty) _open(r.first, save: true);
                    },
                    textInputAction: TextInputAction.search,
                    style: ClimaText.body.copyWith(color: c.textPrimary, fontSize: 16),
                    cursorColor: c.brand,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Buscar cidade, bairro ou CEP',
                      hintStyle: ClimaText.body.copyWith(color: c.textTertiary, fontSize: 16),
                    ),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  IconButton(tooltip: 'Limpar', onPressed: _clear, icon: Icon(Icons.close_rounded, color: c.textSecondary))
                else
                  const SizedBox(width: 12),
                const SizedBox(width: 4),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: app.locating ? null : _useLocation,
            icon: app.locating
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location_rounded),
            label: const Text('Usar minha localização atual'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
        ],
      ),
    );

    final List<Widget> body;
    if (searching) {
      body = [
        if (_searching) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        if (!_searching && _searchError != null) _Message(icon: Icons.wifi_off_rounded, text: _searchError!),
        if (!_searching && _searchError == null && (_results?.isEmpty ?? false))
          const _Message(icon: Icons.search_off_rounded, text: 'Nenhum local encontrado.'),
        if (!_searching && (_results?.isNotEmpty ?? false)) ...[
          const Overline('RESULTADOS'),
          for (final p in _results!)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: Icon(Icons.location_on_outlined, color: c.textSecondary),
              title: Text([?p.detail, p.name].join(', '), style: ClimaText.titleS.copyWith(color: c.textPrimary)),
              subtitle: Text(p.searchSubtitle, style: ClimaText.bodyS.copyWith(color: c.textSecondary)),
              trailing: app.isSaved(p)
                  ? Icon(Icons.bookmark_rounded, color: c.brand)
                  : IconButton(
                      tooltip: 'Salvar',
                      icon: Icon(Icons.bookmark_add_outlined, color: c.brand),
                      onPressed: () => app.addPlace(p),
                    ),
              onTap: () => _open(p, save: true),
            ),
        ],
      ];
    } else {
      body = [
        const Overline('SALVOS'),
        if (gps != null) ...[
          CityCard(
            place: gps,
            data: app.dataFor(gps),
            selected: widget.pane && activeId == gps.id,
            onTap: () => _open(gps),
          ),
          const SizedBox(height: 12),
        ],
        if (saved.isEmpty && gps == null)
          const _Message(icon: Icons.bookmark_border_rounded, text: 'Busque uma cidade para salvá-la aqui.'),
        // Arraste para reordenar; deslize para remover; toque longo para opções.
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: saved.length,
          onReorderItem: app.reorderPlaces,
          itemBuilder: (context, i) {
            final p = saved[i];
            return Padding(
              key: ValueKey(p.id),
              padding: const EdgeInsets.only(bottom: 12),
              child: Dismissible(
                key: ValueKey('d-${p.id}'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  app.removePlace(p);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${p.name} removido'),
                    action: SnackBarAction(label: 'Desfazer', onPressed: () => app.addPlace(p)),
                  ));
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: ClimaTokens.statusDanger.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.delete_outline_rounded),
                ),
                child: ReorderableDelayedDragStartListener(
                  index: i,
                  child: CityCard(
                    place: p,
                    data: app.dataFor(p),
                    selected: widget.pane && activeId == p.id,
                    onTap: () => _open(p),
                    onLongPress: () => _confirmRemove(p),
                  ),
                ),
              ),
            );
          },
        ),
        if (suggestions.isNotEmpty) ...[
          const Overline('SUGESTÕES'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in suggestions)
                GlassChip(icon: Icons.add_rounded, label: s.name, onTap: () => app.addPlace(s)),
            ],
          ),
        ],
        if (saved.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'Deslize para a esquerda para remover · toque e segure para mais opções.',
              textAlign: TextAlign.center,
              style: ClimaText.bodyS.copyWith(color: c.textTertiary),
            ),
          ),
      ];
    }

    return ColoredBox(
      color: c.bgBase,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: widget.pane ? double.infinity : kReadableMaxWidth),
            child: Column(children: [
              header,
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => Future.wait([
                    for (final p in [?gps, ...saved]) app.load(p),
                  ]),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: body,
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = ClimaColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(children: [
        Icon(icon, size: 36, color: c.textTertiary),
        const SizedBox(height: 8),
        Text(text, textAlign: TextAlign.center, style: ClimaText.body.copyWith(color: c.textSecondary)),
      ]),
    );
  }
}
