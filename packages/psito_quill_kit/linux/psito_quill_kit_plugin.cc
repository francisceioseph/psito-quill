// Cola entre o núcleo (core/) e o Flutter Linux.
//
// - Guarda o FlTextureRegistrar do registro do plugin.
// - Cada vaga da TileCache vira uma FlPixelBufferTexture (TileTexture).
// - Implementa a API C (quill_kit_api.h) que o Dart chama por FFI.
//
// Não há method channel: tudo passa por FFI, e as respostas voltam pelo
// ponteiro de função que o Dart dá (um NativeCallable.listener).
#include "include/psito_quill_kit/psito_quill_kit_plugin.h"
#include "include/psito_quill_kit/quill_kit_api.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include <cstdlib>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

#include "core/lok_engine.h"
#include "core/lua_sandbox.h"
#include "core/task_queue.h"

// ---------------------------------------------------------------- textura --

G_DECLARE_FINAL_TYPE(PqkTileTexture, pqk_tile_texture, PQK, TILE_TEXTURE,
                     FlPixelBufferTexture)

struct _PqkTileTexture {
  FlPixelBufferTexture parent_instance;
  pqk::TileSlot* slot;
};

G_DEFINE_TYPE(PqkTileTexture, pqk_tile_texture, fl_pixel_buffer_texture_get_type())

// Roda na thread de raster. As texturas são populadas uma de cada vez nessa
// thread, e o upload para a GPU acontece logo depois desta chamada: um buffer
// de apoio só, compartilhado, basta. Copiar sob o mutex da vaga evita que o
// kit escreva no meio do upload.
static gboolean pqk_tile_texture_copy_pixels(FlPixelBufferTexture* texture,
                                             const uint8_t** out_buffer,
                                             uint32_t* width, uint32_t* height,
                                             GError** error) {
  static uint8_t staging[pqk::kTileBytes];
  pqk::TileSlot* slot = PQK_TILE_TEXTURE(texture)->slot;
  {
    std::lock_guard<std::mutex> lock(slot->mutex);
    memcpy(staging, slot->pixels.get(), pqk::kTileBytes);
  }
  *out_buffer = staging;
  *width = pqk::kTileSize;
  *height = pqk::kTileSize;
  return TRUE;
}

static void pqk_tile_texture_class_init(PqkTileTextureClass* klass) {
  FL_PIXEL_BUFFER_TEXTURE_CLASS(klass)->copy_pixels = pqk_tile_texture_copy_pixels;
}

static void pqk_tile_texture_init(PqkTileTexture* self) {}

// ------------------------------------------------------------------ estado --

namespace {

FlTextureRegistrar* g_registrar = nullptr;

class Kit : public pqk::EngineSink {
 public:
  Kit(int slots, pqk_event_fn fn) : fn_(fn), engine_(this, slots), lua_("pqk-lua") {
    for (int i = 0; i < slots; ++i) {
      auto* t = PQK_TILE_TEXTURE(g_object_new(pqk_tile_texture_get_type(), nullptr));
      t->slot = &engine_.tiles().slot(i);
      textures_.push_back(t);
      if (g_registrar) fl_texture_registrar_register_texture(g_registrar, FL_TEXTURE(t));
      ids_.push_back(g_registrar ? fl_texture_get_id(FL_TEXTURE(t)) : -1);
    }
  }

  ~Kit() override {
    lua_.stop();
    engine_.shutdown();
    for (auto* t : textures_) {
      if (g_registrar) fl_texture_registrar_unregister_texture(g_registrar, FL_TEXTURE(t));
      g_object_unref(t);
    }
  }

  void onEvent(int32_t type, const std::string& payload) override {
    if (fn_) fn_(type, strdup(payload.c_str()));
  }

  void onTileUpdated(int slot) override {
    if (g_registrar)
      fl_texture_registrar_mark_texture_frame_available(g_registrar,
                                                        FL_TEXTURE(textures_[slot]));
  }

  pqk::LokEngine& engine() { return engine_; }
  pqk::TaskQueue& lua() { return lua_; }
  int64_t textureId(int slot) const {
    return slot >= 0 && slot < static_cast<int>(ids_.size()) ? ids_[slot] : -1;
  }
  int slots() const { return static_cast<int>(ids_.size()); }

 private:
  pqk_event_fn fn_;
  pqk::LokEngine engine_;
  pqk::TaskQueue lua_;
  std::vector<PqkTileTexture*> textures_;
  std::vector<int64_t> ids_;
};

std::unique_ptr<Kit> g_kit;

std::string str(const char* s) { return s ? s : ""; }

std::string jsonEscape(const std::string& s) {
  std::string out;
  for (char c : s) {
    if (c == '"' || c == '\\') out += '\\';
    if (c == '\n') {
      out += "\\n";
      continue;
    }
    out += c;
  }
  return out;
}

}  // namespace

