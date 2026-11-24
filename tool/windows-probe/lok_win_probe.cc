// A sonda do LibreOfficeKit no Windows (D-078): o LibreOffice comum do Windows
// serve de motor para o Quill? Faz o que o plugin do Linux faz, sem Flutter:
// liga o motor com um perfil próprio, abre um DOCX, desenha ladrilhos, digita
// por teclas, liga o negrito e espera o estado voltar, pede a lista de fontes e
// salva em ODT e PDF. Imprime uma linha por passo ("ok" ou "FALHOU").
//
// Compila no Linux com o MinGW (tool/windows-probe/build.sh), sem nada do Quill.
// Uso, no Windows: lok_win_probe.exe "<pasta program do LO>" <pasta de trabalho> <arquivo.docx>
#include <algorithm>
#include <atomic>
#include <cstdlib>
#include <chrono>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <string>
#include <thread>
#include <vector>

#define LOK_USE_UNSTABLE_API
#include <LibreOfficeKit/LibreOfficeKit.h>
#include <LibreOfficeKit/LibreOfficeKitEnums.h>
#include <LibreOfficeKit/LibreOfficeKitInit.h>

namespace {

using Clock = std::chrono::steady_clock;

std::atomic<int> g_invalidations{0};
std::atomic<int> g_cursor{0};
std::atomic<bool> g_bold{false};
std::atomic<int> g_states{0};
std::atomic<int> g_types[128];

int failures = 0;

void report(const char* step, bool ok, const std::string& detail = "") {
  std::printf("%-28s %s %s\n", step, ok ? "ok    " : "FALHOU", detail.c_str());
  std::fflush(stdout);
  if (!ok) failures++;
}

long ms_since(Clock::time_point t) {
  return (long)std::chrono::duration_cast<std::chrono::milliseconds>(Clock::now() - t).count();
}

// C:\a\b → file:///C:/a/b
std::string file_url(std::string path) {
  for (auto& c : path)
    if (c == '\\') c = '/';
  return "file:///" + path;
}

void doc_callback(int type, const char* payload, void*) {
  if (type >= 0 && type < 128) g_types[type]++;
  switch (type) {
    case LOK_CALLBACK_INVALIDATE_TILES: g_invalidations++; break;
    case LOK_CALLBACK_INVALIDATE_VISIBLE_CURSOR: g_cursor++; break;
    case LOK_CALLBACK_STATE_CHANGED:
      g_states++;
      if (payload && std::strncmp(payload, ".uno:Bold=", 10) == 0) g_bold = std::strcmp(payload + 10, "true") == 0;
      break;
    default: break;
  }
}

template <class F>
bool wait_for(F cond, int ms) {
  const auto t = Clock::now();
  while (!cond()) {
    if (ms_since(t) > ms) return false;
    std::this_thread::sleep_for(std::chrono::milliseconds(20));
  }
  return true;
}

// Desenha um ladrilho de 256 px cobrindo `twips` e conta os pixels que não são
// brancos (o texto). Grava um PPM para conferir à mão.
int paint(LibreOfficeKitDocument* doc, int x, int y, int twips, const std::string& ppm) {
  const int px = 256;
  std::vector<unsigned char> buf(px * px * 4);
  doc->pClass->paintTile(doc, buf.data(), px, px, x, y, twips, twips);
  int ink = 0;
  std::ofstream out(ppm, std::ios::binary);
  out << "P6\n" << px << " " << px << "\n255\n";
  for (int i = 0; i < px * px; i++) {
    // BGRA no Windows e no Linux (LOK_TILEMODE_BGRA)
    unsigned char b = buf[i * 4], g = buf[i * 4 + 1], r = buf[i * 4 + 2];
    if (r < 200 || g < 200 || b < 200) ink++;
    out.put((char)r).put((char)g).put((char)b);
  }
  return ink;
}

long file_size(const std::string& p) {
  std::ifstream f(p, std::ios::binary | std::ios::ate);
  return f ? (long)f.tellg() : -1;
}

}  // namespace

