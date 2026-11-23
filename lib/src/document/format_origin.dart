// De onde vem cada formatação no cursor (o "Revelar formatação", Fase 2B,
// Etapa 3): do estilo do parágrafo ou direta. Compara os estados do motor
// com as propriedades do estilo lidas da cópia temporária (D-044).
import 'fodt.dart';

/// Uma linha do "Revelar formatação".
enum FormatAspect { font, size, bold, italic, color, alignment, firstLine }

/// true: direta (diferente do estilo); false: do estilo; sem a chave: não se
/// sabe (o estilo não diz, ou a cópia ainda não chegou).
Map<FormatAspect, bool> formatOrigins({
  required StyleProps? style,
  required String? fontName,
  required double? fontSize,
  required bool bold,
  required bool italic,
  required int? color,
  required String alignment,
  required double? firstLineCm,
}) {
  final s = style;
  if (s == null) return const {};
  final out = <FormatAspect, bool>{};
  if (s.fontName != null && fontName != null) out[FormatAspect.font] = s.fontName != fontName;
  if (s.sizePt != null && fontSize != null) out[FormatAspect.size] = (s.sizePt! - fontSize).abs() > 0.05;
  out[FormatAspect.bold] = (s.bold ?? false) != bold;
  out[FormatAspect.italic] = (s.italic ?? false) != italic;
  // A cor automática do estado é null; no estilo, sem cor ou preta.
  final styleColor = s.color == 0 ? null : s.color;
  out[FormatAspect.color] = styleColor != color;
  out[FormatAspect.alignment] = (s.align ?? 'start') != alignment;
  if (firstLineCm != null) out[FormatAspect.firstLine] = ((s.firstLineCm ?? 0) - firstLineCm).abs() > 0.01;
  return out;
}
