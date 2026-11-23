#include "core/font_info.h"

#include <fontconfig/fontconfig.h>

#include <cstring>
#include <sstream>

namespace pqk {

namespace {

// O fontconfig acrescenta a família genérica ("serif", "sans-serif",
// "monospace") pelas regras do sistema (45-latin.conf). A primeira que
// aparece depois do nome pedido é a classe da fonte. As fontes que as regras
// não conhecem ganham "sans-serif" (49-sansserif.conf): ficam como sem
// serifa, o que costuma estar certo e é só um filtro.
int genericOf(FcPattern* pattern) {
  FcChar8* family = nullptr;
  for (int i = 1; FcPatternGetString(pattern, FC_FAMILY, i, &family) == FcResultMatch; i++) {
    const char* f = reinterpret_cast<const char*>(family);
    if (std::strcmp(f, "monospace") == 0) return kFontMono;
    if (std::strcmp(f, "serif") == 0) return kFontSerif;
    if (std::strcmp(f, "sans-serif") == 0 || std::strcmp(f, "sans") == 0) return kFontSans;
  }
  return 0;
}

int classify(const std::string& name) {
  FcPattern* pattern = FcPatternCreate();
  FcPatternAddString(pattern, FC_FAMILY, reinterpret_cast<const FcChar8*>(name.c_str()));
  FcConfigSubstitute(nullptr, pattern, FcMatchPattern);
  FcDefaultSubstitute(pattern);
  int classes = genericOf(pattern);

  // O espaçamento de verdade vem da fonte escolhida, se for a pedida.
  FcResult result;
  FcPattern* match = FcFontMatch(nullptr, pattern, &result);
  if (match) {
    FcChar8* got = nullptr;
    int spacing = 0;
    const bool same = FcPatternGetString(match, FC_FAMILY, 0, &got) == FcResultMatch &&
                      FcStrCmpIgnoreCase(got, reinterpret_cast<const FcChar8*>(name.c_str())) == 0;
    if (!same) {
      classes = 0;  // não instalada: o fontconfig trocou por outra
    } else if (FcPatternGetInteger(match, FC_SPACING, 0, &spacing) == FcResultMatch &&
               spacing >= FC_MONO) {
      classes = kFontMono;
    }
    FcPatternDestroy(match);
  }
  FcPatternDestroy(pattern);
  return classes;
}

}  // namespace

std::string classifyFonts(const std::string& familiesByLine) {
  FcInit();
  std::istringstream in(familiesByLine);
  std::ostringstream out;
  std::string line;
  bool first = true;
  while (std::getline(in, line)) {
    if (!first) out << '\n';
    first = false;
    out << (line.empty() ? 0 : classify(line));
  }
  return out.str();
}

}  // namespace pqk
