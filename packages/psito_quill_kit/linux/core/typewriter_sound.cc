#include "core/typewriter_sound.h"

#include <dlfcn.h>
#include <pthread.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstring>

namespace pqk::sound {

namespace {

constexpr double kPi = 3.14159265358979323846;

// Um gerador simples e determinístico: o sino sai igual a cada vez (e nos
// testes).
struct Rng {
  uint32_t s;
  float next() {  // de −1 a 1
    s ^= s << 13;
    s ^= s >> 17;
    s ^= s << 5;
    return static_cast<float>(s) / 2147483648.0f - 1.0f;
  }
};

size_t frames(double seconds) { return static_cast<size_t>(seconds * kRate); }

uint32_t le32(const unsigned char* p) { return p[0] | p[1] << 8 | p[2] << 16 | static_cast<uint32_t>(p[3]) << 24; }
uint16_t le16(const unsigned char* p) { return static_cast<uint16_t>(p[0] | p[1] << 8); }

}  // namespace

std::optional<std::vector<int16_t>> readWav(const std::string& path) {
  FILE* f = std::fopen(path.c_str(), "rb");
  if (!f) return std::nullopt;
  std::vector<unsigned char> data;
  unsigned char buf[16384];
  for (size_t n; (n = std::fread(buf, 1, sizeof buf, f)) > 0;) {
    data.insert(data.end(), buf, buf + n);
    if (data.size() > 4u << 20) break;  // nenhum som do Quill passa de 4 MB
  }
  std::fclose(f);
  if (data.size() < 12 || std::memcmp(data.data(), "RIFF", 4) != 0 || std::memcmp(data.data() + 8, "WAVE", 4) != 0)
    return std::nullopt;
  bool format = false;
  for (size_t at = 12; at + 8 <= data.size();) {
    const uint32_t size = le32(&data[at + 4]);
    const size_t body = at + 8;
    if (body + size > data.size()) return std::nullopt;
    if (std::memcmp(&data[at], "fmt ", 4) == 0 && size >= 16) {
      // PCM (1), mono, 44,1 kHz, 16 bits.
      format = le16(&data[body]) == 1 && le16(&data[body + 2]) == 1 && le32(&data[body + 4]) == kRate &&
               le16(&data[body + 14]) == 16;
      if (!format) return std::nullopt;
    } else if (std::memcmp(&data[at], "data", 4) == 0) {
      if (!format) return std::nullopt;
      std::vector<int16_t> out(size / 2);
      for (size_t i = 0; i < out.size(); i++) out[i] = static_cast<int16_t>(le16(&data[body + 2 * i]));
      return out;
    }
    at = body + size + (size & 1);
  }
  return std::nullopt;
}

// O sino: as parciais de um sino pequeno (1, 2,76, 5,40), que somem em
// tempos diferentes, e a batida do martelinho.
std::vector<int16_t> bellSound() {
  Rng rng{0xBE11u};
  std::vector<double> buf(frames(1.4), 0);
  const double f0 = 2100, partial[3] = {1, 2.76, 5.40}, amp[3] = {1, 0.45, 0.2}, tau[3] = {0.9, 0.35, 0.15};
  double max = 1e-9;
  for (size_t i = 0; i < buf.size(); i++) {
    const double t = static_cast<double>(i) / kRate;
    const double attack = std::min(1.0, t / 0.002);
    double v = 0;
    for (int p = 0; p < 3; p++) v += amp[p] * std::sin(2 * kPi * f0 * partial[p] * t) * std::exp(-t / tau[p]);
    buf[i] = attack * v + 0.3 * rng.next() * std::exp(-t / 0.0015);
    max = std::max(max, std::abs(buf[i]));
  }
  // O pico em 55 %, e um desvanecer de 3 ms no fim, para não estalar.
  const double scale = 0.55 * 32767.0 / max;
  const size_t fade = frames(0.003);
  std::vector<int16_t> out(buf.size());
  for (size_t i = 0; i < buf.size(); i++) {
    double v = buf[i] * scale;
    if (i + fade >= buf.size()) v *= static_cast<double>(buf.size() - 1 - i) / fade;
    out[i] = static_cast<int16_t>(std::clamp(v, -32767.0, 32767.0));
  }
  return out;
}

Bank Bank::load(const std::string& dir) {
  Bank b;
  for (int i = 0;; i++) {
    auto k = readWav(dir + "/tecla-" + std::to_string(i) + ".wav");
    if (!k) break;
    b.keys.push_back(std::move(*k));
  }
  for (int i = 0;; i++) {
    auto k = readWav(dir + "/espaco-" + std::to_string(i) + ".wav");
    if (!k) break;
    b.spaces.push_back(std::move(*k));
  }
  if (auto r = readWav(dir + "/retorno.wav")) b.carriageReturn = std::move(*r);
  b.bell = bellSound();
  return b;
}

const std::vector<int16_t>* Bank::of(Kind kind, int variant) const {
  const auto pick = [variant](const std::vector<std::vector<int16_t>>& v) -> const std::vector<int16_t>* {
    if (v.empty()) return nullptr;
    const int n = static_cast<int>(v.size());
    return &v[((variant % n) + n) % n];
  };
  switch (kind) {
    case Kind::key:
      return pick(keys);
    case Kind::space:
      return pick(spaces);
    case Kind::backspace:
      return spaces.empty() ? nullptr : &spaces.back();
    case Kind::carriageReturn:
      return carriageReturn.empty() ? nullptr : &carriageReturn;
    case Kind::bell:
      return &bell;
  }
  return nullptr;
}

float Bank::gainOf(Kind kind) {
  switch (kind) {
    case Kind::backspace:
      return 0.6f;
    case Kind::bell:
      return 0.8f;
    default:
      return 1.0f;
  }
}

size_t Bank::bytes() const {
  size_t n = carriageReturn.size() + bell.size();
  for (const auto& k : keys) n += k.size();
  for (const auto& k : spaces) n += k.size();
  return n * sizeof(int16_t);
}

void Mixer::start(const std::vector<int16_t>* samples, float gain) {
  if (!samples || samples->empty()) return;
  if (voices_.size() >= kMaxVoices) voices_.erase(voices_.begin());
  voices_.push_back({samples, 0, gain});
}

bool Mixer::mix(int16_t* out, size_t n) {
  if (voices_.empty()) return false;
  for (size_t i = 0; i < n; i++) {
    float v = 0;
    for (auto& voice : voices_) {
      if (voice.pos < voice.samples->size()) v += (*voice.samples)[voice.pos++] * voice.gain;
    }
    out[i] = static_cast<int16_t>(std::clamp(v, -32767.0f, 32767.0f));
  }
  std::erase_if(voices_, [](const Voice& v) { return v.pos >= v.samples->size(); });
  return true;
}

namespace {

// O PulseAudio pelo dlopen: as poucas declarações da API simples (estáveis
// desde o 0.9), sem os cabeçalhos de desenvolvimento.
struct PaSampleSpec {
  int format;
  uint32_t rate;
  uint8_t channels;
};
struct PaBufferAttr {
  uint32_t maxlength, tlength, prebuf, minreq, fragsize;
};
using PaNew = void* (*)(const char*, const char*, int, const char*, const char*, const PaSampleSpec*, const void*,
                        const PaBufferAttr*, int*);
using PaWrite = int (*)(void*, const void*, size_t, int*);
using PaFree = void (*)(void*);
constexpr int kPaSampleS16LE = 3;
constexpr int kPaStreamPlayback = 1;

class PulseSink : public Sink {
 public:
  ~PulseSink() override { close(); }

