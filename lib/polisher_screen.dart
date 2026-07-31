import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart'; // Access themes and PremiumGlassCard

class PolisherScreen extends StatefulWidget {
  final Function(String)? onChatTriggered;
  final Function(int, [String?])? onNavigate;
  final String? initialText;

  const PolisherScreen({super.key, this.onChatTriggered, this.onNavigate, this.initialText});

  @override
  State<PolisherScreen> createState() => _PolisherScreenState();
}

class _PolisherScreenState extends State<PolisherScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isStreaming = false;
  String _polishedResult = "";

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null) {
      _textController.text = widget.initialText!;
    }
  }

  Future<void> _processText() async {
    String textInput = _textController.text.trim();
    if (textInput.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isStreaming = true;
      _polishedResult = "";
    });

    try {
      // ── SMART INTENT CLASSIFIER (Ultra-fast Llama 3.3) ──
      final classifierBody = {
        "model": "llama-3.3-70b-versatile",
        "messages": [
          {
            "role": "system",
            "content": "You are a strict routing AI. Classify the user's text into exactly ONE WORD:\n1. 'LETTER': If it is a pre-written formal letter, application, or appeal body to be reviewed/polished.\n2. 'GRIEVANCE': If it is a description of an issue OR a command to write a document (e.g., 'Draft an RTI...', 'I want to file...', 'Write a letter...').\n3. 'QUESTION': ONLY if the user is asking YOU a conversational question or seeking legal advice (e.g., 'How do I...', 'What is the law...'). NEVER output 'QUESTION' if the user is telling you to draft a letter that asks questions to a third party.\nRespond with the single word only."
          },
          {"role": "user", "content": textInput}
        ],
        "temperature": 0.0
      };

      final classRes = await Supabase.instance.client.functions.invoke('groq-api', body: {'requestBody': classifierBody});
      
      if (classRes.status == 200 && classRes.data != null) {
        String intent = classRes.data['choices'][0]['message']['content'].toString().trim().toUpperCase();
        
        // ── AUTO-ROUTING LOGIC ──
        if (intent.contains('GRIEVANCE')) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This looks like a raw grievance! Routing you to the Draft generator...'), backgroundColor: Color(0xFF10B981)));
          if (widget.onNavigate != null) widget.onNavigate!(1, textInput); // Route to New RTI
          return;
        } else if (intent.contains('QUESTION')) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This is a question! Routing you to the Legal Co-Pilot...'), backgroundColor: kRoyalBlue));
          if (widget.onChatTriggered != null) widget.onChatTriggered!(textInput); // Route to Chat
          return;
        }
      }

      // ── IF IT IS A LETTER, PROCEED WITH POLISHING ──
      final polishBody = {
        "model": "llama-3.3-70b-versatile",
        "messages": [
          {
            "role": "system",
            "content": "You are a senior Indian High Court lawyer. The user will provide a rough or poorly formatted letter. Rewrite it instantly into a cold, highly professional, and intimidating legal RTI application. Ensure correct formatting. DO NOT add conversational filler. ONLY return the rewritten letter."
          },
          {"role": "user", "content": textInput}
        ],
        "temperature": 0.2,
      };

      final response = await Supabase.instance.client.functions.invoke('groq-api', body: {'requestBody': polishBody});
      if (response.status != 200) throw Exception(response.data);

      final polishedText = response.data['choices'][0]['message']['content'].toString().trim();

      setState(() {
        _polishedResult = polishedText;
        _isStreaming = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✨ Letter professionally polished!'), backgroundColor: kSuccessEmerald));
    } catch (e) {
      setState(() => _isStreaming = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: kRejectedRed));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("AI Document Polisher", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kTextSlate)),
          const SizedBox(height: 8),
          const Text("Paste an existing rough letter or application here. Our legal AI will format it perfectly.", style: TextStyle(color: kTextSecondary)),
          const SizedBox(height: 24),

          PremiumGlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                TextField(
                  controller: _textController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: "To the PIO, I am writing to ask about the broken road...",
                    hintStyle: TextStyle(color: kTextSecondary.withOpacity(0.5)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black12)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _isStreaming ? null : _processText,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isStreaming ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_fix_high),
                  label: Text(_isStreaming ? "Analyzing Intent..." : "Review & Polish Letter", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          
          if (_polishedResult.isNotEmpty) ...[
            const SizedBox(height: 32),
            const Text("Polished Legal Draft", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextSlate)),
            const SizedBox(height: 16),
            PremiumGlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(data: _polishedResult, selectable: true),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => generateAndPrintPdf(_polishedResult, context, isAppeal: false),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Generate PDF"),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}