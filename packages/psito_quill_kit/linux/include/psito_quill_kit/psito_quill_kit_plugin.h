#ifndef FLUTTER_PLUGIN_PSITO_QUILL_KIT_PLUGIN_H_
#define FLUTTER_PLUGIN_PSITO_QUILL_KIT_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FLUTTER_PLUGIN_EXPORT
#endif

// Só guarda o registro de texturas: o resto da API é C, por FFI
// (quill_kit_api.h).
FLUTTER_PLUGIN_EXPORT void psito_quill_kit_plugin_register_with_registrar(
    FlPluginRegistrar* registrar);

G_END_DECLS

#endif  // FLUTTER_PLUGIN_PSITO_QUILL_KIT_PLUGIN_H_
