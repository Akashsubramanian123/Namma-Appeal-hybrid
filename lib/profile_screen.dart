import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';
import 'legal_screen.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobileController = TextEditingController();
  final _stateController = TextEditingController();

  String _selectedLanguage = 'English';
  final List<String> _languages = [
    'English', 'Hindi', 'Tamil', 'Telugu', 'Malayalam',
    'Kannada', 'Marathi', 'Bengali', 'Gujarati', 'Punjabi', 'Odia',
  ];

  bool _isSaving = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadFromNotifier();
    userProfileNotifier.addListener(_loadFromNotifier);
  }

  @override
  void dispose() {
    userProfileNotifier.removeListener(_loadFromNotifier);
    _fullNameController.dispose();
    _addressController.dispose();
    _mobileController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _loadFromNotifier() {
    final profile = userProfileNotifier.value;
    if (profile != null && mounted) {
      setState(() {
        _fullNameController.text = profile['full_name'] ?? '';
        _addressController.text = profile['address'] ?? '';
        _mobileController.text = profile['mobile_number'] ?? '';
        _stateController.text = profile['state'] ?? '';
        final lang = profile['preferred_language'] ?? 'English';
        _selectedLanguage = _languages.contains(lang) ? lang : 'English';
        _isLoaded = true;
      });
    } else if (mounted) {
      setState(() => _isLoaded = true);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await userProfileNotifier.saveProfile({
        'full_name': _fullNameController.text.trim(),
        'address': _addressController.text.trim(),
        'mobile_number': _mobileController.text.trim(),
        'state': _stateController.text.trim(),
        'preferred_language': _selectedLanguage,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final saffron = Theme.of(context).colorScheme.secondary;

    if (!_isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: themeColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: saffron.withOpacity(0.3),
                    child: const Icon(Icons.person, size: 32, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ValueListenableBuilder<Map<String, dynamic>?>(
                          valueListenable: userProfileNotifier,
                          builder: (_, profile, __) => Text(
                            profile?['full_name']?.isNotEmpty == true
                                ? profile!['full_name']
                                : 'Your Profile',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          Supabase.instance.client.auth.currentUser?.email ?? '',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            // Profile auto-fill info chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: saffron.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: saffron.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_fix_high, size: 16, color: saffron),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Your saved profile is auto-filled into RTI drafts and PDF signatures.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _sectionLabel('Personal Details', themeColor),
            const SizedBox(height: 12),

            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _mobileController,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value != null && value.isNotEmpty && value.length != 10) {
                  return 'Please enter a valid 10-digit mobile number';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _stateController,
              decoration: const InputDecoration(
                labelText: 'State',
                prefixIcon: Icon(Icons.map_outlined),
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.home_outlined),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),

            _sectionLabel('Preferred Language for RTI Drafts', themeColor),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: themeColor.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(12),
                color: themeColor.withOpacity(0.04),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  isExpanded: true,
                  icon: Icon(Icons.language, color: themeColor),
                  items: _languages
                      .map((l) => DropdownMenuItem(
                            value: l,
                            child: Text(l,
                                style: TextStyle(
                                    color: themeColor, fontWeight: FontWeight.w600)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedLanguage = v!),
                ),
              ),
            ),

            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isSaving ? 'Saving...' : 'Save Profile',
                  style: const TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 30),
            const Divider(height: 30),

            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined, color: Colors.blueGrey),
              title: const Text('Privacy Policy & Terms of Service'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LegalScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Row(
      children: [
        Container(width: 4, height: 18, color: color,
            margin: const EdgeInsets.only(right: 10)),
        Text(text,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