  bool open() override {
    if (stream_) return true;
    if (!lib_) {
      lib_ = dlopen("libpulse-simple.so.0", RTLD_NOW | RTLD_LOCAL);
      if (!lib_) return false;
      new_ = reinterpret_cast<PaNew>(dlsym(lib_, "pa_simple_new"));
      write_ = reinterpret_cast<PaWrite>(dlsym(lib_, "pa_simple_write"));
      free_ = reinterpret_cast<PaFree>(dlsym(lib_, "pa_simple_free"));
      if (!new_ || !write_ || !free_) return false;
    }
    if (!new_) return false;
    const PaSampleSpec spec{kPaSampleS16LE, kRate, 1};
    // 20 ms no buffer, e toca a partir de 5 ms: a tecla soa logo.
    const PaBufferAttr attr{UINT32_MAX, static_cast<uint32_t>(kRate * 2 * 20 / 1000),
                            static_cast<uint32_t>(kRate * 2 * 5 / 1000), UINT32_MAX, UINT32_MAX};
    int error = 0;
    stream_ = new_(nullptr, "Psito Quill", kPaStreamPlayback, nullptr, "Máquina de escrever", &spec, nullptr, &attr,
                   &error);
    return stream_ != nullptr;
  }

  bool write(const int16_t* frames, size_t n) override {
    if (!stream_) return false;
    int error = 0;
    return write_(stream_, frames, n * sizeof(int16_t), &error) == 0;
  }

