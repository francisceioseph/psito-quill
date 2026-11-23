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

void LokEngine::init(const std::string& installPath, const std::string& profileUrl) {
  queue_.post([this, installPath, profileUrl] {
    if (kit_) return;
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
    if (doc_) {
      doc_->pClass->destroy(doc_);
      doc_ = nullptr;
    }
    cache_.clear();
    std::fill(announced_.begin(), announced_.end(), false);
    const std::string url = path.empty() ? "private:factory/swriter" : toFileUrl(path);
    doc_ = kit_->pClass->documentLoadWithOptions(kit_, url.c_str(), "Language=pt-BR");
    if (!doc_) {
      sink_->onEvent(kEvOpenFailed,
                     takeLokString(kit_, kit_->pClass->getError(kit_)));
      return;
    }
    doc_->pClass->initializeForRendering(doc_, "{}");
    doc_->pClass->registerCallback(doc_, &LokEngine::lokCallback, this);
    tileMode_ = doc_->pClass->getTileMode ? doc_->pClass->getTileMode(doc_)
                                          : LOK_TILEMODE_RGBA;
    long w = 0, h = 0;
    doc_->pClass->getDocumentSize(doc_, &w, &h);
    char buf[160];
    snprintf(buf, sizeof buf, "{\"width\":%ld,\"height\":%ld,\"parts\":%d}", w, h,
             doc_->pClass->getParts(doc_));
    sink_->onEvent(kEvOpened, buf);
    scheduleRender();
  });
}

void LokEngine::close() {
  queue_.post([this] {
    if (doc_) {
      doc_->pClass->destroy(doc_);
      doc_ = nullptr;
    }
    cache_.clear();
    std::fill(announced_.begin(), announced_.end(), false);
    sink_->onEvent(kEvClosed, "");
  });
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
    if (doc_) doc_->pClass->destroy(doc_);
    doc_ = nullptr;
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
void LokEngine::lokCallback(int type, const char* payload, void* data) {
  static_cast<LokEngine*>(data)->handleCallback(type, payload ? payload : "");
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
