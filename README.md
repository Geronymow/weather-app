# Clima Agora — app do tempo (Flutter · Android, iOS e Web)

App do tempo que detecta onde o usuário está e mostra **temperatura, hora e data locais**, previsão por hora e para 7 dias, detalhes (umidade, vento, UV, pressão, visibilidade, chuva), nascer/pôr do sol, qualidade do ar, cidades salvas e **alertas oficiais** (INMET/Defesa Civil).

O app implementa o protótipo Figma deste repositório (`previews/`, `figma-plugin/`): mesmas cores (Variables `Clima/Tokens`), fundos dinâmicos, tipografia `Clima/*`, ilustrações do tempo e layout das 8 telas. É **mobile-first** e se adapta à web/tablet/desktop pelas *window size classes* do Material.

## Rodando

Requer Flutter **3.47+** (Dart 3.14), o mesmo SDK do `weather-app-flutter`.

```bash
flutter pub get
flutter run                 # Android/iOS conectado ou emulador
flutter run -d chrome       # Web
flutter build web --release # gera build/web (hospedar em qualquer servidor estático)
flutter build apk --release
```

Testes e análise:

```bash
flutter analyze
flutter test
```

> Na web, a localização exige **HTTPS** (ou `localhost`) e a permissão do navegador.

## Telas (protótipo → app)

| Figma | No app |
|---|---|
| 01 · Splash | `features/onboarding/splash_page.dart`: aparece enquanto carrega ajustes, GPS e previsão |
| 02 · Boas-vindas | `features/onboarding/welcome_page.dart`: só no primeiro uso |
| 03 · Permissão (Android) | Diálogo **real** do sistema (Android 12+: Precisa/Aproximada) ou do navegador. Se negar, vai para **Locais** |
| 04 · Início | `features/home/`: hora/data locais do lugar (com fuso), temperatura, máx/mín/sensação, banner de alerta, 24 horas, 7 dias com faixa de temperatura, grade de detalhes, arco do sol e IQA |
| 05 · Locais e busca | `features/places/`: busca por cidade, bairro ou **CEP**, “usar minha localização”, cartões com o fundo do clima de cada cidade e hora local com UTC, sugestões, arrastar para reordenar, deslizar para remover |
| 06 · Alertas | `features/alerts/`: alertas oficiais do INMET + avisos calculados da previsão (UV alto, frente fria, chuva nas próximas 2 h, tempestade, calor, vento), “Lembrar-me”, “Compartilhar” e preferências |
| 07 · Ajustes | `features/settings/`: °C/°F, km/h · m/s · mph, hPa · mmHg · inHg, tema Auto/Claro/Escuro, fundo conforme o clima, precisão do GPS, atualização automática e frequência |
| 08 · Sem conexão | `features/home/offline_view.dart`: mostra a última previsão salva (cache local) e “Tentar novamente” |

## Layout responsivo

| Classe | Largura | Layout |
|---|---|---|
| Compacto | < 600 dp | 1 coluna, grade 2×, `NavigationBar` inferior |
| Médio | 600–839 dp | `NavigationRail` com FAB de busca, grade 3×, sol e ar lado a lado |
| Expandido | ≥ 840 dp | Rail + 2 painéis no Início (locais à esquerda, detalhes à direita) |

Na web, as listas horizontais também rolam arrastando com o mouse, e páginas de lista têm largura máxima de leitura.

## Integrações (sem chave de API)

| Função | Serviço |
|---|---|
| GPS e permissão | `geolocator` (Fused Location Provider / Geolocation API) |
| Nome do bairro/cidade | Nominatim (OpenStreetMap), geocodificação reversa |
| Previsão atual/horária/7 dias, fuso e hora local | Open-Meteo Forecast (`timezone=auto`) |
| Qualidade do ar | Open-Meteo Air Quality (US AQI, PM2.5) |
| Busca de cidades | Open-Meteo Geocoding, com Nominatim para bairros e ViaCEP para CEP |
| Alertas oficiais | INMET (`apiprevmet3.inmet.gov.br/avisos/ativos`), filtrado pelo município |
| Locais salvos, ajustes e cache offline | `shared_preferences` |

## Estrutura

Segue a organização do `weather-app-flutter` (`models/`, `services/`, tema + `GlassCard`, `material_ui`, `http`, `geolocator`, `intl`, `google_fonts`), expandida por funcionalidade:

```
lib/
  main.dart, app.dart          # inicialização, tema, Splash → Boas-vindas → app
  core/                        # tokens/tema (claro e escuro), breakpoints, unidades, weather_code (WMO)
  models/                      # Weather, AirQuality, Place, WeatherAlert, AppSettings
  services/                    # Open-Meteo, geocodificação, alertas, GPS, armazenamento
  state/app_state.dart         # ChangeNotifier com todo o estado do app
  widgets/                     # GlassCard, chips, CityCard, ilustrações do tempo (CustomPainter)
  features/                    # onboarding, home, places, alerts, settings, shell (navegação)
test/                          # modelos, unidades, alertas, geocodificação e fluxos de tela (APIs falsas)
tool/generate_icons_test.dart  # gera os ícones (Android/iOS/web) a partir do logo do protótipo
```

As ilustrações (sol, parcialmente nublado, nuvem, chuva, tempestade, noite) são desenhadas com a **mesma geometria dos SVGs do Figma**, sem imagens rasterizadas. Os ícones do app saem do logo da Splash: `flutter test tool/generate_icons_test.dart`.

## Limitações conhecidas

- **Notificações em segundo plano** (Android `workmanager` + `flutter_local_notifications`) ainda não foram feitas. “Alertas severos” e “Chuva nas próximas 2 horas” avisam **dentro do app**, e “Lembrar-me” avisa quando o alerta começa, também **com o app aberto**. O “Resumo diário às 07:00” só fica salvo como preferência.
- A busca por voz (ícone de microfone do protótipo) não foi implementada.
- “Compartilhar” copia o texto do alerta para a área de transferência.
- Se a API do INMET estiver fora do ar ou bloqueada pelo navegador (CORS), o app segue só com os avisos calculados da previsão.

---

## Protótipo Figma

**Padrão de tela: Android Large 360×800 dp**, definido em `SCREEN` no `figma-plugin/code.js`. Visual Material 3, tema escuro com cards de “vidro” e fundo que muda conforme o tempo.

| Pasta | O que é |
|---|---|
| `figma-plugin/` | Plugin que monta o arquivo no Figma: telas com Auto Layout, Variables de cor, estilos de texto, componentes e o protótipo navegável |
| `figma-import-svg/` | As 8 telas em SVG (arraste para o Figma, funciona no Figma web/Linux) |
| `previews/` | PNGs de todas as telas |
| `tools/` | Simulador da API do Figma + script que gera os PNGs e SVGs a partir do `code.js` |
| `docs/flutter-handoff.md` | Mapeamento Figma → widgets Flutter |

### Importar no Figma

**Plugin (editável e navegável):** Figma Desktop → *Plugins ▸ Development ▸ Import plugin from manifest…* → `figma-plugin/manifest.json` → rode *Clima Agora — Gerador de Protótipo* → página **📱 Protótipo** → **▶ Present**.

**SVG:** arraste os arquivos de `figma-import-svg/` para o canvas (sem Auto Layout nem interações).

### Regerar prévias/SVGs depois de editar `code.js`
```bash
cd tools && node render.mjs   # precisa de Node + puppeteer + Google Chrome
```