  void close() override {
    if (stream_) free_(stream_);
    stream_ = nullptr;
  }

 private:
  void* lib_ = nullptr;
  void* stream_ = nullptr;
  PaNew new_ = nullptr;
  PaWrite write_ = nullptr;
  PaFree free_ = nullptr;
};

}  // namespace

std::unique_ptr<Sink> pulseSink() { return std::make_unique<PulseSink>(); }

Player::Player(std::unique_ptr<Sink> sink, std::string dir, int idleCloseMs)
    : sink_(std::move(sink)), dir_(std::move(dir)), idleCloseMs_(idleCloseMs) {}

Player::~Player() {
  {
    std::lock_guard lock(mu_);
    stop_ = true;
  }
  cv_.notify_all();
  if (thread_.joinable()) thread_.join();
}

void Player::setEnabled(bool on, double volume) {
  {
    std::lock_guard lock(mu_);
    volume_ = static_cast<float>(std::clamp(volume, 0.0, 1.0));
    enabled_ = on;
    if (!on) pending_.clear();
    // A thread nasce no primeiro ligar, e fica (dorme sem custo).
    if (on && !thread_.joinable()) thread_ = std::thread([this] { run(); });
  }
  cv_.notify_all();
}

void Player::play(Kind kind) {
  {
    std::lock_guard lock(mu_);
    if (!enabled_ || !thread_.joinable()) return;
    // Teclas rápidas demais não enchem a fila: o misturador já tem teto.
    if (pending_.size() < Mixer::kMaxVoices) pending_.push_back(kind);
  }
  cv_.notify_all();
}

void Player::run() {
  pthread_setname_np(pthread_self(), "pqk-som");
  using Clock = std::chrono::steady_clock;
  constexpr size_t kChunk = kRate * 5 / 1000;  // 5 ms
  int16_t buffer[kChunk];
  Mixer mixer;
  bool open = false;
  Clock::time_point lastFailure{};

  for (;;) {
    std::vector<Kind> take;
    float volume;
    bool on;
    {
      std::unique_lock lock(mu_);
      if (mixer.idle()) {
        if (open) {
          // Com a saída aberta, espera um som; sem nenhum por um tempo, fecha.
          const bool woke = cv_.wait_for(lock, std::chrono::milliseconds(idleCloseMs_),
                                         [this] { return stop_ || !pending_.empty() || !enabled_; });
          if (!woke) {
            lock.unlock();
            sink_->close();
            open = false;
            continue;
          }
        } else {
          cv_.wait(lock, [this] { return stop_ || !pending_.empty() || (!enabled_ && bank_); });
        }
      }
      if (stop_) break;
      take.swap(pending_);
      volume = volume_;
      on = enabled_;
    }

    if (!on) {
      // Desligado: solta os sons e a saída.
      mixer.clear();
      if (open) sink_->close();
      open = false;
      bank_.reset();
      continue;
    }
    if (!bank_) bank_ = std::make_unique<Bank>(Bank::load(dir_));
    for (Kind k : take) {
      mixer.start(bank_->of(k, variant_++), volume * Bank::gainOf(k));
      started_++;
    }
    if (!open && !mixer.idle()) {
      // Sem servidor de som, não tenta a cada tecla: espera 5 s.
      const bool recent = lastFailure != Clock::time_point{} && Clock::now() - lastFailure < std::chrono::seconds(5);
      if (recent || !sink_->open()) {
        if (!recent) lastFailure = Clock::now();
        mixer.clear();
        continue;
      }
      open = true;
    }
    // Mistura um pedaço e escreve; a escrita espera o lugar no buffer, e é
    // o que dá o ritmo. Entre um pedaço e outro, as teclas novas entram.
    if (mixer.mix(buffer, kChunk) && !sink_->write(buffer, kChunk)) {
      sink_->close();
      open = false;
      mixer.clear();
      lastFailure = Clock::now();
    }
  }
  if (open) sink_->close();
}

}  // namespace pqk::sound
