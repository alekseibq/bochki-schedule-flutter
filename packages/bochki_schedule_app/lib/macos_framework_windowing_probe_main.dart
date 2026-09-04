import 'package:flutter/widgets.dart';

import 'src/presentation/macos_framework_windowing_probe.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await runMacosFrameworkWindowingProbe();
}
