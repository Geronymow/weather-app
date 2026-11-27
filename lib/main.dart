import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'services/storage_service.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'pt_BR';
  await initializeDateFormatting('pt_BR');

  final state = AppState(storage: await StorageService.open());
  runApp(ClimaAgoraApp(state: state));
  // Carrega ajustes, GPS e previsão enquanto a Splash está na tela.
  await state.bootstrap();
}
