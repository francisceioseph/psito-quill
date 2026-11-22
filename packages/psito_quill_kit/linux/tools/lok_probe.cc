// lok_probe: mede o motor sem a UI (Fase 0).
//
// Abre o LOK do sistema no próprio processo, como o app, e mede: RSS vazio e
// com o documento, tempo de abrir, desenho de ladrilhos, latência tecla →
// ladrilho pronto, negrito, salvar/reabrir, papel escuro, e grava ladrilhos a
// 1x e 1,25x para comparar a nitidez.
//
// Uso: lok_probe <documento> <pasta-de-saída> [instalação-do-LO]
// Saída: JSON no stdout e PPMs na pasta.
#define LOK_USE_UNSTABLE_API
#include <LibreOfficeKit/LibreOfficeKitEnums.h>

#include <condition_variable>
#include <cstdio>
#include <cstring>
#include <map>
#include <mutex>
#include <string>
#include <thread>

#include "core/lok_engine.h"

using namespace pqk;
using Clock = std::chrono::steady_clock;

namespace {

double since(Clock::time_point t) {
  return std::chrono::duration<double, std::milli>(Clock::now() - t).count();
}
double mb(int64_t b) { return b / 1048576.0; }

class Sink : public EngineSink {
 public:
  void onEvent(int32_t type, const std::string& payload) override {
    std::lock_guard<std::mutex> lock(m_);
    last_[type] = payload;
    ++count_[type];
    if (type == LOK_CALLBACK_STATE_CHANGED) states_.push_back(payload);
    cv_.notify_all();
  }
  void onTileUpdated(int) override {
    std::lock_guard<std::mutex> lock(m_);
    ++tiles_;
  }
  bool wait(int type, int ms = 30000) {
    std::unique_lock<std::mutex> lock(m_);
    int before = seen_[type];
    bool ok = cv_.wait_for(lock, std::chrono::milliseconds(ms),
                           [&] { return count_[type] > before; });
    seen_[type] = count_[type];
    return ok;
  }
  std::string last(int type) {
    std::lock_guard<std::mutex> lock(m_);
    return last_[type];
  }
  int tiles() {
    std::lock_guard<std::mutex> lock(m_);
    return tiles_;
  }
  bool sawState(const std::string& s) {
    std::lock_guard<std::mutex> lock(m_);
    for (auto& x : states_)
      if (x.find(s) != std::string::npos) return true;
    return false;
  }
  void clearStates() {
    std::lock_guard<std::mutex> lock(m_);
    states_.clear();
  }

 private:
  std::mutex m_;
  std::condition_variable cv_;
  std::map<int, std::string> last_;
  std::map<int, int> count_, seen_;
  std::vector<std::string> states_;
  int tiles_ = 0;
};

long jsonInt(const std::string& json, const char* key) {
  auto p = json.find(std::string("\"") + key + "\":");
  return p == std::string::npos ? 0 : atol(json.c_str() + p + strlen(key) + 3);
}

void writePpm(const std::string& path, const uint8_t* rgba) {
  FILE* f = fopen(path.c_str(), "wb");
  fprintf(f, "P6\n%d %d\n255\n", kTileSize, kTileSize);
  for (int i = 0; i < kTileSize * kTileSize; ++i) fwrite(rgba + i * 4, 1, 3, f);
  fclose(f);
}

double meanLuma(TileCache& c, int slot) {
  std::lock_guard<std::mutex> lock(c.slot(slot).mutex);
  const uint8_t* p = c.slot(slot).pixels.get();
  double sum = 0;
  for (int i = 0; i < kTileBytes; i += 4) sum += 0.2126 * p[i] + 0.7152 * p[i + 1] + 0.0722 * p[i + 2];
  return sum / (kTileSize * kTileSize);
}

// Espera a fila esvaziar e os ladrilhos pararem de chegar.
void settle(LokEngine& e, Sink& s, int quietMs = 300) {
  int last = -1;
  while (true) {
    e.drain();
    std::this_thread::sleep_for(std::chrono::milliseconds(quietMs));
    e.drain();
    int now = s.tiles();
    if (now == last) return;
    last = now;
  }
}

}  // namespace

