// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Psito Quill';

  @override
  String get commandBold => 'Bold';

  @override
  String get commandSave => 'Save';

  @override
  String get commandDarkPaper => 'Dark theme';

  @override
  String get documentArea => 'Document';

  @override
  String get statusStarting => 'Starting the engine…';

  @override
  String statusEngineFailed(String detail) {
    return 'The engine did not start: $detail';
  }

  @override
  String get statusOpening => 'Opening…';

  @override
  String get statusNoDocument => 'No document';

  @override
  String statusSaved(String path) {
    return 'Saved to $path';
  }

  @override
  String statusError(String detail) {
    return 'Error: $detail';
  }

  @override
  String statusPlugin(String text) {
    return 'Plugin: $text';
  }

  @override
  String get statusModified => 'modified';

  @override
  String statusMemory(int mb) {
    return '$mb MB';
  }
}
