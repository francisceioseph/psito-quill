// lok_two_docs: a sonda das abas leves (D-051). Dois documentos no mesmo
// processo do LibreOfficeKit 24.2 funcionam? Quanto custa o segundo? E quanto
// fica para trás depois de fechar e reabrir (o que a troca de aba faz)?
//
// Uso: lok_two_docs <pasta-de-trabalho> <documento.docx>
// Trabalha em cópias do documento dentro da pasta. Imprime cada passo e o RSS,
// e no fim confere, salvando cada documento como .odt, que o texto digitado
// em cada um foi parar nele e só nele. Não abre janela.
#define LOK_USE_UNSTABLE_API
#include <LibreOfficeKit/LibreOfficeKit.h>
#include <LibreOfficeKit/LibreOfficeKitEnums.h>
#include <LibreOfficeKit/LibreOfficeKitInit.h>

#include <unistd.h>

#include <atomic>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <string>
#include <thread>

namespace fs = std::filesystem;

namespace {

double rssMb() {
  long pages = 0, resident = 0;
  FILE* f = fopen("/proc/self/statm", "r");
  if (!f) return -1;
  if (fscanf(f, "%ld %ld", &pages, &resident) != 2) resident = 0;
  fclose(f);
  return resident * sysconf(_SC_PAGESIZE) / 1048576.0;
}

// A memória anônima (o que pesa de verdade), do /proc/self/smaps_rollup.
double anonMb() {
  FILE* f = fopen("/proc/self/smaps_rollup", "r");
  if (!f) return -1;
  char line[256];
  long kb = 0;
  while (fgets(line, sizeof line, f))
    if (sscanf(line, "Anonymous: %ld kB", &kb) == 1) break;
  fclose(f);
  return kb / 1024.0;
}

struct Counter {
  const char* name;
  std::atomic<int> events{0};
};

void callback(int type, const char*, void* data) {
  if (type == LOK_CALLBACK_INVALIDATE_TILES || type == LOK_CALLBACK_INVALIDATE_VISIBLE_CURSOR ||
      type == LOK_CALLBACK_TEXT_SELECTION)
    static_cast<Counter*>(data)->events++;
}

void pause(int ms) { std::this_thread::sleep_for(std::chrono::milliseconds(ms)); }

void step(const char* what) { printf("%-46s RSS %7.1f MB  anônima %7.1f MB\n", what, rssMb(), anonMb()); fflush(stdout); }

LibreOfficeKitDocument* load(LibreOfficeKit* kit, const std::string& path, Counter* c) {
  auto* d = kit->pClass->documentLoadWithOptions(kit, ("file://" + path).c_str(), "Language=pt-BR");
  if (!d) {
    printf("FALHOU ao abrir %s: %s\n", path.c_str(), kit->pClass->getError(kit));
    return nullptr;
  }
  d->pClass->initializeForRendering(d, "{}");
  d->pClass->registerCallback(d, callback, c);
  d->pClass->setClientVisibleArea(d, 0, 0, 18000, 12000);
  return d;
}

// Digita no começo do documento, como o app (a entrada do IME confirmada).
void typeAtStart(LibreOfficeKitDocument* d, const char* text, bool setView) {
  if (setView) d->pClass->setView(d, d->pClass->getView(d));
  d->pClass->postMouseEvent(d, LOK_MOUSEEVENT_MOUSEBUTTONDOWN, 1700, 1700, 1, 1, 0);
  d->pClass->postMouseEvent(d, LOK_MOUSEEVENT_MOUSEBUTTONUP, 1700, 1700, 1, 1, 0);
  pause(100);
  d->pClass->postUnoCommand(d, ".uno:GoToStartOfDoc", nullptr, false);
  pause(100);
  d->pClass->postWindowExtTextInputEvent(d, 0, LOK_EXT_TEXTINPUT, text);
  d->pClass->postWindowExtTextInputEvent(d, 0, LOK_EXT_TEXTINPUT_END, "");
  pause(300);
}

// Salva como .odt e diz quais marcas estão no texto.
void check(LibreOfficeKitDocument* d, const std::string& dir, const char* name, bool setView) {
  if (setView) d->pClass->setView(d, d->pClass->getView(d));
  std::string out = dir + "/" + name + ".odt";
  int ok = d->pClass->saveAs(d, ("file://" + out).c_str(), "odt", nullptr);
  std::string cmd = "unzip -p '" + out + "' content.xml | grep -o 'MARCA[A-Z0-9]*' | sort | uniq -c | tr '\\n' ' '";
  printf("  %s: saveAs %s, marcas: ", name, ok ? "ok" : "FALHOU");
  fflush(stdout);
  if (system(cmd.c_str()) != 0) printf("(nenhuma)");
  printf("\n");
  fflush(stdout);
}

// Um ladrilho do canto da primeira página: a soma dos pixels escuros diz se o
// texto do documento certo está ali.
long darkPixels(LibreOfficeKitDocument* d, bool setView) {
  if (setView) d->pClass->setView(d, d->pClass->getView(d));
  static unsigned char buf[256 * 256 * 4];
  d->pClass->paintTile(d, buf, 256, 256, 1000, 1000, 6000, 6000);
  long dark = 0;
  for (int i = 0; i < 256 * 256 * 4; i += 4)
    if (buf[i] < 128) dark++;
  return dark;
}

// Pinta o documento inteiro, de cima a baixo, como a rolagem do app: o Writer
// só monta as páginas que alguém pede.
void paintAll(LibreOfficeKitDocument* d) {
  static unsigned char buf[256 * 256 * 4];
  long w = 0, h = 0;
  d->pClass->getDocumentSize(d, &w, &h);
  for (long y = 0; y < h; y += 12000) d->pClass->paintTile(d, buf, 256, 256, 0, y, 12000, 12000);
}

}  // namespace