int main(int argc, char** argv) {
  if (argc < 3) {
    fprintf(stderr, "uso: %s <documento> <pasta-de-saída> [instalação]\n", argv[0]);
    return 2;
  }
  const std::string docPath = argv[1], outDir = argv[2];
  const std::string install = argc > 3 ? argv[3] : "/usr/lib/libreoffice/program";
  const std::string profile = "file://" + outDir + "/perfil-lo";

  Sink sink;
  // 128 vagas = 32 MB, o que o app usa por padrão.
  auto engine = std::make_unique<LokEngine>(&sink, 128);
  LokEngine& e = *engine;
  std::string json = "{\n";
  auto put = [&](const std::string& k, const std::string& v) {
    json += "  \"" + k + "\": " + v + ",\n";
    fprintf(stderr, "%s = %s\n", k.c_str(), v.c_str());
  };
  char b[256];

  put("rss_antes_mb", std::to_string(mb(residentBytes())));
  auto t = Clock::now();
  e.init(install, profile);
  if (!sink.wait(kEvReady, 60000)) {
    fprintf(stderr, "init falhou: %s\n", sink.last(kEvInitFailed).c_str());
    return 1;
  }
  put("init_ms", std::to_string(since(t)));
  put("versao", "\"" + [&] {
    std::string v = sink.last(kEvReady), out;
    for (char c : v) out += (c == '"') ? '\'' : c;
    return out;
  }() + "\"");

  // A tela do app: ~1200×800 px lógicos. Viewport em twips na escala 1.
  const int32_t vw = 1200 * 15, vh = 800 * 15;

  // --- documento vazio ---
  t = Clock::now();
  e.open("");
  if (!sink.wait(kEvOpened)) return 1;
  e.setViewport(1000, {0, 0, vw, vh});
  settle(e, sink);
  put("vazio_abrir_e_desenhar_ms", std::to_string(since(t)));
  put("rss_vazio_mb", std::to_string(mb(residentBytes())));

  // --- documento de 30 páginas ---
  t = Clock::now();
  e.open(docPath);
  if (!sink.wait(kEvOpened)) {
    fprintf(stderr, "abrir falhou: %s\n", sink.last(kEvOpenFailed).c_str());
    return 1;
  }
  double openMs = since(t);
  std::string opened = sink.last(kEvOpened);
  long docW = jsonInt(opened, "width"), docH = jsonInt(opened, "height");
  put("abrir_ms", std::to_string(openMs));
  put("doc_twips", "\"" + std::to_string(docW) + "x" + std::to_string(docH) + "\"");
  t = Clock::now();
  int tiles0 = sink.tiles();
  e.setViewport(1000, {0, 0, vw, vh});
  settle(e, sink, 150);
  put("primeira_tela_ms", std::to_string(since(t) - 150));
  put("primeira_tela_ladrilhos", std::to_string(sink.tiles() - tiles0));
  put("rss_30p_mb", std::to_string(mb(residentBytes())));

  // Rolar o documento inteiro, uma tela por vez.
  t = Clock::now();
  tiles0 = sink.tiles();
  for (long y = 0; y < docH; y += vh) {
    e.setViewport(1000, {0, y, vw, vh});
    e.drain();
  }
  settle(e, sink, 150);
  double scrollMs = since(t) - 150;
  int scrolled = sink.tiles() - tiles0;
  put("rolar_tudo_ms", std::to_string(scrollMs));
  put("rolar_ladrilhos", std::to_string(scrolled));
  put("ms_por_ladrilho", std::to_string(scrollMs / std::max(1, scrolled)));
  put("rss_30p_depois_de_rolar_mb", std::to_string(mb(residentBytes())));

  // --- digitar ---
  e.setViewport(1000, {0, 0, vw, vh});
  settle(e, sink, 150);
  // Clique no início do primeiro parágrafo (margem de 2 cm da página).
  e.postMouse(LOK_MOUSEEVENT_MOUSEBUTTONDOWN, 1700, 3200, 1, 1, 0);
  e.postMouse(LOK_MOUSEEVENT_MOUSEBUTTONUP, 1700, 3200, 1, 1, 0);
  settle(e, sink, 200);
  e.resetLatency();
  const std::string typed = "Kaelen olhou o horizonte. ";
  const int kKeys = 200;
  for (int i = 0; i < kKeys; ++i) {
    int ch = static_cast<unsigned char>(typed[i % typed.size()]);
    e.postKey(LOK_KEYEVENT_KEYINPUT, ch, 0);
    e.postKey(LOK_KEYEVENT_KEYUP, ch, 0);
    std::this_thread::sleep_for(std::chrono::milliseconds(80));  // ~ 12 teclas/s
  }
  settle(e, sink, 300);
  LatencyStats lat = e.latency();
  snprintf(b, sizeof b, "{\"amostras\": %zu, \"p50_ms\": %.2f, \"p95_ms\": %.2f, \"max_ms\": %.2f}",
           lat.count, lat.p50, lat.p95, lat.max);
  put("latencia_tecla_ladrilho", b);
  put("rss_depois_de_digitar_mb", std::to_string(mb(residentBytes())));

  // Crescimento: PQK_PROBE_LONGO=N digita N teclas (com Enter a cada 60) e
  // anota o RSS a cada 250, para ver se a memória estabiliza.
  if (const char* longo = getenv("PQK_PROBE_LONGO")) {
    int n = atoi(longo);
    std::string serie = "[";
    for (int i = 1; i <= n; ++i) {
      int ch = (i % 60 == 0) ? 13 : static_cast<unsigned char>(typed[i % typed.size()]);
      e.postKey(LOK_KEYEVENT_KEYINPUT, ch, ch == 13 ? 1280 : 0);
      e.postKey(LOK_KEYEVENT_KEYUP, ch, ch == 13 ? 1280 : 0);
      std::this_thread::sleep_for(std::chrono::milliseconds(25));
      if (i % 250 == 0) {
        e.drain();
        serie += (serie.size() > 1 ? ", " : "") + std::to_string(static_cast<int>(mb(residentBytes())));
      }
    }
    put("rss_a_cada_250_teclas_mb", serie + "]");
  }

  // Rajada: teclas sem pausa (alguém digitando rápido / tecla presa).
  e.resetLatency();
  for (int i = 0; i < 60; ++i) {
    e.postKey(LOK_KEYEVENT_KEYINPUT, 'a', 0);
    e.postKey(LOK_KEYEVENT_KEYUP, 'a', 0);
    std::this_thread::sleep_for(std::chrono::milliseconds(15));
  }
  settle(e, sink, 300);
  lat = e.latency();
  snprintf(b, sizeof b, "{\"amostras\": %zu, \"p50_ms\": %.2f, \"p95_ms\": %.2f, \"max_ms\": %.2f}",
           lat.count, lat.p50, lat.p95, lat.max);
  put("latencia_rajada_15ms", b);

  // --- negrito ---
  sink.clearStates();
  // Seleciona a palavra anterior (Ctrl+Shift+Esquerda) e aplica negrito.
  const int KEY_LEFT = 1026, KEY_SHIFT = 0x1000, KEY_MOD1 = 0x2000;
  e.postKey(LOK_KEYEVENT_KEYINPUT, 0, KEY_LEFT | KEY_SHIFT | KEY_MOD1);
  e.postKey(LOK_KEYEVENT_KEYUP, 0, KEY_LEFT | KEY_SHIFT | KEY_MOD1);
  settle(e, sink, 200);
  e.uno(".uno:Bold", "");
  settle(e, sink, 300);
  put("negrito_estado_true", sink.sawState(".uno:Bold=true") ? "true" : "false");

  // --- salvar e reabrir ---
  const std::string saved = outDir + "/salvo.docx";
  t = Clock::now();
  e.saveAs(saved, "docx", "");
  bool ok = sink.wait(kEvSaved, 30000);
  put("salvar_ms", std::to_string(since(t)));
  put("salvar_ok", ok ? "true" : "false");
  e.open(saved);
  ok = sink.wait(kEvOpened, 30000);
  put("reabrir_ok", ok ? "true" : "false");

  // --- nitidez: o mesmo trecho a 1x e 1,25x ---
  // Ladrilho que contém o começo do texto (perto de x=1700, y=3200 twips).
  for (int scale : {1000, 1250, 2000}) {
    e.setViewport(scale, {0, 0, vw, vh});
    settle(e, sink, 200);
    double side = tileTwips(scale);
    TileKey k{static_cast<int>(1700 / side), static_cast<int>(3200 / side), scale};
    int s = e.tiles().find(k);
    if (s >= 0) {
      std::lock_guard<std::mutex> lock(e.tiles().slot(s).mutex);
      writePpm(outDir + "/ladrilho-" + std::to_string(scale) + ".ppm",
               e.tiles().slot(s).pixels.get());
    }
  }

  // --- papel escuro ---
  e.setViewport(1000, {0, 0, vw, vh});
  settle(e, sink, 200);
  TileKey paper{1, 1, 1000};  // dentro da página, longe da borda
  int ps = e.tiles().find(paper);
  double before = ps >= 0 ? meanLuma(e.tiles(), ps) : -1;
  std::string themes = "{\"luma_antes\": " + std::to_string(before);
  for (const char* name : {"Dark", "LibreOffice Dark"}) {
    std::string args = std::string("{\"NewTheme\":{\"type\":\"string\",\"value\":\"") + name + "\"}}";
    e.uno(".uno:ChangeTheme", args);
    sink.wait(LOK_CALLBACK_UNO_COMMAND_RESULT, 5000);
    std::string result = sink.last(LOK_CALLBACK_UNO_COMMAND_RESULT);
    e.repaintAll();
    settle(e, sink, 500);
    ps = e.tiles().find(paper);
    double after = ps >= 0 ? meanLuma(e.tiles(), ps) : -1;
    if (ps >= 0) {
      std::lock_guard<std::mutex> lock(e.tiles().slot(ps).mutex);
      writePpm(outDir + "/escuro-" + std::string(name).substr(0, 4) + ".ppm", e.tiles().slot(ps).pixels.get());
    }
    for (char& c : result) if (c == '"') c = '\'';
    themes += std::string(", \"") + name + "\": {\"luma\": " + std::to_string(after) + ", \"resultado\": \"" + result + "\"}";
  }
  put("papel_escuro", themes + "}");

  put("rss_final_mb", std::to_string(mb(residentBytes())));
  json += "  \"fim\": true\n}\n";
  printf("%s", json.c_str());
  fflush(stdout);
  // Sair sem destruir o LOK: o destroy dele às vezes demora segundos.
  _exit(0);
}
