// Abre uma pasta no gerenciador de arquivos do sistema (Arquivo ›
// Informações, D-064). O `xdg-open` é o padrão do freedesktop: o Quill não
// sabe qual gerenciador está instalado, e nada sai do computador.
import 'dart:io';

/// Trocado nos testes.
Future<void> Function(String dir) openFolder = _xdgOpen;

Future<void> _xdgOpen(String dir) async {
  try {
    await Process.start('xdg-open', [dir], mode: ProcessStartMode.detached);
  } on ProcessException {
    // Sem xdg-open: não há o que fazer.
  }
}
