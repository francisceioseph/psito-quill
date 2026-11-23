// A área de transferência do sistema, como porta: o app usa a do Flutter, e
// os testes uma na memória.
import 'package:flutter/services.dart';

abstract interface class TextClipboard {
  Future<String?> read();
  Future<void> write(String text);
}

class SystemTextClipboard implements TextClipboard {
  const SystemTextClipboard();

  @override
  Future<String?> read() async => (await Clipboard.getData(Clipboard.kTextPlain))?.text;

  @override
  Future<void> write(String text) => Clipboard.setData(ClipboardData(text: text));
}

class MemoryTextClipboard implements TextClipboard {
  String? text;

  @override
  Future<String?> read() async => text;

  @override
  Future<void> write(String text) async => this.text = text;
}
