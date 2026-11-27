import 'package:flutter/widgets.dart';

/// Material window size classes, os mesmos limites usados no protótipo.
enum WindowSize { compact, medium, expanded }

WindowSize windowSizeForWidth(double w) {
  if (w < 600) return WindowSize.compact;
  if (w < 840) return WindowSize.medium;
  return WindowSize.expanded;
}

WindowSize windowSizeOf(BuildContext context) =>
    windowSizeForWidth(MediaQuery.sizeOf(context).width);

/// Largura máxima de leitura para páginas de lista (Locais, Ajustes, Alertas)
/// em telas largas — evita linhas esticadas de ponta a ponta no navegador.
const double kReadableMaxWidth = 720;
