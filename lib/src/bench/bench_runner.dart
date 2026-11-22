// O roteiro de medição da Fase 0, dentro do app de verdade.
//
// `psito-quill --bench capitulo.docx saida.json` liga o motor, abre um
// documento vazio, abre o de 30 páginas, rola até o fim, digita 200 teclas,
// aplica negrito, salva uma cópia, troca para o papel escuro e grava os
// números num JSON. Depois sai.
//
// As teclas entram pelo mesmo caminho da UI (DocumentController.postKey),
// sem passar pelo evento de teclado do GTK, que custa microssegundos.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../app.dart';
import '../document/document_controller.dart';
import '../kit/lok/vcl_keys.dart';
import '../kit/quill_kit.dart';
import '../ui/tokens/themes/themes.dart';

class BenchRunner {
  BenchRunner({
    required this.doc,
    required this.scroll,
    required this.app,
    required this.documentPath,
    required this.outputPath,
    required this.rssAtStart,
  });

  final DocumentController doc;
  final ScrollController scroll;
  final GlobalKey<QuillAppState> app;
  final String documentPath, outputPath;
  final int rssAtStart;

  final Map<String, Object?> _out = {};
  final List<FrameTiming> _frames = [];

  static double _mb(int bytes) => double.parse((bytes / 1048576).toStringAsFixed(1));

