import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'secrets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'auth_screen.dart';
import 'startup_screens.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'reminder_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'dart:async';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'legal_screen.dart';
import 'package:flutter/services.dart'; // Required for Haptics
import 'package:shimmer/shimmer.dart';
// ==========================================
// USER PROFILE NOTIFIER (global state)
// ==========================================
class UserProfileNotifier extends ValueNotifier<Map<String, dynamic>?> {
  UserProfileNotifier() : super(null);

  Future<void> loadProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      value = data;
    } catch (_) {}
  }

  Future<void> saveProfile(Map<String, dynamic> profile) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final upsertData = {...profile, 'user_id': userId};
    await Supabase.instance.client
        .from('user_profiles')
        .upsert(upsertData, onConflict: 'user_id');
    value = upsertData;
  }
}

final userProfileNotifier = UserProfileNotifier();

// ==========================================
// MAIN ENTRY POINT
// ==========================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  usePathUrlStrategy();

  tz.initializeTimeZones();

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
  const iosInit = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: androidInit, iOS: iosInit),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  await Supabase.initialize(
    url: Secrets.supabaseUrl,
    anonKey: Secrets.supabaseAnonKey,
  );

  runApp(const NammaAppealApp());
}

// ==========================================
// APP + THEME
// ==========================================
class NammaAppealApp extends StatelessWidget {
  const NammaAppealApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryNavy = Color(0xFF1A237E);
    const secondarySaffron = Color(0xFFFF8F00);
    const surfaceOffWhite = Color(0xFFFAFAF7);
    const backgroundOchre = Color(0xFFF5F0E8);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryNavy,
      primary: primaryNavy,
      secondary: secondarySaffron,
      surface: surfaceOffWhite,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ).copyWith(
      surfaceContainerLowest: backgroundOchre,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Namma-Appeal',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: backgroundOchre,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surfaceOffWhite,
          indicatorColor: secondarySaffron.withOpacity(0.25),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: primaryNavy);
            }
            return const IconThemeData(color: Colors.grey);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(color: primaryNavy, fontWeight: FontWeight.w600, fontSize: 12);
            }
            return const TextStyle(color: Colors.grey, fontSize: 12);
          }),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryNavy,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryNavy,
            side: const BorderSide(color: primaryNavy),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: primaryNavy, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        cardTheme: CardThemeData(
          color: surfaceOffWhite,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/privacy-policy': (context) => const LegalScreen(),
        '/terms': (context) => const LegalScreen(),
      },
    );
  }
}

// ==========================================
// MAIN NAVIGATION SCREEN
// ==========================================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  String? _pendingChatContext;

  @override
  void initState() {
    super.initState();
    userProfileNotifier.loadProfile();
  }

  void _jumpToChatWithContext(String contextText) {
    setState(() {
      _pendingChatContext = contextText;
      _currentIndex = 3;
    });
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of Namma-Appeal?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await Supabase.instance.client.auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      ScannerScreen(onChatTriggered: _jumpToChatWithContext),
      NewRtiScreen(onChatTriggered: _jumpToChatWithContext),
      HistoryScreen(onChatTriggered: _jumpToChatWithContext),
      ChatScreen(
        initialContext: _pendingChatContext,
        onContextConsumed: () => setState(() => _pendingChatContext = null),
      ),
      ProfileScreen(),
    ];

    final List<String> titles = [
      "Namma-Appeal Scanner",
      "Draft New RTI",
      "Analysis History",
      "Legal Assistant",
      "My Profile",
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            tooltip: 'Active Reminders',
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const RemindersScreen())
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => _confirmSignOut(context),
          )
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.document_scanner), label: 'Scanner'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'New RTI'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Assistant'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

// ==========================================
// NEW RTI SCREEN
// ==========================================
class NewRtiScreen extends StatefulWidget {
  final Function(String)? onChatTriggered;
  const NewRtiScreen({super.key, this.onChatTriggered});

  @override
  State<NewRtiScreen> createState() => _NewRtiScreenState();
}

