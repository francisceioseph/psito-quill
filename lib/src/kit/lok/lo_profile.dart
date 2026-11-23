// O perfil do LibreOffice que o Quill usa: uma pasta só dele.
//
// Assim o Quill não briga com um LibreOffice aberto pelo usuário (o perfil
// tem trava) nem muda as configurações dele. E dá para registrar os esquemas
// de cor do papel: a 24.2 aceita o `.uno:ChangeTheme`, mas não traz esquema
// escuro nenhum (ver docs/FASE0-RESULTADOS.md).
import 'dart:io';

import '../../settings/config_dir.dart';

/// Um esquema de cor do documento, em 0xRRGGBB.
class PaperScheme {
  const PaperScheme({required this.name, required this.paper, required this.ink, required this.backdrop});

  /// O nome no LibreOffice (o valor do `.uno:ChangeTheme`).
  final String name;
  final int paper, ink, backdrop;
}

class LoProfile {
  LoProfile(this.directory);

  /// `$XDG_CONFIG_HOME/psito-quill/lo-profile`, ou `~/.config/...`.
  factory LoProfile.standard() => LoProfile(Directory('${quillConfigDir().path}/lo-profile'));

  final Directory directory;

  String get url => Uri.directory(directory.path).toString().replaceAll(RegExp(r'/$'), '');

  File get _registry => File('${directory.path}/user/registrymodifications.xcu');

  static const _marker = 'psito-quill: esquemas';

  /// Garante que os esquemas estão no perfil. Chamar antes de ligar o motor:
  /// o LibreOffice lê o arquivo ao iniciar e o regrava ao sair, mantendo o
  /// que não conhece.
  void ensureSchemes(List<PaperScheme> schemes) {
    final file = _registry;
    file.parent.createSync(recursive: true);
    var text = file.existsSync() ? file.readAsStringSync() : _emptyRegistry;
    text = _removeOurItems(text);
    final items = StringBuffer('<!-- $_marker -->\n');
    for (final s in schemes) {
      items.writeln(schemeItem(s));
    }
    items.write('<!-- /$_marker -->\n');
    text = text.replaceFirst('</oor:items>', '$items</oor:items>');
    file.writeAsStringSync(text);
  }

  static String _removeOurItems(String text) {
    final start = text.indexOf('<!-- $_marker -->');
    final end = text.indexOf('<!-- /$_marker -->');
    if (start < 0 || end < 0) {
      // O LibreOffice regrava o arquivo sem os comentários: tira os nós pelo nome.
      return text.replaceAll(RegExp(r'<item oor:path="/org.openoffice.Office.UI/ColorScheme/ColorSchemes"><node oor:name="PsitoQuill[^"]*".*?</item>\n?'), '');
    }
    return text.substring(0, start) + text.substring(end + '<!-- /$_marker -->\n'.length);
  }

  static String schemeItem(PaperScheme s) {
    String entry(String name, int color) =>
        '<node oor:name="$name" oor:op="fuse"><prop oor:name="Color" oor:op="fuse"><value>$color</value></prop></node>';
    return '<item oor:path="/org.openoffice.Office.UI/ColorScheme/ColorSchemes">'
        '<node oor:name="${s.name}" oor:op="replace">'
        '${entry('DocColor', s.paper)}${entry('FontColor', s.ink)}${entry('AppBackground', s.backdrop)}'
        '</node></item>';
  }

  static const _emptyRegistry = '<?xml version="1.0" encoding="UTF-8"?>\n'
      '<oor:items xmlns:oor="http://openoffice.org/2001/registry" '
      'xmlns:xs="http://www.w3.org/2001/XMLSchema" '
      'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n'
      '</oor:items>\n';
}
