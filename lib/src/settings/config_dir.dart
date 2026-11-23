import 'dart:io';

/// ~/.config/psito-quill (ou $XDG_CONFIG_HOME/psito-quill).
Directory quillConfigDir() {
  final env = Platform.environment;
  final base = env['XDG_CONFIG_HOME'] ?? '${env['HOME']}/.config';
  return Directory('$base/psito-quill');
}
