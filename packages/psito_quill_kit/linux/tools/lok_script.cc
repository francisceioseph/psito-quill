// lok_script: conversa com o motor por um roteiro, e mostra o que ele responde.
//
// Serve para descobrir como a versão instalada do LibreOffice responde a um
// comando antes de escrever o código do app (os estados, os JSON, os
// callbacks). Cada linha do roteiro (na entrada padrão) é um passo:
//
//   open <arquivo>            abre ("" ou "-" para um documento novo)
//   close                     fecha o documento ativo (destroy)
//   open0 <arquivo>           abre sem mandar a área visível (como o app,
//                             que manda no quadro seguinte)
//   view <escala> <x> <y> <w> <h>  a área visível, em twips
//   uno <.uno:Cmd> [json]     despacha um comando
//   values <.uno:Cmd>         getCommandValues
//   type <texto>              digita (como o IME confirmado)
//   key <charCode> <keyCode>  uma tecla (entrada e soltura)
//   click <x> <y> [n] [botão] [mod]  clique em twips (botão 1 esquerdo, 4 direito; mod 8192 = Ctrl)
//   gsel <tipo> <x> <y>       setGraphicSelection (0 início, 1 fim), em twips
//   sel                       a seleção como texto
//   save <arquivo> <formato>  salvar como
//   wait <ms>                 espera os callbacks
//   preload <arquivo>         carrega o dicionário por um documento oculto
//   convert <src> <dst> <fmt> abre oculto, salva e fecha ("-": documento novo)
//   repaint                   redesenha todos os ladrilhos
//   invert <papel> <tinta> <fonte>  o papel escuro (D-074), em rrggbb; "off" desliga
//   a11y on|off               setAccessibilityState (callbacks 62 e 63)
//   color <rrggbb> [tol]      conta os pixels perto da cor nos ladrilhos
//   # ...                     comentário
//
// Uso: lok_script <pasta-de-trabalho> [filtro] < roteiro
// O filtro (números de callback separados por vírgula) esconde os outros;
// sem ele, mostra tudo menos ladrilhos e invalidações.
#define LOK_USE_UNSTABLE_API
#include <LibreOfficeKit/LibreOfficeKitEnums.h>

#include <chrono>
#include <clocale>
#include <cstdlib>
#include <cstdio>
#include <iostream>
#include <memory>
#include <set>
#include <sstream>
#include <string>
#include <thread>

#include "core/lok_engine.h"

using namespace pqk;

namespace {

class Printer : public EngineSink {
 public:
  explicit Printer(std::set<int> only) : only_(std::move(only)) {}
  void onEvent(int32_t type, const std::string& payload) override {
    if (!only_.empty() && !only_.count(type)) return;
    if (only_.empty() && (type == LOK_CALLBACK_INVALIDATE_TILES || type == kEvTile)) return;
    std::string p = payload.size() > 40000 ? payload.substr(0, 40000) + "…" : payload;
    printf("  [%d] %s\n", type, p.c_str());
    fflush(stdout);
  }
  void onTileUpdated(int) override {}

 private:
  std::set<int> only_;
};

}  // namespace