class _NewRtiScreenState extends State<NewRtiScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isStreaming = false;
  String _generatedDraft = "";
  bool _isDraftSuccessful = false;
  Uint8List? _selectedImageBytes;

  String _selectedLanguage = 'English';
  final List<String> _languages = [
    'English', 'Hindi', 'Tamil', 'Telugu', 'Malayalam',
    'Kannada', 'Marathi', 'Bengali', 'Gujarati', 'Punjabi', 'Odia'
  ];

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  String _selectedPio = 'Auto-Detect (AI decides)';
  final List<String> _pioList = [
    'Auto-Detect (AI decides)',
    'PIO, Greater Chennai Corporation, Ripon Building',
    'PIO, Chennai Metropolitan Development Authority (CMDA)',
    'PIO, Chennai Metro Water (CMWSSB), Chintadripet',
    'PIO, TANGEDCO (Electricity Board), Anna Salai',
    'PIO, Tamil Nadu Police Headquarters, Mylapore',
    'PIO, Regional Transport Office (RTO)',
    'PIO, Tamil Nadu Public Service Commission (TNPSC)',
    'PIO, Southern Railway Headquarters, Chennai',
    'PIO, Reserve Bank of India (RBI), Chennai',
    'PIO, Prime Minister\'s Office (PMO), New Delhi',
    'PIO, Election Commission of India, New Delhi',
    'PIO, Ministry of Road Transport & Highways (MoRTH)',
    'PIO, Employees\' Provident Fund Organisation (EPFO)',
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
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
          onResult: (result) => setState(() => _promptController.text = result.recognizedWords),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied or unsupported.')));
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      final bytes = await photo.readAsBytes();
      setState(() => _selectedImageBytes = bytes);
    }
  }

  Future<void> _generateNewRti() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection.'), backgroundColor: Colors.red),
      );
      return;
    }
    // Triggers a subtle, premium vibration
    HapticFeedback.lightImpact();

    String textInput = _promptController.text.trim();
    if (textInput.isEmpty && _selectedImageBytes == null) {
      setState(() {
        _generatedDraft = "Please enter a description or take a photo of your grievance.";
        _isDraftSuccessful = false;
      });
      return;
    }

    final profile = userProfileNotifier.value;
    String profileBlock = '';
    if (profile != null) {
      final name = profile['full_name'] ?? '';
      final address = profile['address'] ?? '';
      final mobile = profile['mobile_number'] ?? '';
      final state = profile['state'] ?? '';
      if (name.isNotEmpty) {
        profileBlock = '\n\nAPPLICANT DETAILS (auto-filled from saved profile):\n'
            'Name: $name\nAddress: $address\nMobile: $mobile\nState: $state\n'
            'Use these details in the applicant block of the letter.';
      }
    }

    String pioInstruction = _selectedPio == 'Auto-Detect (AI decides)'
        ? "Determine the most appropriate Government Department/PIO address based on the grievance."
        : "Address the application explicitly to: $_selectedPio.";

    final now = DateTime.now();
    final formattedDate = "${now.day}/${now.month}/${now.year}";

    String systemInstructions = 
        "You are Namma-Appeal AI, a legal expert. Draft a highly detailed, formal Right to Information (RTI) application "
        "under Section 6(1) of the RTI Act, 2005. Use first-person ('I'). $pioInstruction\n"
        "Frame the requests as specific document or file notation requests, not vague questions. Be exhaustive and list at least 4-5 specific points.\n"
        "Ensure it includes an insurance clause for Section 6(3) internal transfer if applicable.\n\n"
        "CRITICAL FORMATTING INSTRUCTION: Write a continuous, traditional formal letter. DO NOT use markdown headers (like 'SUBJECT:', 'APPLICANT DETAILS:'). DO NOT use asterisks.\n\n"
        "CRITICAL ENDING INSTRUCTION: You MUST end the letter completely by writing this exact marker: [END OF DRAFT]. DO NOT write a fee statement, DO NOT write 'Sincerely', and DO NOT sign the letter. Stop exactly at [END OF DRAFT].\n\n"
        "CRITICAL DATE INSTRUCTION: The current real-world date is $formattedDate. You MUST use exactly this date ($formattedDate) at the top of the letter.\n\n"
        "CRITICAL WRITING INSTRUCTION: You are drafting a physical paper letter. The recipient cannot see what you see. You MUST describe the civic issue in your own words as if you witnessed it in person. FORBIDDEN WORDS: 'image', 'photo', 'photograph', 'picture', 'depicted', 'shown'. You will be penalized if you use any of these forbidden words.\n\n"
        "CRITICAL LANGUAGE INSTRUCTION: You MUST translate and write the entire final legal draft completely in $_selectedLanguage.";

    // --- UPDATED FALLBACK TEXT BELOW ---
    String userContent = "User Context/Grievance Description:\n${textInput.isNotEmpty ? textInput : 'Please describe the civic issue provided in the visual evidence thoroughly.'}\n$profileBlock";
        
    setState(() {
      _isStreaming = true;
      _isDraftSuccessful = false;
      _generatedDraft = "";
    });

    try {
      // 1. Prepare the payload
      final Map<String, dynamic> requestBody = {
        "model": _selectedImageBytes != null 
            ? "meta-llama/llama-4-scout-17b-16e-instruct" 
            : "llama-3.3-70b-versatile",
        "messages": [
          {"role": "system", "content": systemInstructions},
          {
            "role": "user",
            "content": _selectedImageBytes != null
                ? [
                    {"type": "text", "text": userContent},
                    {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,${base64Encode(_selectedImageBytes!)}"}}
                  ]
                : userContent
          }
        ],
        "temperature": 0.3,
      };

      // 2. Call the secure Edge Function instead of Groq
      final response = await Supabase.instance.client.functions.invoke(
        'groq-api',
        body: {'requestBody': requestBody},
      );

      if (response.status != 200) {
        throw Exception("Groq Edge Function Error: ${response.data}");
      }

      // 3. Supabase automatically parses JSON into a Dart Map
      final finalDraft = response.data['choices'][0]['message']['content'];

      String generatedId = "";
      try {
        final insertedRow = await Supabase.instance.client.from('scan_history').insert({
          'topic': 'New RTI Application ($_selectedLanguage)',
          'analysis_summary': 'Fresh RTI Application Draft in $_selectedLanguage',
          'full_draft': finalDraft,
          'user_id': Supabase.instance.client.auth.currentUser?.id,
        }).select('id').single(); 
        generatedId = insertedRow['id'].toString();
      } catch (dbError) {
        debugPrint("Failed to save draft to database: $dbError");
      }

      setState(() {
        _generatedDraft = finalDraft; 
        _isStreaming = false;
        _isDraftSuccessful = true;
      });

      if (mounted && generatedId.isNotEmpty) {
         _offerRtiReminder(finalDraft, 'New RTI Application ($_selectedLanguage)', generatedId);
      }
    } catch (e) {
      setState(() {
        _generatedDraft = "Error generating draft: $e";
        _isStreaming = false;
        _isDraftSuccessful = false;
      });
    }
  }

  Future<void> _offerRtiReminder(String draft, String topic, String targetRecordId) async {
    DateTime? filingDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: 'Did you file (or plan to file) this RTI? Pick the filing date to set reminders.',
      confirmText: 'Set Reminders',
      cancelText: 'Skip',
    );

    if (filingDate == null || !mounted) return;

    try {
      final ids = await ReminderService.scheduleRtiReminders(
        filingDate: filingDate,
        department: _selectedPio == 'Auto-Detect (AI decides)' ? 'the concerned department' : _selectedPio,
        topic: topic,
      );

      await Supabase.instance.client.from('scan_history').update({
        'filing_date': filingDate.toIso8601String(),
        'notification_ids': ids,
      }).eq('id', targetRecordId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Reminders set for Day 27 and Day 57!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Reminder error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final saffron = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      floatingActionButton: _generatedDraft.isNotEmpty && !_isStreaming && _isDraftSuccessful
          ? FloatingActionButton.extended(
              onPressed: () => widget.onChatTriggered!(_generatedDraft),
              icon: const Icon(Icons.chat),
              label: const Text("Discuss Draft"),
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: themeColor.withOpacity(0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedLanguage,
                        isExpanded: true,
                        icon: Icon(Icons.language, color: themeColor),
                        items: _languages.map((String lang) {
                          return DropdownMenuItem<String>(
                            value: lang,
                            child: Text(lang,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, color: themeColor, fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (newValue) => setState(() => _selectedLanguage = newValue!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueGrey.withOpacity(0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPio,
                        isExpanded: true,
                        icon: const Icon(Icons.account_balance, color: Colors.blueGrey),
                        items: _pioList.map((String pio) {
                          return DropdownMenuItem<String>(
                            value: pio,
                            child: Text(pio,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blueGrey,
                                    fontSize: 11),
                                overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (newValue) => setState(() => _selectedPio = newValue!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _promptController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Describe your grievance (e.g., 'The road hasn't been fixed for 6 months...')",
                suffixIcon: IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.red : themeColor, size: 28),
                  onPressed: _toggleListening,
                ),
              ),
            ),
            const SizedBox(height: 15),

            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Attach Photo"),
                ),
                const SizedBox(width: 15),
                if (_selectedImageBytes != null)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            Image.memory(_selectedImageBytes!, width: 60, height: 60, fit: BoxFit.cover),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _selectedImageBytes = null),
                        child: Container(
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            ValueListenableBuilder<Map<String, dynamic>?>(
              valueListenable: userProfileNotifier,
              builder: (context, profile, _) {
                if (profile == null || (profile['full_name'] ?? '').isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Chip(
                    avatar: Icon(Icons.person_outline, color: saffron, size: 18),
                    label: Text('Using your saved profile: ${profile['full_name']}',
                        style: TextStyle(fontSize: 12, color: themeColor)),
                    backgroundColor: saffron.withOpacity(0.1),
                    side: BorderSide(color: saffron.withOpacity(0.4)),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              onPressed: _isStreaming ? null : _generateNewRti,
              icon: _isStreaming
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: Text(_isStreaming ? "Drafting..." : "Generate Application"),
            ),

            const SizedBox(height: 30),

            if (_generatedDraft.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: themeColor.withOpacity(0.15))),
                child: MarkdownBody(
                  data: _generatedDraft,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(fontSize: 15, height: 1.5),
                    strong: const TextStyle(fontSize: 15, height: 1.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_isDraftSuccessful && !_isStreaming)
                if (_selectedLanguage == 'English')
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    onPressed: () => generateAndPrintPdf(_generatedDraft, context, isAppeal: false),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Generate Application PDF", style: TextStyle(fontSize: 16)),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.5)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            "PDF generation for regional languages requires custom font bundling, slated for App Version 2.0.",
                            style: TextStyle(color: Colors.deepOrange, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
            ]
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SCANNER SCREEN
// ==========================================
class ScannerScreen extends StatefulWidget {
  final Function(String)? onChatTriggered;
  const ScannerScreen({super.key, this.onChatTriggered});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isStreaming = false;
  String _resultText = "Scan a rejection letter to begin analysis.";
  String _fullAiResponse = "";

  Future<void> _scanDocument() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No internet connection.'), backgroundColor: Colors.red));
      return;
    }
    // Triggers a subtle, premium vibration
    HapticFeedback.lightImpact();
    setState(() {
      _isStreaming = true;
      _resultText = "";
      _fullAiResponse = "";
    });

    int retryCount = 0;
    const int maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final imageBytes = await photo.readAsBytes();
        final base64Image = base64Encode(imageBytes);
        // 1. First Call: Identify Topic via Edge Function
        final topicRequestBody = {
          "model": "meta-llama/llama-4-scout-17b-16e-instruct",
          "messages": [{
            "role": "user",
            "content": [
              {"type": "text", "text": "Identify the one-word legal topic of this RTI rejection (e.g. Language, Privacy, Security, Fee)."},
              {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,$base64Image"}}
            ]
          }]
        };

        final topicResponse = await Supabase.instance.client.functions.invoke(
          'groq-api',
          body: {'requestBody': topicRequestBody},
        );
        
        String topic = "General";
        if (topicResponse.status == 200) {
          topic = topicResponse.data['choices'][0]['message']['content'].trim();
        }

        // --- Fetch laws from database based on topic ---
        final response = await Supabase.instance.client
            .from('rti_laws')
            .select('content')
            .ilike('content', '%$topic%')
            .limit(3);

        final List<dynamic> laws = response as List<dynamic>;
        String lawContext = laws.map((e) => e['content'].toString()).join("\n\n");

        final now = DateTime.now();
        final formattedDate = "${now.day}/${now.month}/${now.year}";

        final profile = userProfileNotifier.value;
        String profileBlock = '';
        if (profile != null) {
          final name = profile['full_name'] ?? '';
          final address = profile['address'] ?? '';
          final mobile = profile['mobile_number'] ?? '';
          final state = profile['state'] ?? '';
          if (name.isNotEmpty) {
            profileBlock = '\n\nAPPELLANT DETAILS (auto-filled from saved profile):\n'
                'Name: $name\nAddress: $address\nMobile: $mobile\nState: $state\n'
                'Use these details explicitly in the signature and appellant block of the letter.';
          }
        }

        String systemInstructions = 
          "You are Namma-Appeal AI, a constitutional law and RTI activist expert. Analyze the user's letter using this legal context:\n$lawContext\n\n"
          "1. Start with a clean, Markdown-formatted analysis overview: 'As Namma-Appeal AI, I have analyzed your letter...'\n"
          "2. Provide 3 specific legal bullet points explaining why the rejection violates the provisions of the RTI Act, 2005.\n"
          "3. You MUST insert this EXACT marker as a separator between the analysis and the letter: [DRAFT_START]\n"
          "4. Below the separator, write a complete, structurally sound formal First Appeal letter under Section 19(1) of the RTI Act.\n\n"
          "CRITICAL FORMATTING INSTRUCTION: For the draft below the separator, write a continuous formal letter. DO NOT use bold headers or asterisks.\n\n"
          "CRITICAL ENDING INSTRUCTION: You MUST end the draft completely by writing this exact marker: [END OF DRAFT]. DO NOT write a fee statement, DO NOT write 'Yours faithfully', and DO NOT sign the letter. Stop exactly at [END OF DRAFT].\n\n"
          "CRITICAL DATE INSTRUCTION: The current date is $formattedDate. You MUST use exactly this date in the date block of the appeal letter.\n\n"
          "CRITICAL WRITING INSTRUCTION: The appeal letter will be printed on plain paper. You MUST refer to the rejected document neutrally as 'the rejection order issued by the PIO'. FORBIDDEN WORDS: 'scan', 'upload', 'photo', 'image', 'photograph'. You will be penalized if you use these words in the appeal draft.\n\n"
          "Use first-person ('I') throughout the letter text.";

        String userContent = "Please analyze the attached rejection order.$profileBlock";

        // 2. Second Call: Full Analysis via Edge Function
        final analysisRequestBody = {
          "model": "meta-llama/llama-4-scout-17b-16e-instruct",
          "messages": [
            {"role": "system", "content": systemInstructions},
            {
              "role": "user",
              "content": [
                {"type": "text", "text": userContent}, 
                {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,$base64Image"}}
              ]
            }
          ]
        };

        final analysisResponse = await Supabase.instance.client.functions.invoke(
          'groq-api',
          body: {'requestBody': analysisRequestBody},
        );

        if (analysisResponse.status != 200) throw Exception(analysisResponse.data);

        final finalAiText = analysisResponse.data['choices'][0]['message']['content'];
        
        // --- UPDATED SPLIT LOGIC ---
        String displaySummary = finalAiText;
        if (finalAiText.contains('[DRAFT_START]')) {
          displaySummary = finalAiText.split('[DRAFT_START]')[0].trim();
        } else if (finalAiText.contains('---DRAFT START---')) {
          displaySummary = finalAiText.split('---DRAFT START---')[0].trim();
        } else if (finalAiText.toLowerCase().contains('# draft')) {
          displaySummary = finalAiText.toLowerCase().split('# draft')[0].trim();
        }
        String generatedId = "";
        
        try {
          final insertedRow = await Supabase.instance.client.from('scan_history').insert({
            'topic': topic,
            'analysis_summary': displaySummary,
            'full_draft': finalAiText,
            'user_id': Supabase.instance.client.auth.currentUser?.id,
          }).select('id').single(); 
          generatedId = insertedRow['id'].toString();
        } catch (dbError) {
          debugPrint("Failed to save history: $dbError");
        }

        setState(() {
          _fullAiResponse = finalAiText;
          _resultText = displaySummary;
          _isStreaming = false;
        });

        if (mounted && generatedId.isNotEmpty) {
           _offerRtiReminder(finalAiText, topic, generatedId);
        }
        return;
      } catch (e) {
        if (e.toString().contains("503") && retryCount < maxRetries - 1) {
          retryCount++;
          await Future.delayed(Duration(seconds: retryCount * 5));
        } else {
          setState(() {
            _resultText = "Error: $e";
            _isStreaming = false;
          });
          break;
        }
      }
    }
  }

  Future<void> _offerRtiReminder(String draft, String topic, String targetRecordId) async {
    DateTime? filingDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: 'Did you file this RTI? Pick the filing date to set reminders.',
      confirmText: 'Set Reminders',
      cancelText: 'Skip',
    );

    if (filingDate == null || !mounted) return;

    try {
      final ids = await ReminderService.scheduleRtiReminders(
        filingDate: filingDate,
        department: 'the concerned department',
        topic: topic,
      );

      await Supabase.instance.client.from('scan_history').update({
        'filing_date': filingDate.toIso8601String(),
        'notification_ids': ids,
      }).eq('id', targetRecordId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Reminders set for Day 27 and Day 57!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Reminder error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      floatingActionButton: _fullAiResponse.isNotEmpty && !_isStreaming
          ? FloatingActionButton.extended(
              onPressed: () => widget.onChatTriggered!(_fullAiResponse),
              icon: const Icon(Icons.chat),
              label: const Text("Discuss with AI"),
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset('assets/page_icon_custom.png',
                  width: 90, height: 90, fit: BoxFit.cover),
            ),
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: themeColor.withOpacity(0.15)),
              ),
              child: MarkdownBody(
                data: _resultText.isEmpty
                    ? "Scan a rejection letter to begin analysis."
                    : _resultText,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 16, height: 1.5),
                  strong: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.bold),
                  listBullet: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            if (_isStreaming)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: themeColor)),
                    const SizedBox(width: 8),
                    Text('Analyzing...', style: TextStyle(color: themeColor, fontSize: 12)),
                  ],
                ),
              ),

            const SizedBox(height: 40),

            ElevatedButton.icon(
              onPressed: _isStreaming ? null : _scanDocument,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              icon: const Icon(Icons.camera_alt),
              label: const Text("Scan RTI Rejection", style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 15),

            if (_fullAiResponse.isNotEmpty && !_isStreaming)
              OutlinedButton.icon(
                onPressed: () => generateAndPrintPdf(_fullAiResponse, context, isAppeal: true),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Generate Appeal PDF", style: TextStyle(fontSize: 18)),
              ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// HISTORY SCREEN
// ==========================================
class HistoryScreen extends StatelessWidget {
  final Function(String)? onChatTriggered;
  const HistoryScreen({super.key, this.onChatTriggered});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('scan_history')
            .stream(primaryKey: ['id']).order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              itemCount: 5, // Show 5 fake loading rows
              itemBuilder: (context, index) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.white),
                      title: Container(height: 14, color: Colors.white),
                      subtitle: Container(height: 10, width: 100, color: Colors.white, margin: const EdgeInsets.only(top: 8, right: 100)),
                    ),
                  ),
                );
              },
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 15),
                  const Text("You are offline.",
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 8),
                  const Text("Please connect to the internet to view your history.",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No past scans found."));
          }

          final history = snapshot.data!;
          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              final dateStr = item['created_at'] != null
                  ? DateTime.parse(item['created_at']).toLocal().toString().split('.')[0]
                  : 'Unknown Date';
              final String topic = item['topic'] ?? 'General';
              final bool hasReminder = item['filing_date'] != null &&
                  (item['notification_ids'] as List?)?.isNotEmpty == true;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.history_edu,
                          color: Theme.of(context).colorScheme.primary),
                      if (hasReminder)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.calendar_today,
                                size: 8, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  title: Text("Topic: $topic"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateStr),
                      if (hasReminder)
                        Text(
                          'Reminder active · Filed: ${item['filing_date']?.toString().split('T')[0] ?? ''}',
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onLongPress: hasReminder
                      ? () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Cancel Reminder'),
                              content: const Text(
                                  'Do you want to cancel the RTI deadline reminders for this item?'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Keep')),
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Cancel Reminders',
                                        style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final ids = item['notification_ids'] as List?;
                            if (ids != null) {
                              for (final id in ids) {
                                await ReminderService.cancelReminder(id as int);
                              }
                            }
                            await Supabase.instance.client
                                .from('scan_history')
                                .update({'filing_date': null, 'notification_ids': null}).eq(
                                    'id', item['id']);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Reminders cancelled.')));
                            }
                          }
                        }
                      : null,
                  onTap: () {
                    final bool isRegional =
                        topic.contains('(Tamil)') || topic.contains('(Hindi)');
                    final bool isAnAppeal = !topic.contains('New RTI Application');

                    // Inside HistoryScreen onTap:
                    String displayContent = item['full_draft'] ?? "No content available.";
                    
                    // --- UPDATED SPLIT LOGIC ---
                    if (displayContent.contains('[DRAFT_START]')) {
                      displayContent = displayContent.split('[DRAFT_START]')[1].trim();
                    } else if (displayContent.contains('---DRAFT START---')) {
                      displayContent = displayContent.split('---DRAFT START---')[1].trim();
                    } else if (displayContent.toLowerCase().contains('# draft')) {
                      displayContent = displayContent.substring(displayContent.toLowerCase().indexOf('# draft')).trim();
                      displayContent = displayContent.split('\n').skip(1).join('\n').trim();
                    }

                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(isAnAppeal ? "Appeal Analysis" : "RTI Draft"),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("AI Summary:",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary)),
                                const SizedBox(height: 5),
                                MarkdownBody(
                                  data: item['analysis_summary'] ?? "Analyzing...",
                                  styleSheet: MarkdownStyleSheet(
                                    p: const TextStyle(fontSize: 14, height: 1.4),
                                    strong: const TextStyle(
                                        fontSize: 14,
                                        height: 1.4,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const Divider(height: 30),
                                Text(
                                    isAnAppeal
                                        ? "Generated Appeal:"
                                        : "Generated Application:",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary)),
                                const SizedBox(height: 10),
                                MarkdownBody(
                                  data: displayContent,
                                  selectable: true,
                                  styleSheet: MarkdownStyleSheet(
                                    p: const TextStyle(fontSize: 14, height: 1.5),
                                    strong: const TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (isRegional) ...[
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.orange.withOpacity(0.5)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.info_outline,
                                            color: Colors.orange, size: 18),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Regional PDF generation is slated for App Version 2.0.",
                                            style: TextStyle(
                                                color: Colors.deepOrange, fontSize: 11),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ]
                              ],
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Close")),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              onChatTriggered!(
                                  item['full_draft'] ?? item['analysis_summary'] ?? "");
                            },
                            icon: const Icon(Icons.chat_bubble_outline, size: 16),
                            label: const Text("Ask AI"),
                          ),
                          if (!isRegional)
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                generateAndPrintPdf(item['full_draft'] ?? "", context,
                                    isAppeal: isAnAppeal);
                              },
                              icon: const Icon(Icons.picture_as_pdf, size: 16),
                              label: const Text("Get PDF"),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// REUSABLE DYNAMIC PDF GENERATOR
