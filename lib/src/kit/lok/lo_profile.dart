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
  const PaperScheme({required this.name, required this.paper, required this.ink, required this.backdrop, this.spell});

  /// O nome no LibreOffice (o valor do `.uno:ChangeTheme`).
  final String name;
  final int paper, ink, backdrop;

  /// O ondulado da ortografia (a entrada `Spell`, D-067); null: o vermelho do
  /// LibreOffice. O motor lê ao ligar: trocar de esquema depois não muda.
  final int? spell;
}

class LoProfile {
  LoProfile(this.directory);

  /// `$XDG_CONFIG_HOME/psito-quill/lo-profile`, ou `~/.config/...`.
  factory LoProfile.standard() => LoProfile(Directory('${quillConfigDir().path}/lo-profile'));

  final Directory directory;

  String get url => Uri.directory(directory.path).toString().replaceAll(RegExp(r'/$'), '');

  File get _registry => File('${directory.path}/user/registrymodifications.xcu');

  static const _marker = 'psito-quill: esquemas';

  /// O que o perfil trava para nada sair do computador nem ficar registrado
  /// (D-041). Caminho do registro, nome e valor; os nomes foram conferidos no
  /// `main.xcd` da 24.2. Os logs da UNO já vêm desligados (`LogLevel` no
  /// máximo), e a 24.2 do Ubuntu não tem verificação de atualizações.
  static const privacy = <(String, String, String)>[
    // Sem relatório de falha (o envio ao servidor da TDF).
    ('/org.openoffice.Office.Common/Misc', 'CrashReport', 'false'),
    // Um documento não busca imagens e links de fora sozinho.
    ('/org.openoffice.Office.Common/Security/Scripting', 'BlockUntrustedRefererLinks', 'true'),
    // Macro de documento não roda (poderia abrir a rede ou gravar arquivos).
    ('/org.openoffice.Office.Common/Security/Scripting', 'DisableMacrosExecution', 'true'),
    // O motor não guarda a lista de recentes dele, nem as miniaturas.
    ('/org.openoffice.Office.Common/History', 'PickListSize', '0'),
    ('/org.openoffice.Office.Common/History', 'RecentDocsThumbnail', 'false'),
    ('/org.openoffice.Office.Common/Save/Document', 'GenerateThumbnail', 'false'),
    // Sem o "completar palavras": ele junta as palavras do documento numa
    // lista e, com o texto indo como tecla (D-076), inseriria sugestões.
    ('/org.openoffice.Office.Writer/AutoFunction/Completion', 'Enable', 'false'),
  ];

  /// Garante os esquemas e as travas de privacidade no perfil. Chamar antes
  /// de ligar o motor: o LibreOffice lê o arquivo ao iniciar e o regrava ao
  /// sair, mantendo o que não conhece.
  ///
  /// [current] vira o esquema atual do perfil: a cor da ortografia é a dele
  /// quando o motor liga (sem isso, valeria a do LibreOffice na primeira vez).
  void ensureSettings(List<PaperScheme> schemes, {String? current}) {
    final file = _registry;
    file.parent.createSync(recursive: true);
    var text = file.existsSync() ? file.readAsStringSync() : _emptyRegistry;
    text = _removeOurItems(text);
    final items = StringBuffer('<!-- $_marker -->\n');
    for (final s in schemes) {
      items.writeln(schemeItem(s));
    }
    for (final (path, name, value) in privacy) {
      items.writeln(propItem(path, name, value));
    }
    if (current != null) items.writeln(propItem(_schemePath, 'CurrentColorScheme', current));
    items.write('<!-- /$_marker -->\n');
    text = text.replaceFirst('</oor:items>', '$items</oor:items>');
    file.writeAsStringSync(text);
  }

  static const _schemePath = '/org.openoffice.Office.UI/ColorScheme';

  static String _removeOurItems(String text) {
    // O esquema atual: o LibreOffice regrava (com o último `ChangeTheme`).
    text = text.replaceAll(RegExp('<item oor:path="$_schemePath"><prop oor:name="CurrentColorScheme"[^\n]*?</item>\n?'), '');
    // O LibreOffice regrava as travas no mesmo formato, sem os comentários.
    for (final (path, name, value) in privacy) {
      text = text.replaceAll('${propItem(path, name, value)}\n', '');
    }
    final start = text.indexOf('<!-- $_marker -->');
    final end = text.indexOf('<!-- /$_marker -->');
    if (start < 0 || end < 0) {
      // O LibreOffice regrava o arquivo sem os comentários: tira os nós pelo nome.
      return text.replaceAll(RegExp(r'<item oor:path="/org.openoffice.Office.UI/ColorScheme/ColorSchemes"><node oor:name="PsitoQuill[^"]*".*?</item>\n?'), '');
    }
    return text.substring(0, start) + text.substring(end + '<!-- /$_marker -->\n'.length);
  }

  static String propItem(String path, String name, String value) =>
      '<item oor:path="$path"><prop oor:name="$name" oor:op="fuse"><value>$value</value></prop></item>';

  static String schemeItem(PaperScheme s) {
    String entry(String name, int color) =>
        '<node oor:name="$name" oor:op="fuse"><prop oor:name="Color" oor:op="fuse"><value>$color</value></prop></node>';
    return '<item oor:path="/org.openoffice.Office.UI/ColorScheme/ColorSchemes">'
        '<node oor:name="${s.name}" oor:op="replace">'
        '${entry('DocColor', s.paper)}${entry('FontColor', s.ink)}${entry('AppBackground', s.backdrop)}'
        '${s.spell == null ? '' : entry('Spell', s.spell!)}'
        '</node></item>';
  }

  static const _emptyRegistry = '<?xml version="1.0" encoding="UTF-8"?>\n'
      '<oor:items xmlns:oor="http://openoffice.org/2001/registry" '
      'xmlns:xs="http://www.w3.org/2001/XMLSchema" '
      'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n'
      '</oor:items>\n';
}
