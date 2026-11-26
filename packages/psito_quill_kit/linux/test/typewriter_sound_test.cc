// Os sons da máquina de escrever (D-095): os sons gravados e o sino, o
// misturador e o tocador, com uma saída falsa no lugar do PulseAudio.
#include "core/typewriter_sound.h"

#include <gtest/gtest.h>

#include <algorithm>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <thread>

using namespace pqk::sound;

namespace {

int peak(const std::vector<int16_t>& s) {
  int m = 0;
  for (int16_t v : s) m = std::max(m, std::abs(static_cast<int>(v)));
  return m;
}

double ms(const std::vector<int16_t>& s) { return 1000.0 * s.size() / kRate; }

struct FakeSink : Sink {
  bool canOpen = true;
  std::atomic<int> opens{0}, closes{0}, writes{0};
  std::atomic<int> loudest{0};
  bool open() override {
    opens++;
    return canOpen;
  }
  bool write(const int16_t* f, size_t n) override {
    writes++;
    for (size_t i = 0; i < n; i++) loudest = std::max<int>(loudest, std::abs(static_cast<int>(f[i])));
    return true;
  }
  void close() override { closes++; }
};

template <typename F>
bool waitFor(F f, int timeoutMs = 2000) {
  const auto end = std::chrono::steady_clock::now() + std::chrono::milliseconds(timeoutMs);
  while (std::chrono::steady_clock::now() < end) {
    if (f()) return true;
    std::this_thread::sleep_for(std::chrono::milliseconds(2));
  }
  return f();
}

}  // namespace

TEST(Bank, LeOsSonsGravadosESintetizaOSino) {
  const Bank b = Bank::load(PQK_SOUNDS_DIR);
  ASSERT_EQ(b.keys.size(), 6u);
  ASSERT_EQ(b.spaces.size(), 2u);
  for (const auto& k : b.keys) {
    EXPECT_GT(ms(k), 150);
    EXPECT_LT(ms(k), 260);
    EXPECT_GT(peak(k), 32767 * 0.2);
  }
  EXPECT_GT(ms(b.carriageReturn), 1000);
  EXPECT_NEAR(ms(b.bell), 1400, 1);
  // O sino acaba em silêncio (o desvanecer), sem estalar.
  EXPECT_EQ(b.bell.back(), 0);
  // Pouca memória: uns 450 KB ao todo, só com o som ligado.
  EXPECT_LT(b.bytes(), 500u * 1024);
}

TEST(Bank, OsSonsEmRodizioEORetrocesso) {
  const Bank b = Bank::load(PQK_SOUNDS_DIR);
  EXPECT_EQ(b.of(Kind::key, 7), &b.keys[1]);
  EXPECT_EQ(b.of(Kind::key, -1), &b.keys[5]);
  EXPECT_EQ(b.of(Kind::space, 3), &b.spaces[1]);
  EXPECT_EQ(b.of(Kind::backspace, 0), &b.spaces.back());
  EXPECT_EQ(b.of(Kind::bell, 0), &b.bell);
  EXPECT_LT(Bank::gainOf(Kind::backspace), Bank::gainOf(Kind::key));
}

TEST(Bank, SemOsArquivosSoOSino) {
  const Bank b = Bank::load("/nao/existe");
  EXPECT_TRUE(b.keys.empty());
  EXPECT_EQ(b.of(Kind::key, 0), nullptr);
  EXPECT_EQ(b.of(Kind::carriageReturn, 0), nullptr);
  EXPECT_NE(b.of(Kind::bell, 0), nullptr);
}

