// A janela do app: só o título, por enquanto. O Flutter no Linux não tem
// API para o título; o plugin nativo tem (pqk_set_window_title).
import 'package:psito_quill_kit/psito_quill_kit.dart';

abstract interface class AppWindow {
  void setTitle(String title);
}

class NativeAppWindow implements AppWindow {
  NativeAppWindow([NativeQuillKit? native]) : _native = native ?? NativeQuillKit.open();
  final NativeQuillKit _native;
  String? _last;

  @override
  void setTitle(String title) {
    if (title == _last) return;
    _last = title;
    _native.setWindowTitle(title);
  }
}