  Future<void> _until(bool Function() test, {Duration timeout = const Duration(seconds: 60)}) async {
    final end = DateTime.now().add(timeout);
    while (!test()) {
      if (DateTime.now().isAfter(end)) throw TimeoutException('bench: esperou demais');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<void> _idle([int ms = 1500]) => Future<void>.delayed(Duration(milliseconds: ms));

  /// RSS do processo inteiro (Flutter + motor), lido do /proc.
  int get _rss => ProcessInfo.currentRss;

  Future<void> run() async {
    try {
      await _run();
      _out['ok'] = true;
    } catch (e, st) {
      _out['ok'] = false;
      _out['erro'] = '$e\n$st';
    }
    File(outputPath).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(_out));
    exit(_out['ok'] == true ? 0 : 1);
  }

  Future<void> _run() async {
    _out['rss_inicio_mb'] = _mb(rssAtStart);
    await _until(() => doc.kitStatus != KitStatus.starting);
    if (doc.kitStatus == KitStatus.failed) throw StateError('motor não ligou');
    _out['versao'] = doc.engineVersion;
    await _idle(500);
    _out['rss_motor_ligado_mb'] = _mb(_rss);

    // Documento vazio.
    doc.open('');
    await _until(() => doc.docStatus == DocStatus.open);
    await _idle();
    _out['rss_vazio_mb'] = _mb(_rss);

    // As 30 páginas.
    final sw = Stopwatch()..start();
    doc.open(documentPath);
    await _until(() => doc.docStatus == DocStatus.open);
    _out['abrir_ms'] = sw.elapsedMilliseconds;
    await _until(() => doc.tiles.isNotEmpty);
    _out['primeiro_ladrilho_ms'] = sw.elapsedMilliseconds;
    await _idle();
    _out['rss_30p_mb'] = _mb(_rss);

    // Rolar até o fim e voltar, medindo os quadros.
    await _until(() => scroll.hasClients && scroll.position.maxScrollExtent > 0);
    SchedulerBinding.instance.addTimingsCallback(_frames.addAll);
    final max = scroll.position.maxScrollExtent;
    final rolarMs = (max / 3).round(); // ~3000 px/s, uma rolagem rápida de leitura
    await scroll.animateTo(max, duration: Duration(milliseconds: rolarMs), curve: Curves.linear);
    await scroll.animateTo(0, duration: Duration(milliseconds: rolarMs), curve: Curves.linear);
    await _idle(500);
    SchedulerBinding.instance.removeTimingsCallback(_frames.addAll);
    _out['rolar'] = _frameStats(_frames, px: max * 2, ms: rolarMs * 2);
    _out['rss_depois_de_rolar_mb'] = _mb(_rss);

    // Digitar: clique no primeiro parágrafo e 200 teclas a ~12 por segundo.
    doc.postMouse(MouseEventType.down, const Offset(1700, 3200));
    doc.postMouse(MouseEventType.up, const Offset(1700, 3200));
    await _idle(500);
    doc.kit.resetKeyLatency();
    _frames.clear();
    SchedulerBinding.instance.addTimingsCallback(_frames.addAll);
    const texto = 'Kaelen olhou o horizonte. ';
    for (var i = 0; i < 200; i++) {
      final c = texto.codeUnitAt(i % texto.length);
      doc.postKey(c, c == 0x20 ? VclKey.space : 0);
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    await _idle(500);
    SchedulerBinding.instance.removeTimingsCallback(_frames.addAll);
    final lat = doc.kit.keyLatency();
    _out['latencia_tecla_ladrilho'] = {
      'amostras': lat.samples,
      'p50_ms': lat.p50.inMicroseconds / 1000,
      'p95_ms': lat.p95.inMicroseconds / 1000,
      'max_ms': lat.max.inMicroseconds / 1000,
    };
    _out['digitar_quadros'] = _frameStats(_frames);
    _out['rss_depois_de_digitar_mb'] = _mb(_rss);

    // Negrito na palavra anterior.
    doc.postKey(0, VclKey.left | VclKey.shift | VclKey.mod1);
    await _idle(300);
    doc.uno('.uno:Bold');
    await _until(() => doc.isOn('.uno:Bold'), timeout: const Duration(seconds: 5));
    _out['negrito'] = true;

    // Salvar uma cópia (nunca por cima do arquivo de teste).
    final copia = '${File(outputPath).parent.path}/bench-salvo.docx';
    final saveWatch = Stopwatch()..start();
    doc.kit.saveAs(copia, 'docx');
    await _until(() => doc.message is SavedMessage);
    _out['salvar_ms'] = saveWatch.elapsedMilliseconds;
    _out['salvo_bytes'] = File(copia).lengthSync();

    // Papel escuro: troca o tema (e o esquema do LibreOffice). Confere pela
    // luminância dos ladrilhos e pela resposta do .uno:ChangeTheme.
    final results = <String>[];
    final sub = doc.kit.events.listen((e) {
      if (e is OtherKitEvent && e.payload.contains('ChangeTheme')) results.add(e.payload);
    });
    final lumaClaro = doc.kit.debugTilesLuma();
    app.currentState!.setTheme(escuro);
    await _idle(1500);
    final lumaEscuro = doc.kit.debugTilesLuma();
    app.currentState!.setTheme(claro);
    await _idle(1500);
    final lumaDeVolta = doc.kit.debugTilesLuma();
    app.currentState!.setTheme(escuro);
    await _idle(1500);
    await sub.cancel();
    _out['papel_escuro'] = {
      'luma_claro': double.parse(lumaClaro.toStringAsFixed(1)),
      'luma_escuro': double.parse(lumaEscuro.toStringAsFixed(1)),
      'luma_de_volta_ao_claro': double.parse(lumaDeVolta.toStringAsFixed(1)),
      'change_theme_ok': results.isNotEmpty && results.every((r) => r.contains("'success': true") || r.contains('"success": true')),
      'respostas': results,
    };
    _out['rss_escuro_mb'] = _mb(_rss);

    // Lua.
    doc.kit.runLua('psito.log("olá do bench")', 'bench.lua');
    await _until(() => doc.message is PluginMessage, timeout: const Duration(seconds: 5));
    _out['lua'] = (doc.message as PluginMessage).text;
    _out['rss_final_mb'] = _mb(_rss);
  }

  static Map<String, Object> _frameStats(List<FrameTiming> frames, {double? px, int? ms}) {
    if (frames.isEmpty) return {'quadros': 0};
    List<double> sorted(Iterable<Duration> d) => d.map((x) => x.inMicroseconds / 1000).toList()..sort();
    double pct(List<double> v, double p) => v[((p * v.length).ceil() - 1).clamp(0, v.length - 1)];
    final build = sorted(frames.map((f) => f.buildDuration));
    final raster = sorted(frames.map((f) => f.rasterDuration));
    final total = sorted(frames.map((f) => f.totalSpan));
    // Um quadro "perdido" é o que não coube em 16,7 ms (60 Hz).
    final lost = frames.where((f) => f.buildDuration + f.rasterDuration > const Duration(microseconds: 16667));
    return {
      'quadros': frames.length,
      if (ms != null) 'fps_medio': double.parse((frames.length / (ms / 1000)).toStringAsFixed(1)),
      'build_p95_ms': pct(build, .95),
      'raster_p50_ms': pct(raster, .5),
      'raster_p95_ms': pct(raster, .95),
      'total_p95_ms': pct(total, .95),
      'acima_de_16ms': lost.length,
      'px_rolados': ?px?.round(),
    };
  }
}
