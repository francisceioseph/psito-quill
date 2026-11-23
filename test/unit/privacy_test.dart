// A privacidade (D-041): o perfil do motor trava o que fala para fora, os
// recentes podem ficar só na memória, e o código do app não abre a rede.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/files/recent_files.dart';
import 'package:psito_quill/src/kit/lok/lo_profile.dart';
import 'package:psito_quill/src/settings/settings.dart';
import 'package:psito_quill/src/ui/tokens/themes/themes.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('quill-privacidade-'));
  tearDown(() => dir.deleteSync(recursive: true));

  group('o perfil do motor', () {
    File registry() => File('${dir.path}/user/registrymodifications.xcu');

    test('trava relatório de falha, links de fora, macros e o histórico', () {
      LoProfile(dir).ensureSettings(paperSchemes(builtInThemes));
      final text = registry().readAsStringSync();
      for (final (path, name, value) in LoProfile.privacy) {
        expect(text, contains('<item oor:path="$path"><prop oor:name="$name" oor:op="fuse"><value>$value</value></prop></item>'), reason: name);
      }
      expect(text, contains('"CrashReport"'));
      expect(text, contains('"DisableMacrosExecution"'));
    });

    test('regravado pelo LibreOffice (sem os comentários), não duplica', () {
      final p = LoProfile(dir)..ensureSettings(paperSchemes(builtInThemes));
      final file = registry();
      file.writeAsStringSync(file.readAsStringSync().replaceAll(RegExp(r'<!--[^>]*-->\n'), ''));
      p.ensureSettings(paperSchemes(builtInThemes));
      expect('"CrashReport"'.allMatches(file.readAsStringSync()).length, 1);
    });
  });

  group('os recentes', () {
    test('desligado: não grava e apaga o que havia', () {
      final store = File('${dir.path}/recentes.json');
      RecentFiles(store).add('/a.odt');
      expect(store.existsSync(), isTrue);
      final r = RecentFiles(store, keep: false)..add('/b.odt');
      expect(store.existsSync(), isFalse);
      expect(r.paths, ['/b.odt']);
    });

    test('religar grava a lista da sessão', () {
      final store = File('${dir.path}/recentes.json');
      final r = RecentFiles(store, keep: false)..add('/c.odt');
      r.keep = true;
      expect(RecentFiles(store).paths, ['/c.odt']);
      r.keep = false;
      expect(store.existsSync(), isFalse);
    });

    test('a preferência é guardada', () {
      final f = File('${dir.path}/preferencias.json');
      expect(Settings(f).keepRecents, isTrue);
      Settings(f).keepRecents = false;
      expect(Settings(f).keepRecents, isFalse);
    });
  });

  test('o código do app não abre a rede', () {
    const banned = ['HttpClient', 'Socket.connect', 'RawSocket', 'SecureSocket', 'WebSocket', 'package:http/', 'dart:html', 'HttpServer'];
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final text = f.readAsStringSync();
      for (final b in banned) {
        if (text.contains(b)) hits.add('${f.path}: $b');
      }
    }
    expect(hits, isEmpty);
  });

  test('o núcleo nativo não abre a rede nem grava arquivo', () {
    // As ferramentas de medição (linux/tools) gravam PPMs: não entram no app.
    final core = Directory('packages/psito_quill_kit/linux');
    final writes = RegExp(r'fopen\([^)]*"[wa]|ofstream|<sys/socket\.h>|curl|SAL_LOG_FILE');
    final hits = <String>[];
    for (final f in core.listSync(recursive: true).whereType<File>().where(
        (f) => !f.path.contains('/tools/') && (f.path.endsWith('.cc') || f.path.endsWith('.h')))) {
      final m = writes.firstMatch(f.readAsStringSync());
      if (m != null) hits.add('${f.path}: ${m[0]}');
    }
    expect(hits, isEmpty);
  });
}
