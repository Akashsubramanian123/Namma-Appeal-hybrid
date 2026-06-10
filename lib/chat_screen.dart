import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';
import 'secrets.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/services.dart'; // Required for Haptics
class ChatScreen extends StatefulWidget {
  final String? initialContext;
  final VoidCallback? onContextConsumed;

  const ChatScreen({super.key, this.initialContext, this.onContextConsumed});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late GenerativeModel _model;
  late ChatSession _chatSession;

  // Each message: {"role": "user"|"model", "text": "...", "isStreaming": bool}
  List<Map<String, dynamic>> _messages = [];
  bool _isStreaming = false;

  String? _currentSessionId;
  String _currentSessionTitle = "New Legal Chat";
  List<Map<String, dynamic>> _allSessions = [];

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    
    // INJECT THE SYSTEM INSTRUCTION HERE to give the AI its persona!
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', 
      apiKey: Secrets.geminiApiKey,
      systemInstruction: Content.system(
        "You are Namma-Appeal AI, a specialized legal co-pilot designed to help Indian citizens navigate the Right to Information (RTI) Act, 2005. "
        "Your primary job is to help users draft RTI applications, analyze government rejection letters, explain legal jargon, and empower citizens to fight bureaucratic delays. "
        "You must NEVER refer to yourself as a generic language model or mention that you were trained by Google. "
        "Always respond in the first person as Namma-Appeal AI. Maintain a professional, empathetic, and highly knowledgeable legal persona. "
        "Always be concise, practical, and focused on Indian constitutional and civic rights."
      ),
    );
    
    _startNewChat();
    _fetchSessionsList();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    } else {
      if (_speechEnabled) {
        setState(() => _isListening = true);
        await _speechToText.listen(
          onResult: (result) =>
              setState(() => _messageController.text = result.recognizedWords),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Microphone permission denied.')));
      }
    }
  }

  void _startNewChat() {
    setState(() {
      _currentSessionId = null;
      _currentSessionTitle = "New Legal Chat";
      _messages = [
        {
          "role": "model",
          "text": "Hello! I am your Namma-Appeal legal assistant. How can I help you today?",
          "isStreaming": false,
        }
      ];
      _chatSession = _model.startChat();
    });

    if (widget.initialContext != null && widget.initialContext!.isNotEmpty) {
      _processInitialContext(widget.initialContext!);
    }
  }

  Future<void> _fetchSessionsList() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final data = await Supabase.instance.client
          .from('chat_sessions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      setState(() => _allSessions = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint("Failed to fetch sessions: $e");
    }
  }

  Future<void> _loadPastChat(String sessionId, String title) async {
    setState(() {
      _isStreaming = false;
      _currentSessionId = sessionId;
      _currentSessionTitle = title;
    });

    try {
      final data = await Supabase.instance.client
          .from('chat_messages')
          .select()
          .eq('session_id', sessionId)
          .order('created_at', ascending: true);

      // FIX 1: Explicitly cast the history mapping for Mobile AOT
      List<Content> history = (data as List<dynamic>).map<Content>((msg) {
        return msg['role'] == 'user'
            ? Content.text(msg['message_text'].toString())
            : Content.model([TextPart(msg['message_text'].toString())]);
      }).toList();

      setState(() {
        _chatSession = _model.startChat(history: history);
        
        // FIX 2: Force the list to be a flexible Map<String, dynamic> 
        _messages = List<Map<String, dynamic>>.from(
          data.map((msg) => <String, dynamic>{
            "role": msg['role'].toString(),
            "text": msg['message_text'].toString(),
            "isStreaming": false,
          })
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading chat: $e')));
    } finally {
      _scrollToBottom();
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    try {
      await Supabase.instance.client.from('chat_sessions').delete().eq('id', sessionId);
      if (_currentSessionId == sessionId) _startNewChat();
      _fetchSessionsList();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Chat deleted successfully.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error deleting chat: $e')));
      }
    }
  }

  Future<void> _ensureSessionExists(String firstMessage) async {
    if (_currentSessionId != null) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    List<String> words = firstMessage.split(' ');
    String newTitle = words.take(5).join(' ') + (words.length > 5 ? "..." : "");
    if (newTitle == "I have attached a document...") newTitle = "Document Analysis";

    try {
      final response = await Supabase.instance.client.from('chat_sessions').insert({
        'user_id': userId,
        'title': newTitle,
      }).select().single();

      setState(() {
        _currentSessionId = response['id'];
        _currentSessionTitle = newTitle;
      });
      _fetchSessionsList();
    } catch (e) {
      debugPrint("Failed to create session: $e");
    }
  }

  Future<void> _saveMessageToCloud(String text, String role) async {
    try {
      if (_currentSessionId != null) {
        await Supabase.instance.client.from('chat_messages').insert({
          'session_id': _currentSessionId,
          'user_id': Supabase.instance.client.auth.currentUser?.id,
          'message_text': text,
          'role': role,
        });
      }
    } catch (e) {
      debugPrint("Failed to save message: $e");
    }
  }

  Future<void> _processInitialContext(String contextText) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      setState(() => _messages.add({
            "role": "model",
            "text": "You are offline.",
            "isStreaming": false,
          }));
      if (widget.onContextConsumed != null) widget.onContextConsumed!();
      return;
    }

    setState(() {
      _messages.add({
        "role": "user",
        "text": "I have attached a document for context.",
        "isStreaming": false,
      });
      _isStreaming = true;
    });

    // Add placeholder for streaming AI response
    final int aiIndex = _messages.length;
    setState(() => _messages.add({"role": "model", "text": "", "isStreaming": true}));
    _scrollToBottom();

    try {
      await _ensureSessionExists("I have attached a document for context.");
      await _saveMessageToCloud("I have attached a document for context.", "user");

      final prompt =
          "The user has attached the following document/context from the app. Acknowledge that you have received it, briefly summarize what it is in one sentence, and ask how you can help them with it.\n\nDOCUMENT CONTEXT:\n$contextText";

      final stream = _chatSession.sendMessageStream(Content.text(prompt));
      final buffer = StringBuffer();

      await for (final chunk in stream) {
        if (!mounted) break;
        buffer.write(chunk.text ?? '');
        setState(() {
          _messages[aiIndex] = {
            "role": "model",
            "text": '${buffer.toString()}▌',
            "isStreaming": true,
          };
        });
        _scrollToBottom();
      }

      final aiResponseText = buffer.toString();
      setState(() {
        _messages[aiIndex] = {
          "role": "model",
          "text": aiResponseText,
          "isStreaming": false,
        };
        _isStreaming = false;
      });

      await _saveMessageToCloud(aiResponseText, "model");
    } catch (e) {
      setState(() {
        _messages[aiIndex] = {"role": "model", "text": "Error: $e", "isStreaming": false};
        _isStreaming = false;
      });
    } finally {
      if (widget.onContextConsumed != null) widget.onContextConsumed!();
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No internet connection.'), backgroundColor: Colors.red));
      return;
    }
    // Triggers a subtle, premium vibration
    HapticFeedback.lightImpact();
    setState(() {
      _messages.add(<String, dynamic>{"role": "user", "text": text, "isStreaming": false});
      _messageController.clear();
      _isStreaming = true;
    });
    _scrollToBottom();

    final int aiIndex = _messages.length;
    setState(() => _messages.add(<String, dynamic>{"role": "model", "text": "", "isStreaming": true}));
    _scrollToBottom();

    try {
      await _ensureSessionExists(text);
      await _saveMessageToCloud(text, 'user');

      final stream = _chatSession.sendMessageStream(Content.text(text));
      final buffer = StringBuffer();

      await for (final chunk in stream) {
        if (!mounted) break;
        buffer.write(chunk.text ?? '');
        setState(() {
          _messages[aiIndex] = {
            "role": "model",
            "text": '${buffer.toString()}▌',
            "isStreaming": true,
          };
        });
        _scrollToBottom();
      }

      final aiText = buffer.toString();
      setState(() {
        _messages[aiIndex] = {"role": "model", "text": aiText, "isStreaming": false};
        _isStreaming = false;
      });

      await _saveMessageToCloud(aiText, 'model');
    } catch (e) {
      setState(() {
        _messages[aiIndex] = {"role": "model", "text": "Error: $e", "isStreaming": false};
        _isStreaming = false;
      });
    } finally {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showHistoryModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Chat History",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: _allSessions.isEmpty
                    ? const Center(child: Text("No past chats found."))
                    : ListView.builder(
                        itemCount: _allSessions.length,
                        itemBuilder: (context, index) {
                          final session = _allSessions[index];
                          return ListTile(
                            leading: const Icon(Icons.chat_bubble_outline),
                            title: Text(session['title']),
                            subtitle: Text(DateTime.parse(session['created_at'])
                                .toLocal()
                                .toString()
                                .split(' ')[0]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () async {
                                Navigator.pop(context);
                                bool? confirm = await showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Chat'),
                                    content: const Text(
                                        'Are you sure you want to permanently delete this conversation?'),
                                    actions: [
                                      TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('Cancel')),
                                      TextButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Delete',
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold))),
                                    ],
                                  ),
                                );
                                if (confirm == true) _deleteSession(session['id']);
                              },
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _loadPastChat(session['id'], session['title']);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Column(
        children: [
          // Top Chat Control Bar with streaming indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 4)],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.history),
                  color: themeColor,
                  onPressed: _showHistoryModal,
                  tooltip: "View Past Chats",
                ),
                Expanded(
                  child: Text(
                    _currentSessionTitle,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isStreaming)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: themeColor),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.add_box_outlined),
                  color: themeColor,
                  onPressed: _startNewChat,
                  tooltip: "New Chat",
                ),
              ],
            ),
          ),

          // Chat ListView
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(15),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["role"] == "user";
                final text = msg["text"] as String;

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? themeColor : Theme.of(context).colorScheme.surface,
                      border: isUser
                          ? null
                          : Border.all(color: themeColor.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(15).copyWith(
                        bottomRight:
                            isUser ? const Radius.circular(0) : const Radius.circular(15),
                        bottomLeft:
                            isUser ? const Radius.circular(15) : const Radius.circular(0),
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: MarkdownBody(
                      data: text,
                      selectable: !isUser,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                            color: isUser ? Colors.white : Colors.black87, fontSize: 15),
                        strong: TextStyle(
                            color: isUser ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Ask for legal advice...",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.red : themeColor,
                          size: 26,
                        ),
                        onPressed: _toggleListening,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: themeColor,
                  child: IconButton(
                    icon: Icon(
                      _isStreaming ? Icons.hourglass_empty : Icons.send,
                      color: Colors.white,
                    ),
                    onPressed: _isStreaming ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
