import 'dart:ui';
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
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dashboard_screen.dart'; 
import 'templates_screen.dart';
import 'polisher_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
// ==========================================
// USER PROFILE NOTIFIER
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
    requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true,
  );
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: androidInit, iOS: iosInit),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  await Supabase.initialize(url: Secrets.supabaseUrl, anonKey: Secrets.supabaseAnonKey);

  runApp(const NammaAppealApp());
}

// ==========================================
// SAAS THEME: PREMIUM ROYAL BLUE GLASSMORPHISM
// ==========================================
const kRoyalBlue = Color(0xFF2563EB);
const kBackgroundOffWhite = Color(0xFFF8FAFC);
const kTextSlate = Color(0xFF1E293B);
const kTextSecondary = Color(0xFF64748B);
const kSuccessEmerald = Color(0xFF10B981);
const kWarningAmber = Color(0xFFF59E0B);
const kRejectedRed = Color(0xFFEF4444);

class NammaAppealApp extends StatelessWidget {
  const NammaAppealApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Namma-Appeal Enterprise',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.transparent, // Transparent to show glowing orbs
        primaryColor: kRoyalBlue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kRoyalBlue,
          primary: kRoyalBlue,
          surface: kBackgroundOffWhite,
          onPrimary: Colors.white,
          onSurface: kTextSlate,
        ),
        textTheme: baseTextTheme.copyWith(
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: kTextSlate),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: kTextSlate),
          titleLarge: baseTextTheme.titleLarge?.copyWith(color: kTextSlate, fontWeight: FontWeight.w600),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kRoyalBlue,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: kRoyalBlue.withOpacity(0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
          ),
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
// ENTERPRISE DASHBOARD LAYOUT (Sidebar + TopNav)
// ==========================================
// ==========================================
// ENTERPRISE DASHBOARD LAYOUT (Sidebar + TopNav)
// ==========================================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  String? _pendingChatContext;
  String? _prefilledTemplate;
  final TextEditingController _searchController = TextEditingController();
  String _historyFilter = 'All';
  String _searchQuery = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // ── NEW ──
  // ── NEW VARIABLES FOR LIVE DROPDOWN ──
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _searchLayerLink = LayerLink();
  OverlayEntry? _searchOverlayEntry;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    userProfileNotifier.loadProfile();
    
    // Automatically close the dropdown if the user clicks away
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        // ── ADDED DELAY: Gives the onTap a split second to fire before destroying the widget ──
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && !_searchFocusNode.hasFocus) {
            _removeSearchOverlay();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _removeSearchOverlay();
    _searchFocusNode.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── LIVE DROPDOWN LOGIC ──
  void _removeSearchOverlay() {
    _searchOverlayEntry?.remove();
    _searchOverlayEntry = null;
  }

  void _onSearchChanged(String value) {
    if (value.isEmpty) {
      _removeSearchOverlay();
      if (_searchQuery.isNotEmpty) {
        setState(() => _searchQuery = '');
      }
      return;
    }

    // Debounce prevents spamming your database on every single keystroke
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final response = await Supabase.instance.client
            .from('scan_history')
            .select('topic')
            .ilike('topic', '%$value%')
            .limit(5);

        if (!mounted) return;

        final List<dynamic> results = response;
        if (results.isEmpty) {
          _removeSearchOverlay();
          return;
        }

        // Remove duplicates and show the overlay
        final uniqueTopics = results.map((e) => e['topic'].toString()).toSet().toList();
        _showSearchOverlay(uniqueTopics);
      } catch (e) {
        debugPrint("Live search error: $e");
      }
    });
  }

  void _showSearchOverlay(List<String> results) {
    _removeSearchOverlay();

    final isDesktop = MediaQuery.of(context).size.width > 850;

    _searchOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: isDesktop ? 260 : 140,
        child: CompositedTransformFollower(
          link: _searchLayerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 52), // Drops down right below the search bar
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [BoxShadow(color: kTextSlate.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final topic = results[index];
                      return InkWell(
                        hoverColor: kRoyalBlue.withOpacity(0.08),
                        onTap: () {
                          _searchController.text = topic;
                          _searchFocusNode.unfocus();
                          _removeSearchOverlay();
                          
                          // Jump directly to history with the selected item
                          setState(() {
                            _searchQuery = topic;
                            _currentIndex = 5; 
                            _historyFilter = 'All';
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.history, size: 16, color: kRoyalBlue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  topic,
                                  style: const TextStyle(fontSize: 13, color: kTextSlate, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_searchOverlayEntry!);
  }

  void _jumpToChatWithContext(String contextText) {
    setState(() {
      _pendingChatContext = contextText;
      _currentIndex = 6;
    });
  }

  void _navigateToIndex(int index, [String? templateText, String? filter]) {
    setState(() {
      _currentIndex = index;
      if (templateText != null) {
        _prefilledTemplate = templateText;
      }
      if (filter != null) {
        _historyFilter = filter;
      } else if (index == 5) {
        _historyFilter = 'All'; 
      }
    });
  }

  Future<void> _confirmSignOut() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: TextStyle(color: kTextSlate, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out of Namma-Appeal?', style: TextStyle(color: kTextSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel', style: TextStyle(color: kTextSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kRejectedRed, shadowColor: kRejectedRed.withOpacity(0.4)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm == true) await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 850; // ── RESPONSIVE BREAKPOINT ──
    
    final List<Widget> screens = [
      DashboardOverviewScreen(onNavigate: _navigateToIndex), 
      NewRtiScreen(onChatTriggered: _jumpToChatWithContext, initialPrompt: _prefilledTemplate, onNavigate: _navigateToIndex), 
      TemplatesScreen(onNavigate: _navigateToIndex),         
      PolisherScreen(onChatTriggered: _jumpToChatWithContext, onNavigate: _navigateToIndex, initialText: _prefilledTemplate), 
      ScannerScreen(onChatTriggered: _jumpToChatWithContext),
      HistoryScreen(onChatTriggered: _jumpToChatWithContext, initialFilter: _historyFilter, searchQuery: _searchQuery), 
      ChatScreen(
        initialContext: _pendingChatContext, 
        onContextConsumed: () => setState(() => _pendingChatContext = null),
        onNavigate: _navigateToIndex, // ── PASS THE NAVIGATOR ──
      ), 
      const ProfileScreen(),                                 
    ];

    final List<String> titles = [
      "Dashboard Overview", "Draft Application", "Template Library", "AI Document Polisher",
      "Rejection Scanner", "RTI History & Tracking", "Legal Co-Pilot", "Settings & Profile"
    ];

    return Scaffold(
      key: _scaffoldKey, // ── ATTACH KEY ──
      backgroundColor: kBackgroundOffWhite,
      // ── ONLY SHOW DRAWER ON MOBILE ──
      drawer: !isDesktop ? Drawer(backgroundColor: Colors.transparent, elevation: 0, child: _buildGlassSidebar(isMobile: true)) : null,
      body: Stack(
        children: [
          Positioned(top: -150, left: -100, child: Container(width: 500, height: 500, decoration: BoxDecoration(shape: BoxShape.circle, color: kRoyalBlue.withOpacity(0.12))).blurred(80)),
          Positioned(bottom: -200, right: -100, child: Container(width: 600, height: 600, decoration: BoxDecoration(shape: BoxShape.circle, color: kRoyalBlue.withOpacity(0.08))).blurred(100)),
          _buildBackgroundDoodles(),
          Row(
            children: [
              if (isDesktop) _buildGlassSidebar(), // ── HIDE IN-LINE SIDEBAR ON MOBILE ──
              Expanded(
                child: Column(
                  children: [
                    _buildTopNav(titles[_currentIndex], isDesktop),
                    Expanded(child: ClipRRect(borderRadius: const BorderRadius.only(topLeft: Radius.circular(24)), child: screens[_currentIndex])),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildBackgroundDoodles() {
    return const AnimatedDoodleBackground();
  }

  Widget _buildGlassSidebar({bool isMobile = false}) {
    return Container(
      width: isMobile ? double.infinity : 280, // Expand fully if inside mobile drawer
      margin: isMobile ? EdgeInsets.zero : const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
        boxShadow: [BoxShadow(color: kTextSlate.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(24, isMobile ? 60 : 32, 24, 40), // More top padding for mobile status bar
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [kRoyalBlue, kRoyalBlue.withOpacity(0.7)]), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.balance, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Text('Namma-Appeal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kTextSlate, letterSpacing: -0.5)),
                    if (isMobile) const Spacer(),
                    if (isMobile) IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)) // Close Drawer
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSidebarItem(Icons.space_dashboard_rounded, 'Overview', 0, isMobile),
                      _buildSidebarItem(Icons.note_add_rounded, 'Draft New RTI', 1, isMobile),
                      _buildSidebarItem(Icons.library_books_rounded, 'Templates', 2, isMobile),
                      _buildSidebarItem(Icons.auto_fix_high, 'Polish Existing Letter', 3, isMobile),
                      _buildSidebarItem(Icons.document_scanner_rounded, 'Rejection Scanner', 4, isMobile),
                      _buildSidebarItem(Icons.folder_copy_rounded, 'History & Tracking', 5, isMobile),
                      _buildSidebarItem(Icons.auto_awesome, 'Legal Co-Pilot', 6, isMobile),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16), child: Divider(color: Colors.black12)),
                      _buildSidebarItem(Icons.settings_rounded, 'Settings & Profile', 7, isMobile),
                    ],
                  ),
                ),
              ),
              // Bottom Profile
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.8))),
                  child: Row(
                    children: [
                      CircleAvatar(backgroundColor: kRoyalBlue.withOpacity(0.1), radius: 18, child: const Icon(Icons.person, color: kRoyalBlue, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ValueListenableBuilder<Map<String, dynamic>?>(
                          valueListenable: userProfileNotifier,
                          builder: (_, profile, __) => Text(profile?['full_name']?.isNotEmpty == true ? profile!['full_name'] : 'User', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kTextSlate), overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.logout, size: 18, color: kTextSecondary), onPressed: _confirmSignOut),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, int index, bool isMobile) {
    final isSelected = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          setState(() => _currentIndex = index);
          if (isMobile) Navigator.pop(context); // Close drawer after selection
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? kRoyalBlue.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? kRoyalBlue.withOpacity(0.2) : Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? kRoyalBlue : kTextSecondary, size: 22),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? kRoyalBlue : kTextSecondary))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopNav(String title, bool isDesktop) {
    return SafeArea(
      bottom: false, // ── PUSHES UI BELOW THE MOBILE STATUS BAR ──
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 12, vertical: isDesktop ? 20 : 12),
        child: Row(
          children: [
            // ── HAMBURGER MENU & TITLE ──
            if (!isDesktop) ...[
              IconButton(
                icon: const Icon(Icons.menu, color: kTextSlate), 
                onPressed: () => _scaffoldKey.currentState?.openDrawer()
              ),
              const SizedBox(width: 4),
            ],
            // ── EXPANDED PREVENTS TEXT FROM COLLIDING WITH SEARCH BAR ──
            Expanded(
              child: Text(
                isDesktop ? title : title.split(" ")[0], 
                style: TextStyle(fontSize: isDesktop ? 24 : 18, fontWeight: FontWeight.w700, color: kTextSlate, letterSpacing: -0.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // ── SEARCH BAR & NOTIFICATION BELL ──
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CompositedTransformTarget(
                  link: _searchLayerLink,
                  child: Container(
                    width: isDesktop ? 260 : 140, 
                    height: 44,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white)),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: const TextStyle(fontSize: 14, color: kTextSlate),
                      decoration: InputDecoration(
                        hintText: isDesktop ? 'Search RTIs...' : 'Search...',
                        hintStyle: TextStyle(color: kTextSecondary.withOpacity(0.7), fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: kTextSecondary, size: 18),
                        suffixIcon: _searchQuery.isNotEmpty || _searchController.text.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.clear, size: 16, color: kTextSecondary), onPressed: () { _searchController.clear(); _removeSearchOverlay(); setState(() => _searchQuery = ''); })
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onChanged: _onSearchChanged,
                      onSubmitted: (value) { _removeSearchOverlay(); setState(() { _searchQuery = value.trim(); if (_searchQuery.isNotEmpty) { _currentIndex = 5; _historyFilter = 'All'; } }); },
                    ),
                  ),
                ),
                SizedBox(width: isDesktop ? 16 : 8),
                Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.8)),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen())),
                      child: const Padding(padding: EdgeInsets.all(10), child: Badge(backgroundColor: kRoyalBlue, child: Icon(Icons.notifications_none_rounded, color: kTextSlate, size: 22))),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
// ── Reusable Extension for Blur ──
extension BlurExtension on Widget {
  Widget blurred(double sigma) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: this,
    );
  }
}

// ==========================================
// REUSABLE PREMIUM GLASS CARD
// ==========================================
class PremiumGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const PremiumGlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(24)});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(color: kTextSlate.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

// ==========================================
// NEW RTI SCREEN (WITH SMART ROUTING)
// ==========================================
class NewRtiScreen extends StatefulWidget {
  final Function(String)? onChatTriggered;
  final String? initialPrompt;
  final Function(int, [String?])? onNavigate;

  const NewRtiScreen({super.key, this.onChatTriggered, this.initialPrompt, this.onNavigate});

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
    if (widget.initialPrompt != null) {
      _promptController.text = widget.initialPrompt!;
    }
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No internet connection.'), backgroundColor: Colors.red));
      return;
    }
    
    String textInput = _promptController.text.trim();
    if (textInput.isEmpty && _selectedImageBytes == null) {
      setState(() { _generatedDraft = "Please enter a description or attach a photo."; _isDraftSuccessful = false; });
      return;
    }

    HapticFeedback.lightImpact();
    setState(() { _isStreaming = true; _isDraftSuccessful = false; _generatedDraft = ""; });

    // ── SMART INTENT CLASSIFIER ──
    if (textInput.isNotEmpty && _selectedImageBytes == null) {
      try {
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
          final data = classRes.data;
          if (data is Map && data.containsKey('choices') && data['choices'] != null && (data['choices'] as List).isNotEmpty) {
            String intent = data['choices'][0]['message']['content'].toString().trim().toUpperCase();
            if (intent.contains('LETTER')) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This is already a letter! Routing you to the Polisher...'), backgroundColor: Color(0xFFF59E0B)));
              if (widget.onNavigate != null) widget.onNavigate!(3, textInput); 
              return;
            } else if (intent.contains('QUESTION')) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This is a question! Routing you to the Legal Co-Pilot...'), backgroundColor: kRoyalBlue));
              if (widget.onChatTriggered != null) widget.onChatTriggered!(textInput);
              return;
            }
          }
        }
      } catch (e) {
        debugPrint("Classifier error: $e"); 
      }
    }

    // ── IF IT IS A GRIEVANCE, PROCEED WITH GEMINI GENERATION ──
    final profile = userProfileNotifier.value;
    String profileBlock = '';
    if (profile != null && profile['full_name']?.isNotEmpty == true) {
      profileBlock = '\n\nAPPLICANT DETAILS:\nName: ${profile['full_name']}\nAddress: ${profile['address']}\nMobile: ${profile['mobile_number']}\nState: ${profile['state']}';
    }

    String pioInstruction = _selectedPio == 'Auto-Detect (AI decides)' ? "Determine the most appropriate Government Department/PIO address." : "Address the application explicitly to: $_selectedPio.";
    final formattedDate = "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";

    String systemInstructions = 
        "You are Namma-Appeal AI, a legal expert. Draft a highly detailed, formal Right to Information (RTI) application "
        "under Section 6(1) of the RTI Act, 2005. Use first-person ('I'). $pioInstruction\n"
        "CRITICAL FORMATTING INSTRUCTION: Write a continuous, traditional formal letter. DO NOT use markdown headers or asterisks.\n"
        "CRITICAL ENDING INSTRUCTION: End completely with exactly: [END OF DRAFT]. DO NOT sign the letter.\n"
        "CRITICAL DATE: Use exactly $formattedDate at the top.\n"
        "Translate and write the entire final draft completely in $_selectedLanguage.";

    String userContent = "User Grievance Description:\n${textInput.isNotEmpty ? textInput : 'Describe civic issue in image.'}\n$profileBlock";
        
    try {
      final List<Map<String, dynamic>> messageParts = [{"text": userContent}];
      if (_selectedImageBytes != null) messageParts.add({"inlineData": {"mimeType": "image/jpeg", "data": base64Encode(_selectedImageBytes!)}});

      final response = await Supabase.instance.client.functions.invoke(
        'groq-api', body: {'targetApi': 'gemini', 'requestBody': {"systemInstruction": {"parts": [{"text": systemInstructions}]}, "contents": [{"role": "user", "parts": messageParts}]}},
      );

      if (response.status != 200) throw Exception(response.data);
      
      final data = response.data;
      if (data == null || data is! Map || !data.containsKey('candidates') || data['candidates'] == null || (data['candidates'] as List).isEmpty) {
        throw Exception("API returned an unexpected format. Raw response: $data");
      }

      final finalDraft = data['candidates'][0]['content']['parts'][0]['text'].toString();

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

      setState(() { _generatedDraft = finalDraft; _isStreaming = false; _isDraftSuccessful = true; });

      if (mounted && generatedId.isNotEmpty) _offerRtiReminder(finalDraft, 'New RTI Application ($_selectedLanguage)', generatedId);
    } catch (e) {
      setState(() { _generatedDraft = "Error generating draft: $e"; _isStreaming = false; _isDraftSuccessful = false; });
    }
  }

  Future<void> _polishDraft() async {
    final textInput = _promptController.text.trim();
    if (textInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please type a rough description first!'), backgroundColor: kWarningAmber),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isStreaming = true);

    try {
      final requestBody = {
        "model": "llama-3.3-70b-versatile",
        "messages": [
          {
            "role": "system",
            // ── UPDATED PROMPT: Strictly outputs a polished prompt, NOT a letter ──
            "content": "You are an expert editor and legal assistant. The user will provide a rough, emotional, or poorly worded description of a grievance, or a basic template prompt. Your job is to rewrite this into a highly professional, clear, and concise factual summary of the issue. This polished text will be used as a prompt to draft a letter later. \n\nCRITICAL INSTRUCTION: DO NOT write a formal letter. DO NOT include To/From addresses, Subject lines, or signatures. ONLY return the polished description of the problem and the specific points to ask for."
          },
          {
            "role": "user",
            "content": textInput
          }
        ],
        "temperature": 0.2,
      };

      final response = await Supabase.instance.client.functions.invoke(
        'groq-api',
        body: {'requestBody': requestBody},
      );

      if (response.status != 200) throw Exception(response.data);

      final data = response.data;
      if (data == null || data is! Map || !data.containsKey('choices') || data['choices'] == null || (data['choices'] as List).isEmpty) {
        throw Exception("API returned an unexpected format. Raw response: $data");
      }

      final polishedText = data['choices'][0]['message']['content'].toString().trim();

      setState(() {
        _promptController.text = polishedText;
        _isStreaming = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✨ Prompt professionally polished!'), backgroundColor: kSuccessEmerald),
        );
      }
    } catch (e) {
      setState(() => _isStreaming = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error polishing prompt: $e'), backgroundColor: kRejectedRed),
        );
      }
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

            // ── RESPONSIVE ACTION BUTTONS ──
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                
                final btnPolish = OutlinedButton.icon(
                  onPressed: _isStreaming ? null : _polishDraft,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: themeColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text("Refine Prompt", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                );
                
                final btnGenerate = ElevatedButton.icon(
                  onPressed: _isStreaming ? null : _generateNewRti,
                  style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(Icons.document_scanner),
                  label: const Text("Generate RTI", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                );

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      btnPolish,
                      const SizedBox(height: 16),
                      btnGenerate,
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(child: btnPolish),
                      const SizedBox(width: 16),
                      Expanded(child: btnGenerate),
                    ],
                  );
                }
              },
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
        
        // ── 1. First Call: Identify Topic via Gemini ──
        final topicRequestBody = {
          "contents": [
            {
              "role": "user",
              "parts": [
                {"text": "Identify the one-word legal topic of this RTI rejection (e.g. Language, Privacy, Security, Fee)."},
                {
                  "inlineData": {
                    "mimeType": "image/jpeg",
                    "data": base64Image
                  }
                }
              ]
            }
          ]
        };

        final topicResponse = await Supabase.instance.client.functions.invoke(
          'groq-api',
          body: {
            'targetApi': 'gemini', 
            'requestBody': topicRequestBody
          },
        );
        
        String topic = "General";
        if (topicResponse.status == 200 && topicResponse.data != null) {
          final data = topicResponse.data;
          if (data is Map && data.containsKey('candidates') && (data['candidates'] as List).isNotEmpty) {
            topic = data['candidates'][0]['content']['parts'][0]['text'].toString().trim();
          }
        }

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

        // ── 2. Second Call: Full Analysis via Gemini ──
        final analysisRequestBody = {
          "systemInstruction": {
            "parts": [{"text": systemInstructions}]
          },
          "contents": [
            {
              "role": "user",
              "parts": [
                {"text": userContent},
                {
                  "inlineData": {
                    "mimeType": "image/jpeg",
                    "data": base64Image
                  }
                }
              ]
            }
          ]
        };

        final analysisResponse = await Supabase.instance.client.functions.invoke(
          'groq-api',
          body: {
            'targetApi': 'gemini',
            'requestBody': analysisRequestBody
          },
        );

        if (analysisResponse.status != 200) throw Exception(analysisResponse.data);

        final data = analysisResponse.data;
        if (data == null || data is! Map || !data.containsKey('candidates') || (data['candidates'] as List).isEmpty) {
          throw Exception("API returned an unexpected format. Raw response: $data");
        }

        final finalAiText = data['candidates'][0]['content']['parts'][0]['text'].toString();
        
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
            _resultText = "Error processing request. Please try again. Details: $e";
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
// HISTORY SCREEN (WITH FILTERS, SEARCH & DELETE)
// ==========================================
class HistoryScreen extends StatefulWidget {
  final Function(String)? onChatTriggered;
  final String initialFilter;
  final String searchQuery;

