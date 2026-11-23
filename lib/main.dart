import 'dart:io';
import 'dart:ui' show PlatformDispatcher, Size;

import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/bench/bench_runner.dart';
import 'src/document/document_controller.dart';
import 'src/document/workspace.dart';
import 'src/files/app_window.dart';
import 'src/files/file_dialogs.dart';
import 'src/files/lo_lock.dart';
import 'src/files/recent_files.dart';
import 'src/kit/lok/lo_profile.dart';
import 'src/kit/lok/lok_quill_kit.dart';
import 'src/kit/quill_kit.dart';
import 'src/plugins/plugin_host.dart';
import 'src/settings/config_dir.dart';
import 'src/settings/settings.dart';
import 'src/ui/tokens/themes/themes.dart';

/// `psito-quill [arquivo]`
/// `psito-quill --bench capitulo.docx saida.json` (as medições)
void main(List<String> args) {
  final rssAtStart = ProcessInfo.currentRss;
  WidgetsFlutterBinding.ensureInitialized();

  final bench = args.isNotEmpty && args.first == '--bench';
  final config = quillConfigDir();
  final settings = Settings(bench ? null : File('${config.path}/preferencias.json'));
  final profile = LoProfile.standard()
    ..ensureSettings(
      paperSchemes(builtInThemes, spell: spellMarkColors[settings.spellColor]),
      current: themeById(settings.theme).paperScheme,
    );
  // Cópias temporárias de uma sessão que caiu (D-044): têm o texto do livro.
  DocumentController.cleanStaleCopies();
  final kit = LokQuillKit(profile: profile, tileSlots: tileSlotsFor(_largestDisplay()));
  final doc = DocumentController(kit);
  final recents = RecentFiles(File('${config.path}/recentes.json'), keep: settings.keepRecents);
  settings.addListener(() => recents.keep = settings.keepRecents);
  final workspace = Workspace(
    doc: doc,
    recents: recents,
    dialogs: const SystemFileDialogs(),
    locks: LockInspector(profileUrl: profile.url),
  );
  final scroll = ScrollController();
  final app = GlobalKey<QuillAppState>();

  if (bench) {
    BenchRunner(
      doc: doc,
      scroll: scroll,
      app: app,
      documentPath: args[1],
      outputPath: args[2],
      rssAtStart: rssAtStart,
    ).run();
  } else {
    final path = args.isEmpty ? null : File(args.first).absolute.path;
    late final void Function(KitEvent) onReady;
    final sub = kit.events.listen((e) => onReady(e));
    onReady = (e) {
      if (e is! KitReady) return;
      sub.cancel();
      // A trava só pode ser julgada com o motor ligado (ele segura o perfil).
      if (path == null) {
        // A tela inicial (D-064) é o editor sem documento.
        if (!settings.startScreen) doc.open('');
      } else {
        workspace.openPath(path);
      }
      PluginHost(kit).runBundled('ola');
    };
  }

  doc.start();
  runApp(QuillApp(
    key: app,
    workspace: workspace,
    settings: settings,
    window: NativeAppWindow(),
    scrollController: scroll,
  ));
}

/// O maior monitor, em pixels físicos (para dimensionar os ladrilhos).
Size _largestDisplay() {
  var best = Size.zero;
  for (final d in PlatformDispatcher.instance.displays) {
    if (d.size.width * d.size.height > best.width * best.height) best = d.size;
  }
  if (best.isEmpty) {
    for (final v in PlatformDispatcher.instance.views) {
      final s = v.physicalSize;
      if (s.width * s.height > best.width * best.height) best = s;
    }
  }
  return best;
}
