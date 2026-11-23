/// Normalized representation of a caregiver facilitation step.
///
/// Strips redundant leading list numbers (e.g. `"1. "`, `"1. 1. "`, `"Step 2: "`)
/// and extracts an optional short action heading before the first colon so UI
/// components can display clean numbered step badges without duplicated digits.
class ParsedFacilitationStep {
  final String? heading;
  final String body;
  final String cleanedText;

  const ParsedFacilitationStep({
    this.heading,
    required this.body,
    required this.cleanedText,
  });
}

final RegExp _leadingNumberPrefix = RegExp(
  r'^\s*(?:step\s*)?\d+\s*[\.\)\-:]\s*',
  caseSensitive: false,
);

/// Strips repeated leading step numbers (`"1. 1. Foo"` -> `"Foo"`) and
/// optionally splits `"Heading: Body"` when the heading is concise.
ParsedFacilitationStep parseFacilitationStep(String raw) {
  var cleaned = raw.trim();
  while (true) {
    final match = _leadingNumberPrefix.firstMatch(cleaned);
    if (match == null) break;
    final next = cleaned.substring(match.end).trimLeft();
    if (next.isEmpty || next == cleaned) break;
    cleaned = next;
  }

  final colonIndex = cleaned.indexOf(':');
  if (colonIndex > 2 && colonIndex <= 56) {
    final candidateHeading = cleaned.substring(0, colonIndex).trim();
    final candidateBody = cleaned.substring(colonIndex + 1).trim();
    final looksLikeUrl = candidateHeading.toLowerCase().endsWith('http') ||
        candidateHeading.toLowerCase().endsWith('https');
    if (!looksLikeUrl &&
        candidateHeading.isNotEmpty &&
        candidateBody.isNotEmpty) {
      return ParsedFacilitationStep(
        heading: candidateHeading,
        body: candidateBody,
        cleanedText: cleaned,
      );
    }
  }

  return ParsedFacilitationStep(
    heading: null,
    body: cleaned,
    cleanedText: cleaned,
  );
}
