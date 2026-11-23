// O nome que o autor lê para cada estilo do LibreOffice: os de fábrica vêm
// da l10n; os criados pelo autor, como ele os chamou.
import '../../l10n/gen/app_localizations.dart';

String styleLabel(AppLocalizations l10n, String id) => switch (id) {
      'Standard' => l10n.styleDefault,
      'Text body' => l10n.styleBody,
      'Title' => l10n.styleTitle,
      'Subtitle' => l10n.styleSubtitle,
      'Heading' => l10n.styleHeadingBase,
      'Quotations' => l10n.styleQuote,
      'Preformatted Text' => l10n.stylePreformatted,
      'Footnote' => l10n.styleFootnote,
      'Endnote' => l10n.styleEndnote,
      'Caption' => l10n.styleCaption,
      'Signature' => l10n.styleSignature,
      'First line indent' => l10n.styleFirstLineIndent,
      'Hanging indent' => l10n.styleHangingIndent,
      'Text body indent' => l10n.styleBodyIndent,
      'Header' => l10n.styleHeader,
      'Footer' => l10n.styleFooter,
      'Table Contents' => l10n.styleTableContents,
      'Table Heading' => l10n.styleTableHeading,
      'List' => l10n.styleList,
      'List Contents' => l10n.styleListContents,
      'Marginalia' => l10n.styleMarginalia,
      'Appendix' => l10n.styleAppendix,
      'Emphasis' => l10n.styleEmphasis,
      'Strong Emphasis' => l10n.styleStrongEmphasis,
      'Citation' => l10n.styleCitation,
      _ when id.startsWith('Heading ') && int.tryParse(id.substring(8)) != null =>
        l10n.styleHeading(int.parse(id.substring(8))),
      _ => id,
    };

/// Os estilos de fábrica que a galeria e o diálogo mostram primeiro (os de
/// um livro). Os outros ficam em "Estilos de fábrica".
const bookStyles = [
  'Standard',
  'Text body',
  'First line indent',
  'Title',
  'Subtitle',
  'Heading 1',
  'Heading 2',
  'Heading 3',
  'Quotations',
];
