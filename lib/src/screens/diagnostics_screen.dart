import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/ai_providers.dart';

class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool keyPresent = false;
    try {
      keyPresent = (dotenv.maybeGet('OPENROUTER_API_KEY') ?? '').isNotEmpty;
    } catch (_) {
      keyPresent =
          false; // dotenv not initialized; could still be using dart-define
    }
    return Scaffold(
      appBar: AppBar(title: const Text('AI Diagnostics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
            'API Key Present',
            keyPresent ? 'Yes' : 'No',
            icon: keyPresent ? Icons.check_circle : Icons.error,
            color: keyPresent ? Colors.green : Colors.red,
          ),
          _tile('Active Model', 'OpenRouter (DeepSeek)'),
          const SizedBox(height: 8),
          const Text(
            'Tip: On web, the app expects --dart-define OPENROUTER_API_KEY=sk-or-… at build time (provided by GitHub Actions).',
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final backend = ref.read(aiBackendProvider);
                final r = await backend.chat('Diagnostic: respond with OK');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Chat OK: ${r.substring(0, r.length > 40 ? 40 : r.length)}',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Chat error: $e')));
                }
              }
            },
            icon: const Icon(Icons.bolt),
            label: const Text('Probe Chat'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final backend = ref.read(aiBackendProvider);
                final s = await backend.summarize(
                  'Short test text about algebra.',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Summary OK: ${s.substring(0, s.length > 40 ? 40 : s.length)}',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Summary error: $e')));
                }
              }
            },
            icon: const Icon(Icons.summarize),
            label: const Text('Probe Summarize'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final backend = ref.read(aiBackendProvider);
                final cards = await backend.generateFlashcards(
                  'Algebra involves variables and equations.',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Flashcards OK: ${cards.length} generated'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Flashcard error: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.style),
            label: const Text('Probe Flashcards'),
          ),
        ],
      ),
    );
  }

  Widget _tile(String title, String value, {IconData? icon, Color? color}) {
    return Card(
      child: ListTile(
        leading: icon != null ? Icon(icon, color: color) : null,
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}
