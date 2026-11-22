// O lado Dart dos plugins Lua. Na Fase 0 só carrega o código e manda rodar
// na caixa de areia nativa; menus e painéis declarativos vêm na Fase 5.
import 'package:flutter/services.dart';

import '../kit/quill_kit.dart';

class PluginLimits {
  const PluginLimits({this.memoryBytes = 16 << 20, this.instructions = 10000000});

  /// Teto de memória por plugin (o plano sugere 16 MB).
  final int memoryBytes;

  /// Instruções por chamada antes de interromper.
  final int instructions;
}

class PluginHost {
  PluginHost(this.kit, {AssetBundle? bundle, this.limits = const PluginLimits()})
      : _bundle = bundle ?? rootBundle;

  final QuillKit kit;
  final AssetBundle _bundle;
  final PluginLimits limits;

  /// Roda o plugin.lua de `plugins/<id>/`, que vem nos assets.
  Future<void> runBundled(String id) async {
    final source = await _bundle.loadString('plugins/$id/plugin.lua');
    kit.runLua(source, '$id/plugin.lua', memoryLimit: limits.memoryBytes, instructionLimit: limits.instructions);
  }
}
