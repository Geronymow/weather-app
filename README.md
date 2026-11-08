# Clima Agora — protótipo Figma (app do tempo Android → Flutter)

**Padrão de tela: Android Large 360×800 dp** (preset do Figma), definido em `SCREEN` no `figma-plugin/code.js`.

App do tempo que detecta onde o usuário está e mostra **temperatura, hora e data locais**, previsão por hora e para 7 dias, detalhes (umidade, vento, UV, pressão, visibilidade, chuva), nascer/pôr do sol, qualidade do ar, cidades salvas e **alertas oficiais** (INMET/Defesa Civil).

Visual: Material 3, tema escuro com cards de “vidro” (glassmorphism) e fundo que muda conforme o tempo.

## Conteúdo da pasta

| Pasta | O que é |
|---|---|
| `figma-plugin/` | **Arquivo principal para importar.** Plugin que monta o arquivo inteiro no Figma: telas com Auto Layout, Variables de cor, estilos de texto, componentes e o protótipo navegável |
| `figma-import-svg/` | As 8 telas em SVG, todas **Android Large 360×800**. É só arrastar para o Figma, e funciona também no **Figma web/Linux** |
| `previews/` | PNGs de todas as telas (para relatório/apresentação) |
| `tools/` | Simulador da API do Figma + script que gera os PNGs e os SVGs a partir do mesmo `code.js` |

## Como importar no Figma

### Opção A — Plugin (recomendado: editável, responsivo e navegável)
> Para importar plugin de desenvolvimento é preciso o **Figma Desktop** (Windows/macOS). No Linux, use o cliente não oficial `figma-linux` ou a opção B.

1. Abra o Figma Desktop e crie um arquivo de Design em branco.
2. Menu **Plugins ▸ Development ▸ Import plugin from manifest…**
3. Selecione `figma-plugin/manifest.json`.
4. Rode em **Plugins ▸ Development ▸ Clima Agora — Gerador de Protótipo** (leva poucos segundos).
5. Vá para a página **📱 Protótipo** e aperte **▶ Present** (fluxo “Abrir o app”).

Páginas criadas (3):
- **📱 Protótipo**: 8 telas 360×800 dp já ligadas (Splash → Boas-vindas → Permissão Android → Início → Locais/Ajustes/Alertas, e o estado Sem conexão).
- **🎨 Design System**: cores (Variables `Clima/Tokens`), fundos dinâmicos, tipografia (`Clima/*`), ícones e componentes.
- **🔌 APIs & Flutter**: tabela de integrações, fluxo de dados e o mapeamento de Figma para widgets Flutter.

### Opção B — SVG (qualquer Figma, inclusive no navegador)
Arraste os arquivos de `figma-import-svg/` para o canvas (as pranchas de Design System e APIs ficam em `figma-import-svg/extras/`). Cada tela vira um grupo com textos editáveis e vetores. Os SVGs **não trazem** Auto Layout nem as interações: para isso, use a opção A.

## Responsividade

Todas as telas saem em 360×800, mas são construídas com **Auto Layout + Fill container**: se você mudar a largura de uma tela no Figma, o conteúdo se reorganiza sozinho. O código também sabe montar o layout médio (≥ 600 dp): troque `SCREEN` para gerar outro tamanho. Os breakpoints seguem as *window size classes* do Material:

| Classe | Largura | Layout |
|---|---|---|
| Compacto | < 600 dp | 1 coluna, grade de métricas 2×, NavigationBar inferior |
| Médio | 600–839 dp | NavigationRail lateral, grade 3×, cards de sol e ar lado a lado |
| Expandido | ≥ 840 dp | Rail + 2 painéis (lista de locais / detalhes) — próxima iteração |

Outras escolhas: áreas de toque ≥ 48 dp, a hora do sistema e a barra de gestos do Android aparecem em todas as telas, e o carrossel horizontal das horas rola no Present.

## Integrações externas previstas

| Função | Serviço | Chave |
|---|---|---|
| Localização GPS | `geolocator` (Fused Location Provider) | — |
| Nome do bairro/cidade | Nominatim (OpenStreetMap) reverse geocoding | não (1 req/s) |
| Previsão atual/hora/7 dias, fuso e hora local | Open-Meteo Forecast (`timezone=auto`) | não |
| Qualidade do ar | Open-Meteo Air Quality | não |
| Busca de cidades | Open-Meteo Geocoding | não |
| Alertas oficiais | INMET Alert-AS (CAP/RSS) | não |
| Notificações em 2º plano | `workmanager` + `flutter_local_notifications` | — |

Exemplo da chamada principal:
```
https://api.open-meteo.com/v1/forecast?latitude=-23.59&longitude=-46.63
  &current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,wind_direction_10m,pressure_msl,visibility,is_day
  &hourly=temperature_2m,precipitation_probability,weather_code
  &daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_probability_max
  &timezone=auto
```

## Rumo ao Flutter

Mais detalhes em `docs/flutter-handoff.md`. Em resumo: Auto Layout vira `Column`/`Row`, Fill vira `Expanded`, Variables viram `ThemeData`/`ColorScheme`, os estilos `Clima/*` viram `TextTheme` e os breakpoints viram `LayoutBuilder`.

## Regerar prévias/SVGs depois de editar `code.js`
```bash
cd tools && node render.mjs   # precisa de Node + puppeteer + Google Chrome
```
O simulador também confere as regras da API do Figma (FILL só dentro de Auto Layout, fonte carregada antes do texto etc.) antes de gerar os arquivos.