int main(int argc, char** argv) {
  if (argc < 2) {
    fprintf(stderr, "uso: %s <pasta-de-trabalho> [filtro] < roteiro\n", argv[0]);
    return 2;
  }
  std::set<int> only;
  if (argc > 2) {
    std::stringstream ss(argv[2]);
    std::string n;
    while (std::getline(ss, n, ',')) only.insert(std::stoi(n));
  }
  // Como o app: o GTK chama setlocale(LC_ALL, "") (LOK_SCRIPT_LOCALE=1).
  if (getenv("LOK_SCRIPT_LOCALE")) setlocale(LC_ALL, "");
  Printer sink(only);
  LokEngine e(&sink, 64);
  e.init("/usr/lib/libreoffice/program", std::string("file://") + argv[1] + "/perfil-lo");
  e.drain();
  std::this_thread::sleep_for(std::chrono::milliseconds(200));

  std::string line;
  while (std::getline(std::cin, line)) {
    if (line.empty() || line[0] == '#') continue;
    printf("> %s\n", line.c_str());
    fflush(stdout);
    std::istringstream in(line);
    std::string op;
    in >> op;
    std::string rest;
    std::getline(in >> std::ws, rest);
    if (op == "open") {
      e.open(rest == "-" ? "" : rest);
      e.setViewport(1000, {0, 0, 18000, 12000});
    } else if (op == "close") {
      e.close();
    } else if (op == "open0") {
      e.open(rest == "-" ? "" : rest);
    } else if (op == "view") {
      int sc = 1000;
      long long x = 0, y = 0, w = 0, h = 0;
      std::istringstream(rest) >> sc >> x >> y >> w >> h;
      e.setViewport(sc, {x, y, w, h});
    } else if (op == "uno") {
      auto sp = rest.find(' ');
      e.uno(rest.substr(0, sp), sp == std::string::npos ? "" : rest.substr(sp + 1));
    } else if (op == "convert") {
      std::istringstream a(rest);
      std::string src, dst, fmt;
      a >> src >> dst >> fmt;
      e.convert(1, src == "-" ? "" : src, dst, fmt);
    } else if (op == "preload") {
      e.preloadSpelling(rest);
    } else if (op == "invert") {
      if (rest == "off") {
        e.setPaperInvert(false, 0, 0, 0);
      } else {
        unsigned p = 0, k = 0, f = 0;
        std::istringstream(rest) >> std::hex >> p >> k >> f;
        e.setPaperInvert(true, p, k, f);
      }
      e.repaintAll();
    } else if (op == "repaint") {
      e.repaintAll();
    } else if (op == "a11y") {
      e.setAccessibility(rest == "on");
    } else if (op == "color") {
      unsigned rgb = 0;
      int tol = 40;
      std::istringstream in(rest);
      in >> std::hex >> rgb >> std::dec >> tol;
      const int r = (rgb >> 16) & 255, g = (rgb >> 8) & 255, b = rgb & 255;
      std::this_thread::sleep_for(std::chrono::milliseconds(300));
      long count = 0;
      for (int i = 0; i < e.tiles().slotCount(); ++i) {
        auto& slot = e.tiles().slot(i);
        std::lock_guard<std::mutex> lock(slot.mutex);
        const uint8_t* p = slot.pixels.get();
        if (!p) continue;
        for (int j = 0; j < kTileBytes; j += 4) {
          if (std::abs(p[j] - r) <= tol && std::abs(p[j + 1] - g) <= tol && std::abs(p[j + 2] - b) <= tol) ++count;
        }
      }
      printf("  cor %06x: %ld pixels\n", rgb, count);
      fflush(stdout);
    } else if (op == "values") {
      e.commandValues(rest);
    } else if (op == "type") {
      e.extTextInput(LOK_EXT_TEXTINPUT, rest);
      e.extTextInput(LOK_EXT_TEXTINPUT_END, "");
    } else if (op == "key") {
      int c = 0, k = 0;
      std::istringstream(rest) >> c >> k;
      e.postKey(LOK_KEYEVENT_KEYINPUT, c, k);
      e.postKey(LOK_KEYEVENT_KEYUP, c, k);
    } else if (op == "click") {
      int x = 0, y = 0, n = 1, b = 1, m = 0;
      std::istringstream(rest) >> x >> y >> n >> b >> m;
      e.postMouse(LOK_MOUSEEVENT_MOUSEBUTTONDOWN, x, y, n, b, m);
      e.postMouse(LOK_MOUSEEVENT_MOUSEBUTTONUP, x, y, n, b, m);
    } else if (op == "gsel") {
      int t = 0, x = 0, y = 0;
      std::istringstream(rest) >> t >> x >> y;
      e.setGraphicSelection(t, x, y);
    } else if (op == "sel") {
      e.textSelection("text/plain;charset=utf-8");
    } else if (op == "save") {
      auto sp = rest.rfind(' ');
      e.saveAs(rest.substr(0, sp), rest.substr(sp + 1), "");
    } else if (op == "wait") {
      e.drain();
      std::this_thread::sleep_for(std::chrono::milliseconds(std::stoi(rest)));
      continue;
    } else {
      fprintf(stderr, "passo desconhecido: %s\n", op.c_str());
      continue;
    }
    e.drain();
    std::this_thread::sleep_for(std::chrono::milliseconds(80));
  }
  e.drain();
  std::this_thread::sleep_for(std::chrono::milliseconds(300));
  fflush(stdout);
  _exit(0);  // os destrutores estáticos do LO derrubam o processo (D-027)
}