// ------------------------------------------------------------------ API C --

extern "C" {

int32_t pqk_init(const char* install_path, const char* profile_url, int32_t tile_slots,
                 pqk_event_fn on_event) {
  if (g_kit) return 1;
  g_kit = std::make_unique<Kit>(tile_slots, on_event);
  g_kit->engine().init(str(install_path), str(profile_url));
  return 0;
}

void pqk_shutdown(void) { g_kit.reset(); }

int64_t pqk_tile_texture_id(int32_t slot) { return g_kit ? g_kit->textureId(slot) : -1; }
int32_t pqk_tile_slots(void) { return g_kit ? g_kit->slots() : 0; }
int32_t pqk_tile_size(void) { return pqk::kTileSize; }

void pqk_open(const char* path) {
  if (g_kit) g_kit->engine().open(str(path));
}
void pqk_close(void) {
  if (g_kit) g_kit->engine().close();
}
void pqk_set_viewport(int32_t scale_milli, int64_t x, int64_t y, int64_t w, int64_t h) {
  if (g_kit) g_kit->engine().setViewport(scale_milli, {x, y, w, h});
}
void pqk_repaint_all(void) {
  if (g_kit) g_kit->engine().repaintAll();
}
void pqk_post_key(int32_t type, int32_t char_code, int32_t key_code) {
  if (g_kit) g_kit->engine().postKey(type, char_code, key_code);
}
void pqk_post_mouse(int32_t type, int32_t x, int32_t y, int32_t count, int32_t buttons,
                    int32_t modifier) {
  if (g_kit) g_kit->engine().postMouse(type, x, y, count, buttons, modifier);
}
void pqk_uno(const char* command, const char* args_json) {
  if (g_kit) g_kit->engine().uno(str(command), str(args_json));
}
void pqk_save_as(const char* path, const char* format, const char* options) {
  if (g_kit) g_kit->engine().saveAs(str(path), str(format), str(options));
}
void pqk_command_values(const char* command) {
  if (g_kit) g_kit->engine().commandValues(str(command));
}

void pqk_lua_run(const char* source, const char* chunk_name, int64_t memory_limit,
                 int64_t instruction_limit) {
  if (!g_kit) return;
  Kit* kit = g_kit.get();
  std::string src = str(source), name = str(chunk_name);
  kit->lua().post([kit, src, name, memory_limit, instruction_limit] {
    pqk::LuaSandbox sb(static_cast<size_t>(memory_limit),
                       static_cast<uint64_t>(instruction_limit),
                       [kit](const std::string& s) { kit->onEvent(PQK_EVENT_LUA_LOG, s); });
    pqk::LuaResult r = sb.run(src, name);
    kit->onEvent(PQK_EVENT_LUA_DONE,
                 r.ok ? "{\"ok\":true}"
                      : "{\"ok\":false,\"error\":\"" + jsonEscape(r.error) + "\"}");
  });
}

int64_t pqk_resident_bytes(void) { return pqk::residentBytes(); }

int32_t pqk_key_latency(int64_t* p50_us, int64_t* p95_us, int64_t* max_us) {
  if (!g_kit) return 0;
  pqk::LatencyStats s = g_kit->engine().latency();
  if (p50_us) *p50_us = static_cast<int64_t>(s.p50 * 1000);
  if (p95_us) *p95_us = static_cast<int64_t>(s.p95 * 1000);
  if (max_us) *max_us = static_cast<int64_t>(s.max * 1000);
  return static_cast<int32_t>(s.count);
}

void pqk_reset_key_latency(void) {
  if (g_kit) g_kit->engine().resetLatency();
}

double pqk_debug_tiles_luma(void) {
  if (!g_kit) return -1;
  pqk::TileCache& cache = g_kit->engine().tiles();
  double sum = 0;
  long n = 0;
  for (int i = 0; i < cache.slotCount(); ++i) {
    pqk::TileSlot& s = cache.slot(i);
    std::lock_guard<std::mutex> lock(s.mutex);
    if (!s.assigned || s.dirty) continue;
    const uint8_t* p = s.pixels.get();
    for (int j = 0; j < pqk::kTileBytes; j += 4) {
      if (p[j + 3] == 0) continue;  // fora da página (transparente)
      sum += 0.2126 * p[j] + 0.7152 * p[j + 1] + 0.0722 * p[j + 2];
      ++n;
    }
  }
  return n ? sum / n : -1;
}

void pqk_free_string(char* s) { free(s); }

}  // extern "C"

// --------------------------------------------------------------- registro --

void psito_quill_kit_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  g_registrar = fl_plugin_registrar_get_texture_registrar(registrar);
  g_object_ref(g_registrar);
}
