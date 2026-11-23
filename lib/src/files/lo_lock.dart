// A trava do LibreOffice (`.~lock.<arquivo>#`), ao lado do arquivo aberto.
//
// O conteúdo é `<nome>,<usuário>,<máquina>,<data>,<perfil>;`. Um arquivo
// travado por outro perfil abre só para leitura, em silêncio. Por isso o app
// olha a trava antes de abrir:
// - Trava do nosso perfil, nesta máquina: é velha. O perfil do LibreOffice
//   só aceita um processo por vez, e esse processo somos nós (o motor já
//   ligou). Sobrou de um Quill que morreu sem fechar o documento. Apaga.
// - Qualquer outra: alguém (um LibreOffice, outro computador) está com o
//   arquivo. Abre só para leitura e diz quem é.
import 'dart:io';

class LoLock {
  const LoLock({required this.name, required this.user, required this.host, required this.when, required this.profileUrl});

  final String name, user, host, when, profileUrl;

  /// Quem está com o arquivo, para mostrar: o nome, ou o usuário.
  String get owner => name.isNotEmpty ? name : user;

  static File fileFor(String documentPath) {
    final doc = File(documentPath);
    final dir = doc.parent.path;
    final base = doc.uri.pathSegments.last;
    return File('$dir/.~lock.$base#');
  }

  static LoLock? parse(String content) {
    final line = content.trim().replaceFirst(RegExp(r';$'), '');
    final parts = line.split(',');
    if (parts.length < 5) return null;
    return LoLock(
      name: parts[0],
      user: parts[1],
      host: parts[2],
      when: parts[3],
      // O URL do perfil pode ter vírgula: o resto da linha é dele.
      profileUrl: parts.sublist(4).join(','),
    );
  }

  static LoLock? read(String documentPath) {
    final f = fileFor(documentPath);
    try {
      return f.existsSync() ? parse(f.readAsStringSync()) : null;
    } on FileSystemException {
      return null;
    }
  }
}

/// O que fazer com a trava de um arquivo antes de abrir.
sealed class LockVerdict {
  const LockVerdict();
}

class Unlocked extends LockVerdict {
  const Unlocked();
}

/// A trava era nossa e velha, e foi apagada.
class StaleLockRemoved extends LockVerdict {
  const StaleLockRemoved();
}

/// Outro está com o arquivo: abrir só para leitura.
class LockedBy extends LockVerdict {
  const LockedBy(this.lock);
  final LoLock lock;
}

class LockInspector {
  LockInspector({required this.profileUrl, String? hostname}) : hostname = hostname ?? Platform.localHostname;

  final String profileUrl;
  final String hostname;

  bool _same(String a, String b) => _norm(a) == _norm(b);
  String _norm(String url) => Uri.decodeFull(url).replaceFirst(RegExp(r'/+$'), '');

  /// Só pode ser chamado com o motor ligado (é ele que segura o perfil).
  LockVerdict inspect(String documentPath) {
    final lock = LoLock.read(documentPath);
    if (lock == null) return const Unlocked();
    if (lock.host == hostname && _same(lock.profileUrl, profileUrl)) {
      try {
        LoLock.fileFor(documentPath).deleteSync();
        return const StaleLockRemoved();
      } on FileSystemException {
        return LockedBy(lock);
      }
    }
    return LockedBy(lock);
  }
}