// ==========================================
// ==========================================
// REUSABLE DYNAMIC PDF GENERATOR
// ==========================================
Future<void> generateAndPrintPdf(
  String fullAiResponse,
  BuildContext context, {
  bool isAppeal = true,
}) async {
  try {
    if (fullAiResponse.isEmpty) return;

    final profile = userProfileNotifier.value;
    final applicantName = profile?['full_name'] ?? '';

    final pdf = pw.Document();

    // 1. BULLETPROOF SPLIT: Handle Llama's markdown variations
    // 1. BULLETPROOF SPLIT: Handle Llama's markdown variations
    String draftPart = fullAiResponse;
    if (draftPart.contains('[DRAFT_START]')) {
      draftPart = draftPart.split('[DRAFT_START]').last;
    } else if (draftPart.contains('---DRAFT START---')) {
      draftPart = draftPart.split('---DRAFT START---').last;
    } else if (draftPart.toLowerCase().contains('# draft')) {
      // Aggressive fallback: slice at the markdown header and delete the header line itself
      draftPart = fullAiResponse.substring(fullAiResponse.toLowerCase().indexOf('# draft')).trim();
      draftPart = draftPart.split('\n').skip(1).join('\n');
    }
    draftPart = draftPart.trim();

    // 2. BULLETPROOF ENDING: Slice at the hard stop marker
    if (draftPart.contains('[END OF DRAFT]')) {
      draftPart = draftPart.split('[END OF DRAFT]').first.trim();
    }

    // 3. AGGRESSIVE CLEANUP FALLBACK
    final lowerDraft = draftPart.toLowerCase();
    int cutoffIndex = draftPart.length;
    final stopPhrases = [
      'sincerely', 'yours faithfully', 'thanking you', 'yours truly',
      'i am attaching an indian postal', 'i am attaching a demand', 'enclosed is'
    ];
    for (String phrase in stopPhrases) {
      int index = lowerDraft.indexOf(phrase);
      if (index != -1 && index < cutoffIndex) cutoffIndex = index;
    }
    draftPart = draftPart.substring(0, cutoffIndex).trim();

    // 4. CLEAN INJECTION: Broken into multi-line to prevent PDF wrapping scrambles
    if (isAppeal) {
      draftPart += "\n\nEnclosed: Indian Postal Order / Demand Draft No. __________________\nAmount: Towards requisite appeal processing fees.\n\nThanking you,\nYours faithfully,\n($applicantName)\nAppellant";
    } else {
      draftPart += "\n\nEnclosed: Indian Postal Order / Demand Draft No. __________________\nAmount: Rs. 10/- towards the application fee.\n\nSincerely,\n($applicantName)";
    }

    final paragraphs = draftPart.split('\n');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            ...paragraphs
                .map((para) => para.trim())
                .where((para) => para.isNotEmpty && para != "---")
                .map((para) {
              
              bool isHeading = para.contains(":") || 
                               para.startsWith("**") || 
                               para.startsWith("To") || 
                               para.startsWith("Subject") ||
                               para.startsWith("APPLICATION") ||
                               para.startsWith("FIRST APPEAL");
                               
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(
                  para.replaceAll("**", "").trim(),
                  style: pw.TextStyle(
                    fontSize: isHeading ? 12 : 11,
                    fontWeight: isHeading ? pw.FontWeight.bold : pw.FontWeight.normal,
                  ),
                ),
              );
            }),
          ];
        },
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: isAppeal ? 'RTI_Appeal_Formal.pdf' : 'New_RTI_Application.pdf',
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF Error: $e")));
  }
}

