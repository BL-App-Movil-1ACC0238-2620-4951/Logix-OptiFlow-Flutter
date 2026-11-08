import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/di/dependencies.dart';
import 'presentation/state/optiflow_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  runApp(
    ChangeNotifierProvider(
      create: (_) => OptiFlowController(dependencies: AppDependencies()),
      child: const OptiFlowApp(),
    ),
  );
}
