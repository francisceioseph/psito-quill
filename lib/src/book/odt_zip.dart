// Ler uma entrada de um ODT (um zip) sem pacote novo (Fase 3, D-071).
//
// O fichário e a busca no livro leem o `content.xml` dos capítulos fechados,
// sem abri-los no motor. Só a leitura: o diretório central no fim do arquivo,
// o cabeçalho local da entrada e o conteúdo, guardado (0) ou comprimido
// (8, o deflate cru do `dart:io`). Sem zip64: um capítulo não chega a 4 GB.
// O Dart nunca escreve ODT; quem escreve é o motor.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// O conteúdo de [name] dentro do zip [zip], ou null se não existe, se o zip
/// está quebrado ou se o método de compressão não é 0 nem 8.
Uint8List? readZipEntry(Uint8List zip, String name) {
  final d = ByteData.sublistView(zip);
  int u16(int at) => d.getUint16(at, Endian.little);
  int u32(int at) => d.getUint32(at, Endian.little);
  // O fim do diretório central: a assinatura, procurada de trás para a
  // frente (o comentário do zip pode ter até 64 KB).
  var end = -1;
  final stop = zip.length - 22 - 0xFFFF < 0 ? 0 : zip.length - 22 - 0xFFFF;
  for (var i = zip.length - 22; i >= stop; i--) {
    if (u32(i) == 0x06054b50) {
      end = i;
      break;
    }
  }
  if (end < 0) return null;
  final count = u16(end + 10);
  var at = u32(end + 16);
  final wanted = utf8.encode(name);
  try {
    for (var n = 0; n < count; n++) {
      if (u32(at) != 0x02014b50) return null;
      final method = u16(at + 10);
      final size = u32(at + 20);
      final nameLen = u16(at + 28), extraLen = u16(at + 30), commentLen = u16(at + 32);
      final local = u32(at + 42);
      if (_sameBytes(zip, at + 46, wanted, nameLen)) {
        if (u32(local) != 0x04034b50) return null;
        final data = local + 30 + u16(local + 26) + u16(local + 28);
        final raw = Uint8List.sublistView(zip, data, data + size);
        return switch (method) {
          0 => Uint8List.fromList(raw),
          8 => Uint8List.fromList(ZLibDecoder(raw: true).convert(raw)),
          _ => null,
        };
      }
      at += 46 + nameLen + extraLen + commentLen;
    }
  } on RangeError {
    return null;
  } on FormatException {
    return null;
  }
  return null;
}

bool _sameBytes(Uint8List zip, int at, List<int> name, int len) {
  if (len != name.length || at + len > zip.length) return false;
  for (var i = 0; i < len; i++) {
    if (zip[at + i] != name[i]) return false;
  }
  return true;
}

/// O `content.xml` de um ODT em [path], como texto; null se não dá para ler.
String? readOdtContent(String path) {
  try {
    final bytes = readZipEntry(File(path).readAsBytesSync(), 'content.xml');
    return bytes == null ? null : utf8.decode(bytes, allowMalformed: true);
  } on FileSystemException {
    return null;
  }
}
