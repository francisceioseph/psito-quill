import 'dart:io';

import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/bench/bench_runner.dart';
import 'src/document/document_controller.dart';
import 'src/kit/lok/lo_profile.dart';
import 'src/kit/lok/lok_quill_kit.dart';
import 'src/kit/quill_kit.dart';
import 'src/plugins/plugin_host.dart';
import 'src/ui/tokens/themes/themes.dart';

/// `psito-quill [arquivo]`
/// `psito-quill --bench capitulo.docx saida.json` (medidas da Fase 0)
void main(List<String> args) {
  final rssAtStart = ProcessInfo.currentRss;
  WidgetsFlutterBinding.ensureInitialized();

  final bench = args.isNotEmpty && args.first == '--bench';
  final profile = LoProfile.standard()..ensureSchemes(paperSchemes(builtInThemes));
  final kit = LokQuillKit(profile: profile);
  final doc = DocumentController(kit);
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
    final path = args.isEmpty ? '' : File(args.first).absolute.path;
    late final void Function(KitEvent) onReady;
    final sub = kit.events.listen((e) => onReady(e));
    onReady = (e) {
      if (e is! KitReady) return;
      sub.cancel();
      doc.open(path);
      PluginHost(kit).runBundled('ola');
    };
  }

  doc.start();
  runApp(QuillApp(key: app, doc: doc, scrollController: scroll));
}