int main(int argc, char** argv) {
  if (argc < 3) {
    fprintf(stderr, "uso: %s <pasta-de-trabalho> <documento.docx>\n", argv[0]);
    return 2;
  }
  std::string dir = fs::absolute(argv[1]);
  fs::create_directories(dir);
  std::string a = dir + "/a.docx", b = dir + "/b.docx";
  fs::copy_file(argv[2], a, fs::copy_options::overwrite_existing);
  fs::copy_file(argv[2], b, fs::copy_options::overwrite_existing);
  bool setView = getenv("SETVIEW") != nullptr;
  printf("setView antes de cada chamada: %s\n", setView ? "sim" : "não");

  setenv("SAL_LOG", "-WARN-INFO", 0);
  setenv("LOK_ALLOWLIST_LANGUAGES", "pt_BR en_US", 0);
  step("início");
  auto* kit = lok_init_2("/usr/lib/libreoffice/program", ("file://" + dir + "/perfil-lo").c_str());
  if (!kit) return 1;
  kit->pClass->setOptionalFeatures(kit, LOK_FEATURE_NO_TILED_ANNOTATIONS | LOK_FEATURE_RANGE_HEADERS);
  step("motor ligado");

  Counter ca{"A"}, cb{"B"};
  auto ta = std::chrono::steady_clock::now();
  auto* da = load(kit, a, &ca);
  printf("  abrir A sozinho: %lld ms\n", static_cast<long long>(std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now() - ta).count()));
  pause(1500);
  step("A aberto");
  paintAll(da);
  pause(500);
  step("A pintado inteiro");
  long darkA = darkPixels(da, setView);
  printf("  vistas de A: %d (id %d)\n", da->pClass->getViewsCount(da), da->pClass->getView(da));

  auto tb = std::chrono::steady_clock::now();
  auto* db = load(kit, b, &cb);
  printf("  abrir B com A aberto: %lld ms\n", static_cast<long long>(std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now() - tb).count()));
  if (!db) return 1;
  pause(1500);
  step("B aberto (A continua)");
  paintAll(db);
  pause(500);
  step("B pintado inteiro");
  printf("  vistas de B: %d (id %d)\n", db->pClass->getViewsCount(db), db->pClass->getView(db));

  // Digitar em A com B aberto por último: vai para A?
  ca.events = 0;
  cb.events = 0;
  typeAtStart(da, "MARCAA1 ", setView);
  printf("  digitar em A: callbacks A=%d B=%d\n", ca.events.load(), cb.events.load());
  ca.events = 0;
  cb.events = 0;
  typeAtStart(db, "MARCAB1 ", setView);
  printf("  digitar em B: callbacks A=%d B=%d\n", ca.events.load(), cb.events.load());
  typeAtStart(da, "MARCAA2 ", setView);
  printf("  ladrilho de A: %ld pixels escuros (antes de B: %ld)\n", darkPixels(da, setView), darkA);
  step("depois de digitar nos dois");
  check(da, dir, "a1", setView);
  check(db, dir, "b1", setView);

  db->pClass->destroy(db);
  pause(800);
  step("B fechado");
  typeAtStart(da, "MARCAA3 ", setView);
  check(da, dir, "a2", setView);

  // A troca de aba das abas leves: fechar e reabrir, 6 vezes.
  da->pClass->destroy(da);
  pause(800);
  step("A fechado (nenhum aberto)");
  for (int i = 1; i <= 6; i++) {
    auto t0 = std::chrono::steady_clock::now();
    auto* d = load(kit, i % 2 ? a : b, &ca);
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now() - t0).count();
    paintAll(d);
    pause(500);
    char label[64];
    snprintf(label, sizeof label, "troca %d: abriu %s em %lld ms", i, i % 2 ? "A" : "B", static_cast<long long>(ms));
    step(label);
    d->pClass->destroy(d);
    pause(500);
  }
  step("depois das 6 trocas, nenhum aberto");

  // As abas completas: 6 capítulos abertos e pintados ao mesmo tempo.
  LibreOfficeKitDocument* many[6];
  for (int i = 0; i < 6; i++) {
    std::string p = dir + "/c" + std::to_string(i) + ".docx";
    fs::copy_file(argv[2], p, fs::copy_options::overwrite_existing);
    many[i] = load(kit, p, &cb);
    paintAll(many[i]);
    pause(500);
    char label[64];
    snprintf(label, sizeof label, "%d capítulos abertos ao mesmo tempo", i + 1);
    step(label);
  }
  for (auto* d : many) d->pClass->destroy(d);
  pause(800);
  step("os 6 fechados");
  fflush(stdout);
  _exit(0);  // os destrutores estáticos do LO derrubam o processo (D-027)
}
