import '../models/flashcard.dart' as models;

/// Lightweight, on-device fallbacks used when online AI is unavailable.
/// These are heuristic and not as smart as real models, but keep the UX flowing.
class LocalAIFallback {
  static String summarize(String text, {int maxWords = 150}) {
    final clean = _normalize(text);
    if (clean.isEmpty) return 'No content to summarize.';

    // Split into sentences and take until we hit the word budget.
    final sentences = _splitSentences(clean);
    final buffer = StringBuffer();
    int words = 0;
    for (final s in sentences) {
      final wc = _wordCount(s);
      if (words + wc > maxWords && words > 0) break;
      buffer.writeln('- ${s.trim()}');
      words += wc;
      if (words >= maxWords) break;
    }

    if (buffer.isEmpty) {
      // Fallback: truncate text to maxWords
      final tokens = clean.split(RegExp(r"\s+")).take(maxWords).join(' ');
      return '- $tokens…';
    }

    return buffer.toString().trim();
  }

  static List<models.Flashcard> flashcards(String text, {int count = 5}) {
    final clean = _normalize(text);
    final now = DateTime.now();
    final out = <models.Flashcard>[];

    // Heuristic 1: Use definition patterns within sentences.
    final sentences = _splitSentences(clean);
    for (final s in sentences) {
      if (out.length >= count) break;
      final lower = s.toLowerCase();
      String? term;
      String? definition;
      if (lower.contains(' is ')) {
        final idx = lower.indexOf(' is ');
        term = s.substring(0, idx).trim();
        definition = s.substring(idx + 4).trim();
      } else if (lower.contains(' are ')) {
        final idx = lower.indexOf(' are ');
        term = s.substring(0, idx).trim();
        definition = s.substring(idx + 5).trim();
      } else if (lower.contains(' refers to ')) {
        final idx = lower.indexOf(' refers to ');
        term = s.substring(0, idx).trim();
        definition = s.substring(idx + ' refers to '.length).trim();
      } else if (lower.contains(':')) {
        final idx = lower.indexOf(':');
        term = s.substring(0, idx).trim();
        definition = s.substring(idx + 1).trim();
      }

      if (term != null && definition != null) {
        term = _shrink(term, 8);
        definition = _shrink(definition, 40);
        if (term.isNotEmpty && definition.isNotEmpty) {
          out.add(
            models.Flashcard(
              id: '${now.microsecondsSinceEpoch}_${out.length}',
              question: 'What is $term?',
              answer: definition,
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      }
    }

    // Heuristic 2: Keyword-based if not enough
    if (out.length < count) {
      final keywords = _topKeywords(clean, limit: count * 2);
      for (final k in keywords) {
        if (out.length >= count) break;
        // Find first sentence containing keyword
        final s = sentences.firstWhere(
          (e) => e.toLowerCase().contains(k.toLowerCase()),
          orElse: () => '',
        );
        if (s.isEmpty) continue;
        out.add(
          models.Flashcard(
            id: '${now.microsecondsSinceEpoch}_${out.length}',
            question: 'Define $k',
            answer: _shrink(s.trim(), 60),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    }

    return out.take(count).toList();
  }

  static String chatFallback(String prompt) {
    final topic = _inferTopic(prompt);
    return [
      'AI is temporarily unavailable due to daily quota limits.',
      if (topic.isNotEmpty)
        'Here are study pointers for "$topic":'
      else
        'Here are general study pointers:',
      '- Break the topic into 3–5 key questions and try answering each briefly.',
      '- Create flashcards for terms, formulas, and definitions you see.',
      '- Summarize your notes in bullets: background, core idea, steps, pitfalls.',
      '- Do a quick recall test: explain the idea in your own words without looking.',
    ].join('\n');
  }

  // ------------------------ helpers ------------------------
  static String _normalize(String s) =>
      s.replaceAll(RegExp(r"\s+"), ' ').trim();

  static List<String> _splitSentences(String s) {
    final parts = s.split(RegExp(r"(?<=[\.\?\!])\s+"));
    return parts.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  static int _wordCount(String s) =>
      s.split(RegExp(r"\s+")).where((w) => w.isNotEmpty).length;

  static String _shrink(String s, int maxWords) {
    final parts = s.split(RegExp(r"\s+")).where((w) => w.isNotEmpty).toList();
    if (parts.length <= maxWords) return s.trim();
    return parts.take(maxWords).join(' ') + '…';
  }

  static List<String> _topKeywords(String text, {int limit = 10}) {
    final stop = <String>{
      'the',
      'is',
      'are',
      'to',
      'of',
      'and',
      'a',
      'in',
      'for',
      'on',
      'that',
      'with',
      'as',
      'by',
      'it',
      'an',
      'be',
      'this',
      'from',
      'or',
      'at',
      'we',
      'you',
      'your',
      'our',
      'their',
      'was',
      'were',
      'will',
      'can',
      'could',
      'should',
      'would',
    };
    final counts = <String, int>{};
    for (final w in text.toLowerCase().split(RegExp(r"[^a-z0-9]+"))) {
      if (w.isEmpty || stop.contains(w) || w.length <= 2) continue;
      counts[w] = (counts[w] ?? 0) + 1;
    }
    final sorted =
        counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  static String _inferTopic(String prompt) {
    final words = prompt
        .split(RegExp(r"\s+"))
        .where((w) => w.length > 3)
        .take(5);
    return words.join(' ');
  }
}
