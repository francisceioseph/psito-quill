// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Psito Quill';

  @override
  String get commandBold => 'Negrito';

  @override
  String get commandSave => 'Salvar';

  @override
  String get commandDarkPaper => 'Tema escuro';

  @override
  String get documentArea => 'Documento';

  @override
  String get statusStarting => 'Ligando o motor…';

  @override
  String statusEngineFailed(String detail) {
    return 'O motor não ligou: $detail';
  }

  @override
  String get statusOpening => 'Abrindo…';

  @override
  String get statusNoDocument => 'Nenhum documento';

  @override
  String statusSaved(String path) {
    return 'Salvo em $path';
  }

  @override
  String statusError(String detail) {
    return 'Erro: $detail';
  }

  @override
  String statusPlugin(String text) {
    return 'Plugin: $text';
  }

  @override
  String get statusModified => 'modificado';

  @override
  String statusMemory(int mb) {
    return '$mb MB';
  }
}
