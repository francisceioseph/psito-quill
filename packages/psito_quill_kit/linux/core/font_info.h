// A classificação das fontes do sistema pelo fontconfig, para os filtros da
// lista de fontes (Fase 2B, Etapa 3): com serifa, sem serifa, monoespaçada.
#pragma once

#include <string>

namespace pqk {

enum FontClass : int {
  kFontMono = 1,
  kFontSerif = 2,
  kFontSans = 4,
};

// Uma família por linha; devolve um número por linha (a soma das classes,
// 0 se a fonte não está instalada). Sem estado: pode ser chamada de qualquer
// thread (o fontconfig se protege), e não toca no LibreOffice.
std::string classifyFonts(const std::string& familiesByLine);

}  // namespace pqk
