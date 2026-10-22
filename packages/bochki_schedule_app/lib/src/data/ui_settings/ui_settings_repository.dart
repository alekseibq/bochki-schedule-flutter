import 'dart:convert';
import 'dart:io';

import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';

final class UiSettings {
  const UiSettings({
    this.uiScale = 1.1,
    this.shouldResetUiDimensionsOnStart = false,
    this.windowSizes = const {},
    this.procedureSessionsColumnWidths = const [],
    this.procedureKindsColumnWidths = const [],
  });

  final double uiScale;
  final bool shouldResetUiDimensionsOnStart;
  final Map<String, Map<String, double>> windowSizes;
  final List<double> procedureSessionsColumnWidths;
  final List<double> procedureKindsColumnWidths;

  UiSettings copyWith({
    double? uiScale,
    bool? shouldResetUiDimensionsOnStart,
    Map<String, Map<String, double>>? windowSizes,
    List<double>? procedureSessionsColumnWidths,
    List<double>? procedureKindsColumnWidths,
  }) =>
      UiSettings(
        uiScale: uiScale ?? this.uiScale,
        shouldResetUiDimensionsOnStart: shouldResetUiDimensionsOnStart ??
            this.shouldResetUiDimensionsOnStart,
        windowSizes: windowSizes ?? this.windowSizes,
        procedureSessionsColumnWidths:
            procedureSessionsColumnWidths ?? this.procedureSessionsColumnWidths,
        procedureKindsColumnWidths:
            procedureKindsColumnWidths ?? this.procedureKindsColumnWidths,
      );

  Map<String, Object?> toJson() => {
        'version': 1,
        'uiScale': uiScale,
        'shouldResetUiDimensionsOnStart': shouldResetUiDimensionsOnStart,
        'windowSizes': windowSizes,
        'procedureSessionsColumnWidths': procedureSessionsColumnWidths,
        'procedureKindsColumnWidths': procedureKindsColumnWidths,
      };

  factory UiSettings.fromJson(Object? value) {
    if (value is! Map)
      throw const FormatException('UI settings must be an object.');
    final scale = (value['uiScale'] as num?)?.toDouble() ?? 1.1;
    if (scale < 1 || scale > 1.5)
      throw const FormatException('Invalid UI scale.');
    final rawSizes = value['windowSizes'];
    final sizes = <String, Map<String, double>>{};
    if (rawSizes is Map) {
      for (final entry in rawSizes.entries) {
        if (entry.value is! Map) continue;
        final width = (entry.value['width'] as num?)?.toDouble();
        final height = (entry.value['height'] as num?)?.toDouble();
        if (width != null && height != null && width > 0 && height > 0) {
          sizes[entry.key.toString()] = {'width': width, 'height': height};
        }
      }
    }
    final widths = (value['procedureSessionsColumnWidths'] as List? ?? const [])
        .whereType<num>()
        .map((width) => width.toDouble())
        .toList(growable: false);
    final procedureKindsWidths =
        (value['procedureKindsColumnWidths'] as List? ?? const [])
            .whereType<num>()
            .map((width) => width.toDouble())
            .toList(growable: false);
    return UiSettings(
      uiScale: scale,
      shouldResetUiDimensionsOnStart:
          value['shouldResetUiDimensionsOnStart'] as bool? ?? false,
      windowSizes: sizes,
      procedureSessionsColumnWidths: widths,
      procedureKindsColumnWidths: procedureKindsWidths,
    );
  }
}

final class UiSettingsRepository {
  UiSettingsRepository({required File file, required SafeFileWriter writer})
      : _file = file,
        _writer = writer;

  final File _file;
  final SafeFileWriter _writer;
  UiSettings _settings = const UiSettings();
  bool _isLoaded = false;

  UiSettings get settings => _settings;
  bool get isLoaded => _isLoaded;

  Future<bool> load({required double legacyUiScale}) async {
    if (!await _file.exists()) {
      _settings = UiSettings(uiScale: legacyUiScale);
      _isLoaded = true;
      await save();
      return true;
    }
    try {
      _settings = UiSettings.fromJson(jsonDecode(await _file.readAsString()));
      _isLoaded = true;
      if (_settings.shouldResetUiDimensionsOnStart) {
        _settings = const UiSettings();
        await save();
        return true;
      }
      return false;
    } catch (_) {
      _settings = const UiSettings();
      _isLoaded = true;
      await save();
      return true;
    }
  }

  Future<void> update(UiSettings settings) {
    _settings = settings;
    return save();
  }

  Future<void> save() => _writer.writeString(
        _file,
        const JsonEncoder.withIndent('  ').convert(_settings.toJson()),
      );
}
