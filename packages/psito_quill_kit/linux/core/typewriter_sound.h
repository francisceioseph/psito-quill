// Os sons da máquina de escrever (D-095): a tecla, o espaço, o retrocesso,
// o retorno do carro e o sino perto da margem.
//
// As teclas, o espaço e o retorno são gravações de uma Smith Corona Corsair
// (CC0, do Freesound; os créditos em assets/sons/LEIA-ME.md), lidas da pasta
// dos sons quando o som é ligado. O sino é sintetizado aqui. O tocador roda
// numa thread própria ("pqk-som"): mistura
// as vozes em pedaços de 5 ms e escreve no PulseAudio (o PipeWire também
// fala com ele). A biblioteca do PulseAudio é aberta por dlopen só quando o
// primeiro som toca; sem ela, ou sem servidor, o som fica mudo, em silêncio.
// A saída fecha depois de 10 s sem som, e a memória dos sons sai ao desligar.
#pragma once

#include <atomic>
#include <condition_variable>
#include <cstdint>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <thread>
#include <vector>

namespace pqk::sound {

constexpr int kRate = 44100;

enum class Kind : int32_t { key = 0, space = 1, backspace = 2, carriageReturn = 3, bell = 4 };

// Um WAV em PCM de 16 bits, mono, 44,1 kHz (o formato dos sons do Quill);
// nullopt se o arquivo falta ou é outro formato.
std::optional<std::vector<int16_t>> readWav(const std::string& path);

// O sino sintetizado: as parciais de um sino pequeno.
std::vector<int16_t> bellSound();

// Os sons prontos, em PCM de 16 bits, mono, 44,1 kHz.
struct Bank {
  // As teclas e os espaços, em rodízio: a mesma batida repetida soa como
  // uma máquina de verdade não soa.
  std::vector<std::vector<int16_t>> keys, spaces;
  std::vector<int16_t> carriageReturn, bell;

  // Lê os sons da pasta [dir] (tecla-0.wav…, espaco-0.wav…, retorno.wav) e
  // sintetiza o sino. O que faltar fica mudo.
  static Bank load(const std::string& dir);
  // O som de [kind] na vez [variant]; nullptr se ele não existe. O
  // retrocesso é a batida mais grave do espaço.
  const std::vector<int16_t>* of(Kind kind, int variant) const;
  // O ganho de cada som (o retrocesso é mais baixo).
  static float gainOf(Kind kind);
  size_t bytes() const;
};

// As vozes que tocam ao mesmo tempo, somadas com saturação.
class Mixer {
 public:
  // Começa a tocar [samples] (que precisa viver até o fim da voz) com o
  // ganho [gain] (0 a 1). Com vozes demais, a mais velha sai.
  void start(const std::vector<int16_t>* samples, float gain);
  // Mistura os próximos [n] quadros em [out]. Devolve false se não há voz.
  bool mix(int16_t* out, size_t n);
  bool idle() const { return voices_.empty(); }
  void clear() { voices_.clear(); }

  static constexpr size_t kMaxVoices = 8;

 private:
  struct Voice {
    const std::vector<int16_t>* samples;
    size_t pos;
    float gain;
  };
  std::vector<Voice> voices_;
};

// Para onde o som vai: o PulseAudio, ou um falso nos testes.
class Sink {
 public:
  virtual ~Sink() = default;
  // Abre a saída; false se não deu (sem biblioteca, sem servidor).
  virtual bool open() = 0;
  // Escreve [n] quadros e espera o lugar no buffer (é o que dá o ritmo).
  virtual bool write(const int16_t* frames, size_t n) = 0;
  virtual void close() = 0;
};

std::unique_ptr<Sink> pulseSink();

class Player {
 public:
  // [dir] é a pasta dos sons gravados.
  Player(std::unique_ptr<Sink> sink, std::string dir, int idleCloseMs = 10000);
  ~Player();

  // Liga ou desliga, e o volume (0 a 1). Ligar lê os sons; desligar solta a
  // memória deles e fecha a saída.
  void setEnabled(bool on, double volume);
  void play(Kind kind);

  bool enabled() const { return enabled_.load(); }
  // Para os testes: quantos sons a thread já começou a tocar.
  int started() const { return started_.load(); }

 private:
  void run();

  std::unique_ptr<Sink> sink_;
  const std::string dir_;
  const int idleCloseMs_;
  std::mutex mu_;
  std::condition_variable cv_;
  std::vector<Kind> pending_;
  std::unique_ptr<Bank> bank_;
  float volume_ = 0.6f;
  bool stop_ = false;
  std::atomic<bool> enabled_{false};
  std::atomic<int> started_{0};
  int variant_ = 0;
  std::thread thread_;
};

}  // namespace pqk::sound