// ==========================================
// REMINDERS DASHBOARD SCREEN
// ==========================================
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  Timer? _timer;
  
  late Stream<List<Map<String, dynamic>>> _remindersStream;

  @override
  void initState() {
    super.initState();
    
    _remindersStream = Supabase.instance.client
        .from('scan_history')
        .stream(primaryKey: ['id']).order('filing_date', ascending: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cancelReminder(BuildContext context, Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Reminder'),
        content: const Text('Are you sure you want to cancel the deadline reminders for this RTI?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancel Reminders', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      final ids = item['notification_ids'] as List?;
      if (ids != null) {
        for (final id in ids) {
          await ReminderService.cancelReminder(id as int);
        }
      }
      await Supabase.instance.client
          .from('scan_history')
          .update({'filing_date': null, 'notification_ids': null}).eq('id', item['id']);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminders cancelled successfully.'), backgroundColor: Colors.green));
      }
    }
  }

  Widget _buildTimelineRow(String label, DateTime date, bool isPassed, Color activeColor) {
    return Row(
      children: [
        Icon(
          isPassed ? Icons.check_circle : Icons.schedule,
          color: isPassed ? Colors.green : activeColor,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Text(
          "${date.day}/${date.month}/${date.year}",
          style: TextStyle(
            color: isPassed ? Colors.grey : Colors.black87,
            decoration: isPassed ? TextDecoration.lineThrough : null,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Deadlines'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _remindersStream, 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              itemCount: 5, // Show 5 fake loading rows
              itemBuilder: (context, index) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.white),
                      title: Container(height: 14, color: Colors.white),
                      subtitle: Container(height: 10, width: 100, color: Colors.white, margin: const EdgeInsets.only(top: 8, right: 100)),
                    ),
                  ),
                );
              },
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(themeColor);
          }

          final activeReminders = snapshot.data!
              .where((item) => item['filing_date'] != null && (item['notification_ids'] as List?)?.isNotEmpty == true)
              .toList();

          if (activeReminders.isEmpty) {
            return _buildEmptyState(themeColor);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeReminders.length,
            itemBuilder: (context, index) {
              final item = activeReminders[index];
              final String topic = item['topic'] ?? 'RTI Application';
              final DateTime filingDate = DateTime.parse(item['filing_date']).toLocal();
              
              final DateTime day27 = filingDate.add(const Duration(days: 27)); 
              final DateTime day57 = filingDate.add(const Duration(days: 57)); 
              final DateTime now = DateTime.now();

              bool isDay27Passed = now.isAfter(day27);
              bool isDay57Passed = now.isAfter(day57);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              topic,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: themeColor),
                            ),
                          ),
                          InkWell(
                            onTap: () => _cancelReminder(context, item),
                            child: const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Icon(Icons.cancel, color: Colors.redAccent, size: 22),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text("Filed on: ${filingDate.day}/${filingDate.month}/${filingDate.year}",
                          style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      _buildTimelineRow("Day 27 Follow-up", day27, isDay27Passed, Colors.orange),
                      const SizedBox(height: 8),
                      _buildTimelineRow("Day 57 Appeal Deadline", day57, isDay57Passed, Colors.red),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(Color themeColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 70, color: themeColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text("No active deadlines.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 8),
          const Text("Generate an RTI and set a filing date to track it here.",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}