TEST(Wav, SoPcmDe16BitsMonoA44100) {
  EXPECT_TRUE(readWav(std::string(PQK_SOUNDS_DIR) + "/tecla-0.wav"));
  EXPECT_FALSE(readWav("/nao/existe.wav"));
  // Um arquivo que não é WAV, e um WAV estéreo.
  const std::string dir = ::testing::TempDir();
  {
    FILE* f = std::fopen((dir + "/lixo.wav").c_str(), "wb");
    std::fputs("isto nao e um wav", f);
    std::fclose(f);
  }
  EXPECT_FALSE(readWav(dir + "/lixo.wav"));
  {
    const unsigned char hdr[] = {'R', 'I', 'F', 'F', 40, 0, 0, 0, 'W', 'A', 'V', 'E', 'f', 'm', 't', ' ', 16, 0, 0, 0,
                                 1,   0,   2,   0,   0x44, 0xAC, 0, 0, 0x10, 0xB1, 2, 0, 4, 0, 16, 0, 'd', 'a', 't', 'a',
                                 4,   0,   0,   0,   1,   0,   1,   0};
    FILE* f = std::fopen((dir + "/estereo.wav").c_str(), "wb");
    std::fwrite(hdr, 1, sizeof hdr, f);
    std::fclose(f);
  }
  EXPECT_FALSE(readWav(dir + "/estereo.wav"));
}

TEST(Mixer, SomaComSaturacaoESoltaAsVozesQueAcabam) {
  const std::vector<int16_t> loud(10, 30000), short2(2, 1000);
  Mixer m;
  int16_t out[10];
  EXPECT_FALSE(m.mix(out, 10));
  m.start(&loud, 1);
  m.start(&loud, 1);
  m.start(&short2, 0.5f);
  ASSERT_TRUE(m.mix(out, 4));
  EXPECT_EQ(out[0], 32767);
  m.mix(out, 10);
  EXPECT_TRUE(m.idle());
}

TEST(Mixer, VozesDemaisTiramAMaisVelha) {
  const std::vector<int16_t> s(100, 100);
  Mixer m;
  for (size_t i = 0; i < Mixer::kMaxVoices + 3; i++) m.start(&s, 1);
  int16_t out[1];
  m.mix(out, 1);
  EXPECT_EQ(out[0], static_cast<int16_t>(100 * Mixer::kMaxVoices));
}

TEST(Player, DesligadoNaoTocaNemAbreASaida) {
  auto sink = std::make_unique<FakeSink>();
  auto* fake = sink.get();
  Player p(std::move(sink), PQK_SOUNDS_DIR);
  p.play(Kind::key);
  std::this_thread::sleep_for(std::chrono::milliseconds(30));
  EXPECT_EQ(p.started(), 0);
  EXPECT_EQ(fake->opens, 0);
}

TEST(Player, LigadoTocaEFechaASaidaDepoisDoSilencio) {
  auto sink = std::make_unique<FakeSink>();
  auto* fake = sink.get();
  Player p(std::move(sink), PQK_SOUNDS_DIR, 60);
  p.setEnabled(true, 0.5);
  p.play(Kind::key);
  ASSERT_TRUE(waitFor([&] { return p.started() == 1 && fake->writes >= 9; }));
  EXPECT_EQ(fake->opens, 1);
  // O volume vale: a metade do volume não passa da metade do pico.
  EXPECT_GT(fake->loudest, 0);
  EXPECT_LE(fake->loudest, 32767 * 0.5 + 1);
  ASSERT_TRUE(waitFor([&] { return fake->closes == 1; }));
  // Tocar de novo reabre.
  p.play(Kind::carriageReturn);
  ASSERT_TRUE(waitFor([&] { return fake->opens == 2; }));
  p.setEnabled(false, 0.5);
  ASSERT_TRUE(waitFor([&] { return fake->closes == 2; }));
  EXPECT_FALSE(p.enabled());
}

TEST(Player, SemServidorFicaMudoENaoTentaACadaTecla) {
  auto sink = std::make_unique<FakeSink>();
  auto* fake = sink.get();
  fake->canOpen = false;
  Player p(std::move(sink), PQK_SOUNDS_DIR);
  p.setEnabled(true, 1);
  for (int i = 0; i < 20; i++) {
    p.play(Kind::key);
    std::this_thread::sleep_for(std::chrono::milliseconds(2));
  }
  ASSERT_TRUE(waitFor([&] { return p.started() >= 1; }));
  std::this_thread::sleep_for(std::chrono::milliseconds(30));
  EXPECT_EQ(fake->opens, 1);
  EXPECT_EQ(fake->writes, 0);
}