int main(int argc, char** argv) {
  if (argc < 4) {
    std::fprintf(stderr, "uso: lok_win_probe <pasta program> <pasta de trabalho> <arquivo.docx>\n");
    return 2;
  }
  const std::string program = argv[1];
  const std::string work = argv[2];
  const std::string docx = argv[3];

  auto t = Clock::now();
  LibreOfficeKit* kit = lok_init_2(program.c_str(), file_url(work + "\\perfil-lo").c_str());
  report("ligar o motor (lok_init_2)", kit != nullptr, std::to_string(ms_since(t)) + " ms");
  if (!kit) return 1;

  char* version = kit->pClass->getVersionInfo(kit);
  report("versão", version != nullptr, version ? version : "");
  if (version) kit->pClass->freeError(version);

  t = Clock::now();
  LibreOfficeKitDocument* doc = kit->pClass->documentLoadWithOptions(kit, file_url(docx).c_str(), "Language=pt-BR");
  const long open_ms = ms_since(t);
  if (!doc) {
    char* err = kit->pClass->getError(kit);
    report("abrir o DOCX", false, err ? err : "");
    return 1;
  }
  report("abrir o DOCX", true, std::to_string(open_ms) + " ms");

  report("tipo de documento", doc->pClass->getDocumentType(doc) == LOK_DOCTYPE_TEXT);
  kit->pClass->setOptionalFeatures(kit, LOK_FEATURE_DOCUMENT_PASSWORD | LOK_FEATURE_NO_TILED_ANNOTATIONS |
                                             LOK_FEATURE_RANGE_HEADERS |
                                             LOK_FEATURE_VIEWID_IN_VISCURSOR_INVALIDATION_CALLBACK);
  doc->pClass->initializeForRendering(doc, "{}");
  doc->pClass->registerCallback(doc, doc_callback, nullptr);
  // Como o Quill: a área visível (a primeira tela) e o zoom do cliente.
  doc->pClass->setClientVisibleArea(doc, 0, 0, 12474, 9000);
  doc->pClass->setClientZoom(doc, 256, 256, 3840, 3840);
  long w = 0, h = 0;
  doc->pClass->getDocumentSize(doc, &w, &h);
  report("tamanho (twips)", w > 0 && h > 0,
         std::to_string(w) + " x " + std::to_string(h) + " (~" + std::to_string(h / 16838) + " páginas A4)");

  // O primeiro ladrilho (o canto da página) e um no meio do texto.
  t = Clock::now();
  const int ink0 = paint(doc, 0, 0, 3840, work + "\\ladrilho-0.ppm");
  report("primeiro ladrilho", true, std::to_string(ms_since(t)) + " ms, " + std::to_string(ink0) + " px de tinta");
  const int ink1 = paint(doc, 1440, 1440 + 16838 * 2, 3840, work + "\\ladrilho-texto.ppm");
  report("ladrilho com texto", ink1 > 200, std::to_string(ink1) + " px de tinta");

  // O motor só invalida dentro da área já pintada (CallbackFlushHandler::
  // m_aPaintedTiles). Um ladrilho grande, de baixa resolução, cobre o documento
  // inteiro, para o fim do documento também contar.
  if (std::getenv("PROBE_PINTAR_TUDO")) {
    std::vector<unsigned char> all(256 * 256 * 4);
    doc->pClass->paintTile(doc, all.data(), 256, 256, 0, 0, (int)std::max(w, h), (int)std::max(w, h));
    report("pintar o documento inteiro", true);
  }

  // Teclas no começo do documento, dentro da área pintada.
  const int inv_start = g_invalidations;
  doc->pClass->postUnoCommand(doc, ".uno:GoToStartOfDoc", nullptr, false);
  for (int c : {'A', 'b'}) {
    doc->pClass->postKeyEvent(doc, LOK_KEYEVENT_KEYINPUT, c, 0);
    doc->pClass->postKeyEvent(doc, LOK_KEYEVENT_KEYUP, c, 0);
  }
  report("digitar no começo: a invalidação", wait_for([&] { return g_invalidations > inv_start; }, 5000),
         std::to_string(g_invalidations - inv_start) + " invalidações");

  // Teclas: o cursor ao fim do documento e três letras, como o Quill digita.
  const int inv_before = g_invalidations;
  doc->pClass->postUnoCommand(doc, ".uno:GoToEndOfDoc", nullptr, false);
  for (int c : {'Q', 'u', 'i'}) {
    doc->pClass->postKeyEvent(doc, LOK_KEYEVENT_KEYINPUT, c, 0);
    doc->pClass->postKeyEvent(doc, LOK_KEYEVENT_KEYUP, c, 0);
  }
  const bool typed = wait_for([&] { return g_invalidations > inv_before; }, 5000);
  report("digitar: a invalidação", typed,
         std::to_string(g_invalidations - inv_before) + " invalidações, " + std::to_string(g_cursor) + " cursores");
  // O texto entrou? O ladrilho do começo, desenhado de novo, muda.
  std::this_thread::sleep_for(std::chrono::milliseconds(1000));
  const int ink0b = paint(doc, 0, 0, 3840, work + "\\ladrilho-0-depois.ppm");
  // Chamadas síncronas fazem o motor rodar a fila dele: a invalidação chega depois?
  for (int i = 0; i < 10 && g_invalidations == inv_before; i++) {
    char* v = doc->pClass->getCommandValues(doc, ".uno:LanguageStatus");
    if (v) kit->pClass->freeError(v);
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
  }
  report("digitar: a invalidação, depois", g_invalidations > inv_before,
         std::to_string(g_invalidations - inv_before) + " invalidações");
  report("digitar: o ladrilho muda", ink0b != ink0, std::to_string(ink0) + " → " + std::to_string(ink0b) + " px de tinta");

  // O texto acentuado como o IME manda.
  doc->pClass->postWindowExtTextInputEvent(doc, 0, LOK_EXT_TEXTINPUT, "ção");
  doc->pClass->postWindowExtTextInputEvent(doc, 0, LOK_EXT_TEXTINPUT_END, "");

  // Negrito: o estado volta pelo callback.
  doc->pClass->postUnoCommand(doc, ".uno:SelectAll", nullptr, false);
  doc->pClass->postUnoCommand(doc, ".uno:Bold", nullptr, true);
  report("negrito e o estado", wait_for([] { return g_bold.load(); }, 5000),
         std::to_string(g_states) + " estados recebidos");
  doc->pClass->postUnoCommand(doc, ".uno:Undo", nullptr, false);

  char* fonts = doc->pClass->getCommandValues(doc, ".uno:CharFontName");
  const size_t fonts_len = fonts ? std::strlen(fonts) : 0;
  report("lista de fontes", fonts_len > 100, std::to_string(fonts_len) + " bytes de JSON");
  if (fonts) kit->pClass->freeError(fonts);

  const std::string odt = work + "\\salvo.odt", pdf = work + "\\salvo.pdf";
  t = Clock::now();
  const bool saved = doc->pClass->saveAs(doc, file_url(odt).c_str(), "odt", nullptr);
  report("salvar em ODT", saved && file_size(odt) > 1000,
         std::to_string(file_size(odt)) + " bytes, " + std::to_string(ms_since(t)) + " ms");
  const bool exported = doc->pClass->saveAs(doc, file_url(pdf).c_str(), "pdf", nullptr);
  report("exportar o PDF", exported && file_size(pdf) > 1000, std::to_string(file_size(pdf)) + " bytes");

  std::string types;
  for (int i = 0; i < 128; i++)
    if (g_types[i]) types += std::to_string(i) + ":" + std::to_string(g_types[i]) + " ";
  report("callbacks por tipo", true, types);

  doc->pClass->destroy(doc);
  kit->pClass->destroy(kit);
  std::printf("\n%s\n", failures == 0 ? "RESULTADO: o motor funciona no Windows" : "RESULTADO: falhou");
  return failures == 0 ? 0 : 1;
}
