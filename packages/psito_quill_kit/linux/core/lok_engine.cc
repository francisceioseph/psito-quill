#include "lok_engine.h"

#define LOK_USE_UNSTABLE_API
#include <LibreOfficeKit/LibreOfficeKit.h>
#include <LibreOfficeKit/LibreOfficeKitEnums.h>
#include <LibreOfficeKit/LibreOfficeKitInit.h>

#include <unistd.h>

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>

namespace pqk {

namespace {

std::string toFileUrl(const std::string& path) {
  if (path.rfind("file://", 0) == 0 || path.rfind("private:", 0) == 0) return path;
  std::string out = "file://";
  static const char* hex = "0123456789ABCDEF";
  for (unsigned char c : path) {
    if (isalnum(c) || strchr("/-_.~", c)) {
      out += static_cast<char>(c);
    } else {
      out += '%';
      out += hex[c >> 4];
      out += hex[c & 15];
    }
  }
  return out;
}

std::string takeLokString(_LibreOfficeKit* kit, char* s) {
  if (!s) return {};
  std::string out(s);
  if (kit && kit->pClass->freeError) kit->pClass->freeError(s);
  else free(s);
  return out;
}

// Payload do LOK_CALLBACK_INVALIDATE_TILES: "x, y, w, h[, parte[, modo]]" ou
// "EMPTY[, parte[, modo]]". Devolve false para "tudo".
bool parseRect(const std::string& payload, TwipRect* r) {
  if (payload.rfind("EMPTY", 0) == 0) return false;
  long long x, y, w, h;
  if (sscanf(payload.c_str(), "%lld, %lld, %lld, %lld", &x, &y, &w, &h) != 4)
    return false;
  *r = {x, y, w, h};
  return true;
}

}  // namespace

int64_t residentBytes() {
  long pages = 0, resident = 0;
  FILE* f = fopen("/proc/self/statm", "r");
  if (!f) return -1;
  if (fscanf(f, "%ld %ld", &pages, &resident) != 2) resident = -1;
  fclose(f);
  return resident < 0 ? -1 : static_cast<int64_t>(resident) * sysconf(_SC_PAGESIZE);
}

LokEngine::LokEngine(EngineSink* sink, int tileSlots)
    : sink_(sink),
      cache_(tileSlots),
      queue_("pqk-kit"),
      announced_(tileSlots, false),
      announcedKey_(tileSlots),
      scratch_(std::make_unique<uint8_t[]>(kTileBytes)) {}

LokEngine::~LokEngine() { shutdown(); }

// As línguas da ortografia: as do Quill e as vizinhas. O dicionário de cada
// uma vem do sistema (hunspell-pt-br, hunspell-en-us...).
const char* const kSpellLanguages = "pt_BR pt_PT en_US en_GB es_ES fr_FR de_DE it_IT";

void LokEngine::init(const std::string& installPath, const std::string& profileUrl) {
  queue_.post([this, installPath, profileUrl] {
    if (kit_) return;
    // Sem esta lista, o LOK desliga a ortografia ("No language allowlisted").
    // Quem rodar com a variável já definida escolhe as línguas.
    setenv("LOK_ALLOWLIST_LANGUAGES", kSpellLanguages, 0);
    // Os avisos do LibreOffice não vão para o terminal (privacidade, D-041).
    // Quem depura define o SAL_LOG antes, e ele vale.
    setenv("SAL_LOG", "-WARN-INFO", 0);
    kit_ = lok_init_2(installPath.c_str(),
                      profileUrl.empty() ? nullptr : profileUrl.c_str());
    if (!kit_) {
      sink_->onEvent(kEvInitFailed, "lok_init_2 falhou em " + installPath);
      return;
    }
    // O app desenha comentários, cursor e seleção; o motor só o papel.
    kit_->pClass->setOptionalFeatures(
        kit_, LOK_FEATURE_DOCUMENT_PASSWORD | LOK_FEATURE_NO_TILED_ANNOTATIONS |
                  LOK_FEATURE_RANGE_HEADERS);
    std::string version = takeLokString(kit_, kit_->pClass->getVersionInfo(kit_));
    sink_->onEvent(kEvReady, version);
  });
}

void LokEngine::open(const std::string& path) {
  queue_.post([this, path] {
    if (!kit_) {
      sink_->onEvent(kEvOpenFailed, "motor não iniciado");
      return;
    }
    const std::string url = path.empty() ? "private:factory/swriter" : toFileUrl(path);
    auto* doc = kit_->pClass->documentLoadWithOptions(kit_, url.c_str(), "Language=pt-BR");
    if (!doc) {
      sink_->onEvent(kEvOpenFailed,
                     takeLokString(kit_, kit_->pClass->getError(kit_)));
      return;
    }
    auto d = std::make_unique<Doc>();
    d->engine = this;
    d->id = nextId_++;
    d->doc = doc;
    d->tileMode = LOK_TILEMODE_RGBA;
    // O novo vira o ativo. O callback entra antes de tudo (o getDocumentSize
    // monta as páginas e manda a contagem de palavras nessa hora; sem o
    // callback, ela se perde), mas o que chegar antes do OPENED fica guardado
    // e sai logo depois dele: o Dart descarta os eventos de documento até o
    // OPENED (D-054).
    makeActive(d.get());
    doc->pClass->initializeForRendering(doc, "{}");
    doc->pClass->registerCallback(doc, &LokEngine::lokCallback, d.get());
    d->tileMode = doc->pClass->getTileMode ? doc->pClass->getTileMode(doc) : LOK_TILEMODE_RGBA;
    tileMode_ = d->tileMode;
    sink_->onEvent(kEvOpened, sizeJson(*d));
    std::vector<std::pair<int, std::string>> early;
    {
      std::lock_guard<std::mutex> lock(d->mutex);
      d->announced = true;
      early.swap(d->early);
    }
    for (auto& [type, payload] : early) handleCallback(type, payload);
    docs_.push_back(std::move(d));
    scheduleRender();
  });
}

void LokEngine::makeActive(Doc* d) {
  activeId_ = d ? d->id : 0;
  doc_ = d ? d->doc : nullptr;
  tileMode_ = d ? d->tileMode : 0;
  cache_.clear();
  std::fill(announced_.begin(), announced_.end(), false);
  // A área visível é a do Dart, que manda a do documento novo logo depois.
  viewport_ = {};
}

std::string LokEngine::sizeJson(const Doc& d) {
  long w = 0, h = 0;
  d.doc->pClass->getDocumentSize(d.doc, &w, &h);
  char buf[192];
  snprintf(buf, sizeof buf, "{\"id\":%d,\"width\":%ld,\"height\":%ld,\"parts\":%d}", d.id, w, h,
           d.doc->pClass->getParts(d.doc));
  return buf;
}

void LokEngine::activate(int id) {
  queue_.post([this, id] {
    for (auto& d : docs_) {
      if (d->id != id) continue;
      makeActive(d.get());
      sink_->onEvent(kEvActivated, sizeJson(*d));
      return;
    }
  });
}

void LokEngine::destroyDoc(int id) {
  for (auto it = docs_.begin(); it != docs_.end(); ++it) {
    if ((*it)->id != id) continue;
    if (activeId_ == id) makeActive(nullptr);
    (*it)->doc->pClass->destroy((*it)->doc);
    docs_.erase(it);
    sink_->onEvent(kEvClosed, std::to_string(id));
    return;
  }
}

void LokEngine::close() {
  queue_.post([this] {
    if (activeId_ == 0) {
      sink_->onEvent(kEvClosed, "0");
      return;
    }
    destroyDoc(activeId_);
  });
}

void LokEngine::closeDocument(int id) {
  queue_.post([this, id] { destroyDoc(id); });
}

void LokEngine::setViewport(int32_t scaleMilli, const TwipRect& visible) {
  queue_.post([this, scaleMilli, visible] {
    scaleMilli_ = scaleMilli;
    viewport_ = visible;
    if (doc_ && doc_->pClass->setClientVisibleArea)
      doc_->pClass->setClientVisibleArea(doc_, visible.x, visible.y, visible.w,
                                         visible.h);
    scheduleRender();
  });
}

void LokEngine::postKey(int type, int charCode, int keyCode) {
  if (type == LOK_KEYEVENT_KEYINPUT) {
    std::lock_guard<std::mutex> lock(latencyMutex_);
    if (!keyPending_) {  // mede a partir da primeira tecla ainda sem ladrilho
      keyPending_ = true;
      keyInvalidated_ = false;
      keyTime_ = Clock::now();
    }
  }
  queue_.post([this, type, charCode, keyCode] {
    if (doc_) doc_->pClass->postKeyEvent(doc_, type, charCode, keyCode);
  });
}

void LokEngine::postMouse(int type, int x, int y, int count, int buttons, int modifier) {
  queue_.post([=, this] {
    if (doc_) doc_->pClass->postMouseEvent(doc_, type, x, y, count, buttons, modifier);
  });
}

void LokEngine::setGraphicSelection(int type, int x, int y) {
  queue_.post([=, this] {
    if (doc_) doc_->pClass->setGraphicSelection(doc_, type, x, y);
  });
}

void LokEngine::uno(const std::string& command, const std::string& argsJson) {
  queue_.post([this, command, argsJson] {
    if (doc_)
      doc_->pClass->postUnoCommand(doc_, command.c_str(),
                                   argsJson.empty() ? nullptr : argsJson.c_str(),
                                   true);
  });
}

void LokEngine::saveAs(const std::string& path, const std::string& format,
                       const std::string& options) {
  queue_.post([this, path, format, options] {
    if (!doc_) {
      sink_->onEvent(kEvSaveFailed, "nenhum documento aberto");
      return;
    }
    const std::string url = toFileUrl(path);
    int ok = doc_->pClass->saveAs(doc_, url.c_str(),
                                  format.empty() ? nullptr : format.c_str(),
                                  options.empty() ? nullptr : options.c_str());
    if (ok)
      sink_->onEvent(kEvSaved, path);
    else
      sink_->onEvent(kEvSaveFailed, takeLokString(kit_, kit_->pClass->getError(kit_)));
  });
}

void LokEngine::commandValues(const std::string& command) {
  queue_.post([this, command] {
    if (!doc_) return;
    char* v = doc_->pClass->getCommandValues(doc_, command.c_str());
    std::string json = v ? v : "";
    free(v);
    sink_->onEvent(kEvCommandValues, command + "\n" + json);
  });
}

void LokEngine::extTextInput(int type, const std::string& text) {
  if (type == LOK_EXT_TEXTINPUT_END) {  // mede como uma tecla
    std::lock_guard<std::mutex> lock(latencyMutex_);
    if (!keyPending_) {
      keyPending_ = true;
      keyInvalidated_ = false;
      keyTime_ = Clock::now();
    }
  }
  queue_.post([this, type, text] {
    if (doc_ && doc_->pClass->postWindowExtTextInputEvent)
      doc_->pClass->postWindowExtTextInputEvent(doc_, 0, type, text.c_str());
  });
}

void LokEngine::textSelection(const std::string& mime) {
  queue_.post([this, mime] {
    if (!doc_) return;
    char* used = nullptr;
    char* text = doc_->pClass->getTextSelection(doc_, mime.c_str(), &used);
    std::string usedMime = used ? used : mime;
    std::string out = text ? text : "";
    free(used);
    free(text);
    sink_->onEvent(kEvTextSelection, usedMime + "\n" + out);
  });
}

void LokEngine::paste(const std::string& mime, const std::string& data) {
  queue_.post([this, mime, data] {
    if (doc_) doc_->pClass->paste(doc_, mime.c_str(), data.data(), data.size());
  });
}

void LokEngine::trimMemory(int target) {
  queue_.post([this, target] {
    if (kit_ && kit_->pClass->trimMemory) kit_->pClass->trimMemory(kit_, target);
  });
}

void LokEngine::repaintAll() {
  queue_.post([this] {
    cache_.invalidateAll();
    scheduleRender();
  });
}

void LokEngine::shutdown() {
  queue_.post([this] {
    makeActive(nullptr);
    for (auto& d : docs_) d->doc->pClass->destroy(d->doc);
    docs_.clear();
    // kit_->destroy encerra o LibreOffice; depois dele o processo não pode
    // iniciar outro LOK. Fica para o fim do processo.
    if (kit_) kit_->pClass->destroy(kit_);
    kit_ = nullptr;
  });
  queue_.stop();
}

void LokEngine::drain() {
  std::mutex m;
  std::condition_variable cv;
  bool done = false;
  queue_.post([&] {
    std::lock_guard<std::mutex> lock(m);
    done = true;
    cv.notify_one();
  });
  std::unique_lock<std::mutex> lock(m);
  cv.wait(lock, [&] { return done; });
}

LatencyStats LokEngine::latency() const {
  std::lock_guard<std::mutex> lock(latencyMutex_);
  LatencyStats s;
  if (samples_.empty()) return s;
  std::vector<double> v = samples_;
  std::sort(v.begin(), v.end());
  auto pct = [&](double p) {
    size_t i = static_cast<size_t>(std::ceil(p * v.size())) - 1;
    return v[std::min(i, v.size() - 1)];
  };
  s.count = v.size();
  s.p50 = pct(0.50);
  s.p95 = pct(0.95);
  s.max = v.back();
  return s;
}

void LokEngine::resetLatency() {
  std::lock_guard<std::mutex> lock(latencyMutex_);
  samples_.clear();
  keyPending_ = false;
}

// Chamado pelo LibreOffice, numa thread dele. Não pode bloquear nem tocar no
// LOK: só repassa e põe trabalho na fila.
// Os de um documento que não é o ativo são descartados (D-054): ele não
// recebe entrada, e as vagas de ladrilho são do ativo.
void LokEngine::lokCallback(int type, const char* payload, void* data) {
  auto* d = static_cast<Doc*>(data);
  if (d->engine->activeId_ != d->id) return;
  {
    std::lock_guard<std::mutex> lock(d->mutex);
    if (!d->announced) {
      d->early.emplace_back(type, payload ? payload : "");
      return;
    }
  }
  d->engine->handleCallback(type, payload ? payload : "");
}

void LokEngine::handleCallback(int type, const std::string& payload) {
  if (type == LOK_CALLBACK_INVALIDATE_TILES) {
    {
      std::lock_guard<std::mutex> lock(latencyMutex_);
      if (keyPending_) keyInvalidated_ = true;
    }
    queue_.post([this, payload] {
      TwipRect r;
      if (parseRect(payload, &r))
        cache_.invalidate(r);
      else
        cache_.invalidateAll();
      scheduleRender();
    });
    return;  // a UI não precisa deste: os pixels chegam pelas texturas
  }
  if (type == LOK_CALLBACK_DOCUMENT_SIZE_CHANGED) {
    queue_.post([this] { scheduleRender(); });
  }
  sink_->onEvent(type, payload);
}

void LokEngine::scheduleRender() {
  if (renderScheduled_.exchange(true)) return;
  queue_.post([this] { renderPass(); });
}

// Desenha alguns ladrilhos sujos dos visíveis e se repõe no fim da fila, para
// as teclas que chegarem no meio passarem na frente do resto da tela.
void LokEngine::renderPass() {
  renderScheduled_ = false;
  if (!doc_ || viewport_.w <= 0 || viewport_.h <= 0) return;

  // Visíveis e uma fileira de margem acima e abaixo.
  const int64_t margin = static_cast<int64_t>(tileTwips(scaleMilli_));
  TwipRect wanted{viewport_.x, std::max<int64_t>(0, viewport_.y - margin), viewport_.w,
                  viewport_.h + 2 * margin};
  std::vector<TileKey> keys = tilesCovering(wanted, scaleMilli_);
  // Primeiro os de dentro da tela, do centro para fora.
  const double t = tileTwips(scaleMilli_);
  const double cy = viewport_.y + viewport_.h / 2.0;
  auto inView = [&](const TileKey& k) { return tileRect(k).intersects(viewport_); };
  std::stable_sort(keys.begin(), keys.end(), [&](const TileKey& a, const TileKey& b) {
    bool va = inView(a), vb = inView(b);
    if (va != vb) return va;
    return std::abs((a.row + 0.5) * t - cy) < std::abs((b.row + 0.5) * t - cy);
  });

  std::vector<int> pinned;
  pinned.reserve(keys.size());
  for (const TileKey& k : keys) {
    int s = cache_.find(k);
    if (s >= 0) pinned.push_back(s);
  }

  constexpr int kBudget = 4;
  int painted = 0;
  bool remaining = false;
  for (const TileKey& k : keys) {
    int s = cache_.acquire(k, pinned);
    if (s < 0) break;  // mais visíveis que vagas: o resto fica sem ladrilho
    if (std::find(pinned.begin(), pinned.end(), s) == pinned.end()) pinned.push_back(s);
    if (cache_.slot(s).key == k && !cache_.slot(s).dirty && announced_[s]) continue;
    if (painted >= kBudget) {
      remaining = true;
      break;
    }
    paintSlot(s);
    ++painted;
  }

  if (remaining) {
    scheduleRender();
    return;
  }
  // Tela em dia: se uma tecla esperava por isso, mede.
  std::lock_guard<std::mutex> lock(latencyMutex_);
  if (keyPending_ && keyInvalidated_) {
    double ms = std::chrono::duration<double, std::milli>(Clock::now() - keyTime_).count();
    if (samples_.size() < 100000) samples_.push_back(ms);
    keyPending_ = false;
    keyInvalidated_ = false;
  }
}

void LokEngine::paintSlot(int index) {
  TileSlot& slot = cache_.slot(index);
  const TileKey key = slot.key;
  const TwipRect r = tileRect(key);
  // O LOK não pinta fora das páginas (acima da primeira, por exemplo): sem
  // limpar, sobram restos do ladrilho anterior. Transparente deixa aparecer o
  // fundo do tema por trás.
  memset(scratch_.get(), 0, kTileBytes);
  doc_->pClass->paintTile(doc_, scratch_.get(), kTileSize, kTileSize, r.x, r.y, r.w, r.h);
  {
    // O Flutter quer RGBA. O LOK no Linux costuma dar BGRA (cairo).
    std::lock_guard<std::mutex> lock(slot.mutex);
    uint8_t* dst = slot.pixels.get();
    const uint8_t* src = scratch_.get();
    if (tileMode_ == LOK_TILEMODE_BGRA) {
      for (int i = 0; i < kTileBytes; i += 4) {
        dst[i] = src[i + 2];
        dst[i + 1] = src[i + 1];
        dst[i + 2] = src[i];
        dst[i + 3] = src[i + 3];
      }
    } else {
      memcpy(dst, src, kTileBytes);
    }
    slot.dirty = false;
  }
  sink_->onTileUpdated(index);
  // A UI só precisa saber quando a vaga passa a mostrar outro ladrilho. Um
  // redesenho no lugar (digitação) não gera evento: a textura basta.
  if (!announced_[index] || !(announcedKey_[index] == key)) {
    char buf[64];
    snprintf(buf, sizeof buf, "%d,%d,%d,%d", index, key.col, key.row, key.scaleMilli);
    sink_->onEvent(kEvTile, buf);
    announced_[index] = true;
    announcedKey_[index] = key;
  }
}

}  // namespace pqk