  const HistoryScreen({super.key, this.onChatTriggered, this.initialFilter = 'All', this.searchQuery = ''});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late String _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
  }

  @override
  void didUpdateWidget(HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      setState(() {
        _selectedFilter = widget.initialFilter;
      });
    }
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : kTextSlate, fontWeight: FontWeight.w600, fontSize: 13)),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() => _selectedFilter = label);
      },
      backgroundColor: Colors.white.withOpacity(0.6),
      selectedColor: kRoyalBlue,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? kRoyalBlue : Colors.black12)),
    );
  }

  // ── NEW DELETE FUNCTION ──
  Future<void> _deleteRecord(dynamic rawId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Record', style: TextStyle(color: kTextSlate, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to permanently delete this RTI record? This cannot be undone.', style: TextStyle(color: kTextSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: kTextSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kRejectedRed, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // 1. Force the ID to a string to guarantee it matches Supabase's format
        final idString = rawId.toString();

        // 2. Add .select() so Supabase is FORCED to hand back the deleted row
        final response = await Supabase.instance.client
            .from('scan_history')
            .delete()
            .eq('id', idString)
            .select();

        // 3. If Supabase hands back an empty list, it means it blocked the deletion!
        if (response.isEmpty) {
          throw Exception("Blocked by Supabase. Please check your RLS Delete policies.");
        }

        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Record deleted successfully.'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildFilterChip('All'),
                _buildFilterChip('Drafts'),
                _buildFilterChip('Rejections'),
              ],
            ),
          ),
          
          if (widget.searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text(
                "Showing results for: '${widget.searchQuery}'", 
                style: const TextStyle(fontWeight: FontWeight.bold, color: kRoyalBlue, fontSize: 14)
              ),
            ),
          
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('scan_history')
                  .stream(primaryKey: ['id']).order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    itemCount: 5, 
                    itemBuilder: (context, index) {
                      return Shimmer.fromColors(
                        baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!,
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
                        const Text("You are offline.", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                        const SizedBox(height: 8),
                        const Text("Please connect to the internet to view your history.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No past scans found."));
                }

                final allHistory = snapshot.data!;
                final history = allHistory.where((item) {
                  final topic = item['topic']?.toString() ?? '';
                  final summary = item['analysis_summary']?.toString() ?? '';
                  
                  if (_selectedFilter == 'Drafts' && !topic.contains('New RTI')) return false;
                  if (_selectedFilter == 'Rejections' && topic.contains('New RTI')) return false;
                  
                  if (widget.searchQuery.isNotEmpty) {
                    final query = widget.searchQuery.toLowerCase();
                    if (!topic.toLowerCase().contains(query) && !summary.toLowerCase().contains(query)) {
                      return false;
                    }
                  }
                  
                  return true; 
                }).toList();

                if (history.isEmpty) {
                  return Center(
                    child: Text(
                      widget.searchQuery.isNotEmpty 
                        ? "No matches found for '${widget.searchQuery}'." 
                        : "No records found for '$_selectedFilter'.", 
                      style: const TextStyle(color: kTextSecondary)
                    )
                  );
                }

                return ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    final dateStr = item['created_at'] != null ? DateTime.parse(item['created_at']).toLocal().toString().split('.')[0] : 'Unknown Date';
                    final String topic = item['topic'] ?? 'General';
                    final bool hasReminder = item['filing_date'] != null && (item['notification_ids'] as List?)?.isNotEmpty == true;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      color: Colors.white.withOpacity(0.8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black12)),
                      child: ListTile(
                        leading: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: kRoyalBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.history_edu, color: kRoyalBlue),
                            ),
                            if (hasReminder)
                              Positioned(
                                top: -4, right: -4,
                                child: Container(
                                  width: 12, height: 12,
                                  decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                                ),
                              ),
                          ],
                        ),
                        title: Text(topic, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: kTextSlate)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dateStr, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                            if (hasReminder)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text('Reminder active · Filed: ${item['filing_date']?.toString().split('T')[0] ?? ''}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                        // ── REPLACED ARROW WITH DELETE BUTTON ──
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 22, color: Colors.redAccent),
                          tooltip: 'Delete Record',
                          onPressed: () => _deleteRecord(item['id']),
                        ),
                        onTap: () {
                          final bool isRegional = topic.contains('(Tamil)') || topic.contains('(Hindi)');
                          final bool isAnAppeal = !topic.contains('New RTI Application');
                          String displayContent = item['full_draft'] ?? "No content available.";
                          
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
                              backgroundColor: Colors.white,
                              title: Text(isAnAppeal ? "Appeal Analysis" : "RTI Draft", style: const TextStyle(color: kTextSlate, fontWeight: FontWeight.bold)),
                              content: SizedBox(
                                width: 600,
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("AI Summary:", style: TextStyle(fontWeight: FontWeight.bold, color: kRoyalBlue)),
                                      const SizedBox(height: 5),
                                      MarkdownBody(
                                        data: item['analysis_summary'] ?? "Analyzing...",
                                        styleSheet: MarkdownStyleSheet(p: const TextStyle(fontSize: 14, color: kTextSlate), strong: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kTextSlate)),
                                      ),
                                      const Divider(height: 30),
                                      Text(isAnAppeal ? "Generated Appeal:" : "Generated Application:", style: const TextStyle(fontWeight: FontWeight.bold, color: kRoyalBlue)),
                                      const SizedBox(height: 10),
                                      MarkdownBody(
                                        data: displayContent, selectable: true,
                                        styleSheet: MarkdownStyleSheet(p: const TextStyle(fontSize: 14, color: kTextSlate), strong: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kTextSlate)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close", style: TextStyle(color: kTextSecondary))),
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    if (widget.onChatTriggered != null) widget.onChatTriggered!(item['full_draft'] ?? item['analysis_summary'] ?? "");
                                  },
                                  icon: const Icon(Icons.chat_bubble_outline, size: 16, color: kRoyalBlue),
                                  label: const Text("Ask AI", style: TextStyle(color: kRoyalBlue)),
                                ),
                                if (!isRegional)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: kRoyalBlue, foregroundColor: Colors.white),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      generateAndPrintPdf(item['full_draft'] ?? "", context, isAppeal: isAnAppeal);
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
          ),
        ],
      ),
    );
  }
}

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

    String draftPart = fullAiResponse;
    if (draftPart.contains('[DRAFT_START]')) {
      draftPart = draftPart.split('[DRAFT_START]').last;
    } else if (draftPart.contains('---DRAFT START---')) {
      draftPart = draftPart.split('---DRAFT START---').last;
    } else if (draftPart.toLowerCase().contains('# draft')) {
      draftPart = fullAiResponse.substring(fullAiResponse.toLowerCase().indexOf('# draft')).trim();
      draftPart = draftPart.split('\n').skip(1).join('\n');
    }
    draftPart = draftPart.trim();

    if (draftPart.contains('[END OF DRAFT]')) {
      draftPart = draftPart.split('[END OF DRAFT]').first.trim();
    }

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
      
      // Update the database
      await Supabase.instance.client
          .from('scan_history')
          .update({'filing_date': null, 'notification_ids': null}).eq('id', item['id']);

      if (context.mounted) {
        // ── FORCE THE UI TO REFRESH INSTANTLY ──
        setState(() {
          _remindersStream = Supabase.instance.client
              .from('scan_history')
              .stream(primaryKey: ['id']).order('filing_date', ascending: true);
        });

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
      backgroundColor: kBackgroundOffWhite, // ── FIX: Explicitly set the premium white background ──
      appBar: AppBar(
        backgroundColor: kBackgroundOffWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Active Deadlines', style: TextStyle(color: kTextSlate, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextSlate),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _remindersStream, 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              itemCount: 5, 
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
                elevation: 0, // ── Flattened to match glass theme ──
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16), 
                  side: BorderSide(color: Colors.black.withOpacity(0.05))
                ),
                color: Colors.white.withOpacity(0.8),
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
                        child: Divider(height: 1, color: Colors.black12),
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

