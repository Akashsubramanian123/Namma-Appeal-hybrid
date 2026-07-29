import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/services.dart';

const kRoyalBlue = Color(0xFF2563EB);
const kTextSlate = Color(0xFF1E293B);
const kTextSecondary = Color(0xFF64748B);
const kRejectedRed = Color(0xFFEF4444);

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

  List<Map<String, dynamic>> _messages = [];
  bool _isStreaming = false;
  String? _currentSessionId;
  String _currentSessionTitle = "New Legal Chat";
  List<Map<String, dynamic>> _allSessions = [];

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  final String _systemInstruction = 
      "You are Namma-Appeal AI, a specialized legal co-pilot designed to help Indian citizens navigate the Right to Information (RTI) Act, 2005. "
      "Always respond in the first person as Namma-Appeal AI. Maintain a professional, empathetic, and highly knowledgeable legal persona. "
      "Always be concise, practical, and focused on Indian constitutional and civic rights.";

  @override
  void initState() {
    super.initState();
    _initSpeech();
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
        await _speechToText.listen(onResult: (result) => setState(() => _messageController.text = result.recognizedWords));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission denied.')));
      }
    }
  }

  void _startNewChat() {
    setState(() {
      _currentSessionId = null;
      _currentSessionTitle = "New Legal Chat";
      _messages = [{"role": "model", "text": "Hello! I am your Namma-Appeal legal assistant. How can I help you today?", "isStreaming": false}];
    });
    if (widget.initialContext != null && widget.initialContext!.isNotEmpty) {
      _processInitialContext(widget.initialContext!);
    }
  }

  Future<void> _fetchSessionsList() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final data = await Supabase.instance.client.from('chat_sessions').select().eq('user_id', userId).order('created_at', ascending: false);
      setState(() => _allSessions = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint("Failed to fetch sessions: $e");
    }
  }

  Future<void> _loadPastChat(String sessionId, String title) async {
    setState(() { _isStreaming = false; _currentSessionId = sessionId; _currentSessionTitle = title; });
    try {
      final data = await Supabase.instance.client.from('chat_messages').select().eq('session_id', sessionId).order('created_at', ascending: true);
      setState(() {
        _messages = List<Map<String, dynamic>>.from(data.map((msg) => <String, dynamic>{"role": msg['role'].toString(), "text": msg['message_text'].toString(), "isStreaming": false}));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading chat: $e')));
    } finally {
      _scrollToBottom();
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    try {
      await Supabase.instance.client.from('chat_sessions').delete().eq('id', sessionId);
      if (_currentSessionId == sessionId) _startNewChat();
      _fetchSessionsList();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat deleted successfully.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting chat: $e')));
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
      final response = await Supabase.instance.client.from('chat_sessions').insert({'user_id': userId, 'title': newTitle}).select().single();
      setState(() { _currentSessionId = response['id']; _currentSessionTitle = newTitle; });
      _fetchSessionsList();
    } catch (e) {
      debugPrint("Failed to create session: $e");
    }
  }

  Future<void> _saveMessageToCloud(String text, String role) async {
    try {
      if (_currentSessionId != null) {
        await Supabase.instance.client.from('chat_messages').insert({'session_id': _currentSessionId, 'user_id': Supabase.instance.client.auth.currentUser?.id, 'message_text': text, 'role': role});
      }
    } catch (e) {
      debugPrint("Failed to save message: $e");
    }
  }

  Future<void> _processInitialContext(String contextText) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      setState(() => _messages.add({"role": "model", "text": "You are offline.", "isStreaming": false}));
      if (widget.onContextConsumed != null) widget.onContextConsumed!();
      return;
    }
    setState(() {
      _messages.add({"role": "user", "text": "I have attached a document for context.", "isStreaming": false});
      _isStreaming = true;
    });
    final int aiIndex = _messages.length;
    setState(() => _messages.add({"role": "model", "text": "", "isStreaming": true}));
    _scrollToBottom();
    try {
      await _ensureSessionExists("I have attached a document for context.");
      await _saveMessageToCloud("I have attached a document for context.", "user");
      final prompt = "The user has attached the following document/context from the app. Acknowledge that you have received it, briefly summarize what it is in one sentence, and ask how you can help them with it.\n\nDOCUMENT CONTEXT:\n$contextText";
      final formattedContents = [{"role": "user", "parts": [{"text": prompt}]}];
      final Map<String, dynamic> requestBody = {"contents": formattedContents, "systemInstruction": {"parts": [{"text": _systemInstruction}]}};
      final response = await Supabase.instance.client.functions.invoke('groq-api', body: {'targetApi': 'gemini', 'requestBody': requestBody});
      if (response.status != 200) throw Exception(response.data);
      final aiText = response.data['candidates'][0]['content']['parts'][0]['text'].toString();
      setState(() { _messages[aiIndex] = {"role": "model", "text": aiText, "isStreaming": false}; _isStreaming = false; });
      await _saveMessageToCloud(aiText, "model");
    } catch (e) {
      setState(() { _messages[aiIndex] = {"role": "model", "text": "Error communicating safely: $e", "isStreaming": false}; _isStreaming = false; });
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No internet connection.'), backgroundColor: Colors.red));
      return;
    }
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
      final formattedContents = _messages.where((m) => m['text'].toString().isNotEmpty && m['role'] != null).map((m) {
        return {"role": m['role'] == 'user' ? 'user' : 'model', "parts": [{"text": m['text'].toString()}]};
      }).toList();
      final Map<String, dynamic> requestBody = {"contents": formattedContents, "systemInstruction": {"parts": [{"text": _systemInstruction}]}};
      final response = await Supabase.instance.client.functions.invoke('groq-api', body: {'targetApi': 'gemini', 'requestBody': requestBody});
      if (response.status != 200) throw Exception(response.data);
      final aiText = response.data['candidates'][0]['content']['parts'][0]['text'].toString();
      setState(() { _messages[aiIndex] = {"role": "model", "text": aiText, "isStreaming": false}; _isStreaming = false; });
      await _saveMessageToCloud(aiText, 'model');
    } catch (e) {
      setState(() { _messages[aiIndex] = {"role": "model", "text": "Error communicating safely: $e", "isStreaming": false}; _isStreaming = false; });
    } finally {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _showHistoryModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [BoxShadow(color: kTextSlate.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Chat History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextSlate)),
              const Divider(),
              Expanded(
                child: _allSessions.isEmpty
                    ? const Center(child: Text("No past chats found.", style: TextStyle(color: kTextSecondary)))
                    : ListView.builder(
                        itemCount: _allSessions.length,
                        itemBuilder: (context, index) {
                          final session = _allSessions[index];
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: kRoyalBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.chat_bubble_outline, color: kRoyalBlue, size: 20),
                            ),
                            title: Text(session['title'], style: const TextStyle(fontWeight: FontWeight.w600, color: kTextSlate)),
                            subtitle: Text(DateTime.parse(session['created_at']).toLocal().toString().split(' ')[0], style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () async {
                                Navigator.pop(context);
                                bool? confirm = await showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: Colors.white,
                                    title: const Text('Delete Chat'),
                                    content: const Text('Are you sure you want to permanently delete this conversation?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Delete')),
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Glassmorphic Top Control Bar
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5))),
                ),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.history), color: kTextSecondary, onPressed: _showHistoryModal),
                    Expanded(
                      child: Text(
                        _currentSessionTitle,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: kTextSlate, fontSize: 15),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isStreaming)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: kRoyalBlue)),
                      ),
                    IconButton(icon: const Icon(Icons.add_box_rounded), color: kRoyalBlue, onPressed: _startNewChat),
                  ],
                ),
              ),
            ),
          ),

          // Chat ListView
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["role"] == "user";
                final text = msg["text"] as String;

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? kRoyalBlue : Colors.white.withOpacity(0.7),
                      border: isUser ? null : Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                        bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                      ),
                      boxShadow: [
                        if (isUser) BoxShadow(color: kRoyalBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
                        else BoxShadow(color: kTextSlate.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: MarkdownBody(
                      data: text,
                      selectable: !isUser,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(color: isUser ? Colors.white : kTextSlate, fontSize: 15, height: 1.5),
                        strong: TextStyle(color: isUser ? Colors.white : kTextSlate, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Glass Input Box
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.5))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: kTextSlate.withOpacity(0.04), blurRadius: 8)],
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(color: kTextSlate, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: "Ask Namma-Appeal...",
                            hintStyle: TextStyle(color: kTextSecondary.withOpacity(0.6)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            suffixIcon: IconButton(
                              icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? kRejectedRed : kTextSecondary, size: 22),
                              onPressed: _toggleListening,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: kRoyalBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: kRoyalBlue,
                        child: IconButton(
                          icon: Icon(_isStreaming ? Icons.hourglass_empty : Icons.send_rounded, color: Colors.white, size: 20),
                          onPressed: _isStreaming ? null : _sendMessage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}