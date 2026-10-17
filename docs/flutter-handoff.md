# Handoff Figma → Flutter

## Pacotes sugeridos
| Necessidade | Pacote |
|---|---|
| Localização + permissão | `geolocator`, `permission_handler` |
| HTTP | `dio` (ou `http`) |
| Estado | `flutter_riverpod` |
| Data/hora em pt-BR e fuso | `intl` (`DateFormat('EEEE, d \'de\' MMMM', 'pt_BR')`), `timezone` |
| Cache offline | `hive` / `shared_preferences` |
| Background + notificações | `workmanager`, `flutter_local_notifications` |
| Fonte | `google_fonts` (Roboto) |
| Ícones | `material_symbols_icons` (Rounded) |

## Estrutura de pastas proposta
```
lib/
  main.dart
  core/theme/        # tokens (Variables Clima/Tokens) → ThemeData, TextTheme, ThemeExtension<SkyGradients>
  core/breakpoints.dart
  data/              # open_meteo_api.dart, nominatim_api.dart, inmet_api.dart
  domain/            # Weather, HourlyForecast, DailyForecast, AirQuality, Alert, Place
  features/
    onboarding/      # Splash, Boas-vindas, permissão
    home/            # Início (hero, horas, 7 dias, grade de métricas, sol, ar)
    places/          # Locais e busca
    alerts/          # Alertas + preferências de notificação
    settings/        # Ajustes (unidades, tema, localização)
```

## Mapeamento de componentes
| Figma | Flutter |
|---|---|
| Frame com Auto Layout vertical/horizontal | `Column` / `Row` (`spacing:` = itemSpacing) |
| Fill container | `Expanded` / `Flexible` |
| Hug contents | `MainAxisSize.min` |
| “Conteúdo (rolagem)” | `CustomScrollView` + `SliverList` |
| Lista horizontal das horas | `ListView.separated(scrollDirection: Axis.horizontal)` |
| Card de vidro | `ClipRRect` + `BackdropFilter(ImageFilter.blur(sigmaX: 15))` + `Container` com cor `glass/fill` |
| Grade de métricas (2×/3×) | `GridView.count(crossAxisCount: width < 600 ? 2 : 3)` |
| Faixa de temperatura (7 dias) | `LayoutBuilder` + `FractionallySizedBox` |
| Navigation bar / rail | `NavigationBar` (< 600) / `NavigationRail` (≥ 600) |
| Chips (máx/mín, sugestões) | `Chip` / `ActionChip` |
| Segmented | `SegmentedButton` |
| Switch | `Switch` (M3) |
| Fundo dinâmico | `AnimatedContainer` com `LinearGradient` escolhido pelo `weather_code` |

## weather_code (WMO) → ilustração/fundo
| Código | Condição | Ícone | Fundo |
|---|---|---|---|
| 0 | Céu limpo | sun / night | Ensolarado / Noite |
| 1–2 | Parcialmente nublado | partly / night-cloud | Parcialmente nublado |
| 3, 45, 48 | Nublado / neblina | cloud | Nublado |
| 51–67, 80–82 | Garoa / chuva | rain | Chuva |
| 95–99 | Tempestade | storm | Tempestade |

## Breakpoints
```dart
enum WindowSize { compact, medium, expanded }
WindowSize windowSizeOf(BuildContext c) {
  final w = MediaQuery.sizeOf(c).width;
  if (w < 600) return WindowSize.compact;
  if (w < 840) return WindowSize.medium;
  return WindowSize.expanded;
}
```

## Permissões Android (`AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```
A tela “03 · Permissão” reproduz o diálogo do Android 12+ com a escolha entre localização **Precisa** e **Aproximada**. Se o usuário negar, o fluxo leva para **Locais** (busca manual).