// ==========================================
// ANIMATED PARALLAX SVG BACKGROUND
// ==========================================
class AnimatedDoodleBackground extends StatefulWidget {
  const AnimatedDoodleBackground({super.key});

  @override
  State<AnimatedDoodleBackground> createState() => _AnimatedDoodleBackgroundState();
}

class _AnimatedDoodleBackgroundState extends State<AnimatedDoodleBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late final Widget _layer1;
  late final Widget _layer2;

  // ── ORIGINAL PREMIUM SVG ASSETS ──
  static const String svgScales = r'''<svg width="80" height="80" viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg"><g transform="rotate(30 40 40)"><rect x="25" y="20" width="30" height="15" rx="3" fill="none" stroke="#60A5FA" stroke-width="4" opacity="0.15"/><line x1="40" y1="35" x2="40" y2="65" stroke="#60A5FA" stroke-width="6" stroke-linecap="round" opacity="0.15"/><line x1="20" y1="27.5" x2="25" y2="27.5" stroke="#60A5FA" stroke-width="4" stroke-linecap="round" opacity="0.15"/><line x1="55" y1="27.5" x2="60" y2="27.5" stroke="#60A5FA" stroke-width="4" stroke-linecap="round" opacity="0.15"/><rect x="20" y="70" width="40" height="5" rx="2" fill="#60A5FA" opacity="0.1"/></g></svg>''';
  static const String svgSearch = r'''<svg width="80" height="80" viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg"><circle cx="40" cy="40" r="30" fill="none" stroke="#2563EB" stroke-width="2" stroke-dasharray="6,4" opacity="0.12"/><circle cx="40" cy="40" r="22" fill="none" stroke="#2563EB" stroke-width="3" opacity="0.15"/><path d="M 25 40 L 40 25 L 55 40 L 40 55 Z" fill="url(#grad5)" opacity="0.1"/><path d="M 25 40 L 40 25 L 55 40 L 40 55 Z" fill="none" stroke="#2563EB" stroke-width="2" stroke-linejoin="round" opacity="0.12"/><defs><linearGradient id="grad5" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stop-color="#2563EB" stop-opacity="1" /><stop offset="100%" stop-color="#FFFFFF" stop-opacity="0" /></linearGradient></defs></svg>''';
  static const String svgDoc = r'''<svg width="80" height="80" viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg"><path d="M 40 10 L 40 70 M 20 30 L 60 30 M 20 30 L 10 50 L 30 50 Z M 60 30 L 50 50 L 70 50 Z M 25 70 L 55 70" fill="none" stroke="#2563EB" stroke-width="4" stroke-linecap="round" stroke-linejoin="round" opacity="0.12"/><defs><linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stop-color="#2563EB" stop-opacity="0.15" /><stop offset="100%" stop-color="#60A5FA" stop-opacity="0" /></linearGradient></defs><path d="M 10 50 C 15 60 25 60 30 50 Z" fill="url(#grad1)"/><path d="M 50 50 C 55 60 65 60 70 50 Z" fill="url(#grad1)"/></svg>''';
  static const String svgShield = r'''<svg width="70" height="80" viewBox="0 0 70 80" xmlns="http://www.w3.org/2000/svg"><path d="M 35 10 L 10 20 L 10 40 C 10 60, 35 70, 35 70 C 35 70, 60 60, 60 40 L 60 20 Z" fill="url(#grad4)" opacity="0.1"/><path d="M 35 10 L 10 20 L 10 40 C 10 60, 35 70, 35 70 C 35 70, 60 60, 60 40 L 60 20 Z" fill="none" stroke="#2563EB" stroke-width="3" stroke-linejoin="round" opacity="0.15"/><path d="M 25 40 L 32 47 L 45 30" fill="none" stroke="#2563EB" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" opacity="0.15"/><defs><linearGradient id="grad4" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stop-color="#2563EB" stop-opacity="1" /><stop offset="100%" stop-color="#60A5FA" stop-opacity="0" /></linearGradient></defs></svg>''';
  static const String svgBriefcase = r'''<svg width="80" height="70" viewBox="0 0 80 70" xmlns="http://www.w3.org/2000/svg"><rect x="10" y="25" width="60" height="40" rx="4" fill="none" stroke="#60A5FA" stroke-width="3" opacity="0.15"/><path d="M 30 25 L 30 15 C 30 10, 50 10, 50 15 L 50 25" fill="none" stroke="#60A5FA" stroke-width="3" stroke-linecap="round" opacity="0.15"/><line x1="10" y1="35" x2="70" y2="35" stroke="#60A5FA" stroke-width="3" opacity="0.15"/><rect x="35" y="30" width="10" height="10" rx="2" fill="#60A5FA" opacity="0.12"/></svg>''';
  static const String svgPillar = r'''<svg width="60" height="80" viewBox="0 0 60 80" xmlns="http://www.w3.org/2000/svg"><rect x="10" y="10" width="40" height="60" rx="4" fill="url(#grad3)" opacity="0.08"/><rect x="10" y="10" width="40" height="60" rx="4" fill="none" stroke="#FFFFFF" stroke-width="3" opacity="0.15"/><line x1="20" y1="25" x2="30" y2="25" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round" opacity="0.15"/><line x1="20" y1="35" x2="40" y2="35" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round" opacity="0.15"/><line x1="20" y1="45" x2="40" y2="45" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round" opacity="0.15"/><line x1="20" y1="55" x2="35" y2="55" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round" opacity="0.15"/><defs><linearGradient id="grad3" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stop-color="#FFFFFF" stop-opacity="1" /><stop offset="100%" stop-color="#93C5FD" stop-opacity="0" /></linearGradient></defs></svg>''';
  static const String svgCitizens = r'''<svg width="80" height="70" viewBox="0 0 80 70" xmlns="http://www.w3.org/2000/svg"><circle cx="40" cy="25" r="12" fill="none" stroke="#60A5FA" stroke-width="3" opacity="0.15"/><path d="M 20 60 C 20 45, 60 45, 60 60" fill="none" stroke="#60A5FA" stroke-width="3" stroke-linecap="round" opacity="0.15"/><circle cx="20" cy="35" r="8" fill="none" stroke="#2563EB" stroke-width="2.5" opacity="0.12"/><path d="M 5 65 C 5 55, 30 55, 30 65" fill="none" stroke="#2563EB" stroke-width="2.5" stroke-linecap="round" opacity="0.12"/><circle cx="60" cy="35" r="8" fill="none" stroke="#2563EB" stroke-width="2.5" opacity="0.12"/><path d="M 50 65 C 50 55, 75 55, 75 65" fill="none" stroke="#2563EB" stroke-width="2.5" stroke-linecap="round" opacity="0.12"/></svg>''';
  static const String svgGavel = r'''<svg width="70" height="90" viewBox="0 0 70 90" xmlns="http://www.w3.org/2000/svg"><polygon points="35,10 10,30 60,30" fill="url(#grad2)" opacity="0.1"/><polygon points="35,10 10,30 60,30" fill="none" stroke="#93C5FD" stroke-width="3" stroke-linejoin="round" opacity="0.15"/><line x1="20" y1="30" x2="20" y2="70" stroke="#93C5FD" stroke-width="6" stroke-linecap="square" opacity="0.12"/><line x1="35" y1="30" x2="35" y2="70" stroke="#93C5FD" stroke-width="6" stroke-linecap="square" opacity="0.12"/><line x1="50" y1="30" x2="50" y2="70" stroke="#93C5FD" stroke-width="6" stroke-linecap="square" opacity="0.12"/><rect x="5" y="70" width="60" height="10" fill="none" stroke="#93C5FD" stroke-width="3" opacity="0.15"/><defs><linearGradient id="grad2" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="0%" stop-color="#93C5FD" stop-opacity="1" /><stop offset="100%" stop-color="#FFFFFF" stop-opacity="0" /></linearGradient></defs></svg>''';
  static const String svgCheck = r'''<svg width="70" height="70" viewBox="0 0 70 70" xmlns="http://www.w3.org/2000/svg"><circle cx="35" cy="35" r="30" fill="url(#grad6)" opacity="0.08"/><path d="M 20 35 L 30 45 L 50 25" fill="none" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" stroke-linejoin="round" opacity="0.15"/><defs><linearGradient id="grad6" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stop-color="#FFFFFF" stop-opacity="1" /><stop offset="100%" stop-color="#93C5FD" stop-opacity="0" /></linearGradient></defs></svg>''';
  
  // ── 3 BRAND NEW SVGS FOR ADDED DENSITY ──
  static const String svgHourglass = r'''<svg width="80" height="80" viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg"><path d="M 25 15 L 55 15 M 25 65 L 55 65 M 30 15 L 30 25 L 40 40 L 50 25 L 50 15 M 30 65 L 30 55 L 40 40 L 50 55 L 50 65" fill="none" stroke="#60A5FA" stroke-width="3" stroke-linejoin="round" opacity="0.15"/><circle cx="40" cy="55" r="5" fill="#60A5FA" opacity="0.1"/><path d="M 35 20 L 45 20 L 40 30 Z" fill="#60A5FA" opacity="0.1"/></svg>''';
  static const String svgPen = r'''<svg width="80" height="80" viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg"><path d="M 60 20 L 25 55 L 15 65 L 20 50 L 55 15 Z" fill="none" stroke="#2563EB" stroke-width="3" stroke-linejoin="round" opacity="0.12"/><line x1="25" y1="55" x2="15" y2="65" stroke="#2563EB" stroke-width="3" opacity="0.12"/><line x1="40" y1="30" x2="50" y2="40" stroke="#2563EB" stroke-width="3" opacity="0.12"/></svg>''';
  static const String svgChat = r'''<svg width="80" height="80" viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg"><rect x="15" y="20" width="50" height="35" rx="8" fill="none" stroke="#60A5FA" stroke-width="3" opacity="0.15"/><path d="M 25 55 L 25 65 L 35 55" fill="none" stroke="#60A5FA" stroke-width="3" stroke-linejoin="round" opacity="0.15"/><line x1="25" y1="30" x2="55" y2="30" stroke="#60A5FA" stroke-width="3" stroke-linecap="round" opacity="0.15"/><line x1="25" y1="40" x2="45" y2="40" stroke="#60A5FA" stroke-width="3" stroke-linecap="round" opacity="0.15"/></svg>''';

  Widget _buildSvg(String svgString, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.string(svgString),
    );
  }

  @override
  void initState() {
    super.initState();
    // Slightly slowed down to 40 seconds to accommodate the denser screen
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    // ── MASSIVELY EXPANDED LAYER 1 (14 Items Spread Wide) ──
    _layer1 = Stack(
      children: [
        Positioned(top: 80, left: 100, child: _buildSvg(svgScales, 80)),
        Positioned(top: 250, left: 60, child: _buildSvg(svgGavel, 90)),
        Positioned(top: 150, right: 180, child: _buildSvg(svgPillar, 85)),
        Positioned(top: 380, left: 220, child: _buildSvg(svgDoc, 90)),
        Positioned(top: 420, right: 280, child: _buildSvg(svgSearch, 100)),
        Positioned(bottom: 150, left: 150, child: _buildSvg(svgBriefcase, 80)),
        Positioned(top: 80, right: 450, child: _buildSvg(svgHourglass, 75)),
        Positioned(top: 600, left: 500, child: _buildSvg(svgPen, 85)),
        Positioned(bottom: 100, right: 500, child: _buildSvg(svgCitizens, 90)),
        Positioned(bottom: 300, right: 80, child: _buildSvg(svgShield, 80)),
        Positioned(top: -20, left: 400, child: _buildSvg(svgCheck, 70)),
        Positioned(top: 200, left: 800, child: _buildSvg(svgChat, 85)),
        Positioned(bottom: 400, left: -20, child: _buildSvg(svgScales, 60)),
        Positioned(bottom: 50, left: 700, child: _buildSvg(svgDoc, 80)),
      ],
    );

    // ── MASSIVELY EXPANDED LAYER 2 (14 Items Spread Wide) ──
    _layer2 = Stack(
      children: [
        Positioned(top: 120, right: 300, child: _buildSvg(svgShield, 70)),
        Positioned(top: 60, left: 450, child: _buildSvg(svgCheck, 80)),
        Positioned(top: 500, left: 650, child: _buildSvg(svgCitizens, 75)),
        Positioned(bottom: 100, right: 150, child: _buildSvg(svgDoc, 70)),
        Positioned(bottom: 250, left: 80, child: _buildSvg(svgScales, 60)),
        Positioned(top: 150, left: -40, child: _buildSvg(svgBriefcase, 90)),
        Positioned(bottom: 180, right: 400, child: _buildSvg(svgPillar, 75)),
        Positioned(top: 300, right: 100, child: _buildSvg(svgPen, 80)),
        Positioned(top: 400, right: 600, child: _buildSvg(svgHourglass, 65)),
        Positioned(bottom: 40, left: 400, child: _buildSvg(svgSearch, 85)),
        Positioned(top: -30, right: 100, child: _buildSvg(svgGavel, 70)),
        Positioned(bottom: 350, left: 300, child: _buildSvg(svgChat, 80)),
        Positioned(bottom: -20, right: 700, child: _buildSvg(svgCheck, 60)),
        Positioned(top: 600, right: -20, child: _buildSvg(svgCitizens, 85)),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final moveX1 = math.sin(_controller.value * 2 * math.pi) * 20;
          final moveY1 = math.cos(_controller.value * 2 * math.pi) * 25;
          final scale1 = 1.0 + (math.sin(_controller.value * 2 * math.pi) * 0.02);
          final rot1 = math.sin(_controller.value * 2 * math.pi) * 0.03; 

          final moveX2 = math.cos(_controller.value * 2 * math.pi) * -15;
          final moveY2 = math.sin(_controller.value * 2 * math.pi) * -20;
          final scale2 = 1.0 + (math.cos(_controller.value * 2 * math.pi) * 0.02);
          final rot2 = math.cos(_controller.value * 2 * math.pi) * -0.04; 

          return Stack(
            children: [
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..translate(moveX1, moveY1)
                  ..scale(scale1)
                  ..rotateZ(rot1),
                child: _layer1,
              ),
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..translate(moveX2, moveY2)
                  ..scale(scale2)
                  ..rotateZ(rot2),
                child: _layer2,
              ),
            ],
          );
        },
      ),
    );
  }
}