import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  final _pincodeController = TextEditingController();

  bool _isVerifyingPin = false;
  String _verifiedArea = "";

  String? _selectedState;
  final List<String> _indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
    'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Andaman and Nicobar Islands', 'Chandigarh', 'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi', 'Jammu and Kashmir', 'Ladakh', 'Lakshadweep', 'Puducherry'
  ];

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
    _pincodeController.dispose();
    super.dispose();
  }

  void _loadFromNotifier() {
    final profile = userProfileNotifier.value;
    if (profile != null && mounted) {
      setState(() {
        _fullNameController.text = profile['full_name'] ?? '';
        _mobileController.text = profile['mobile_number'] ?? '';
        
        final st = profile['state'] ?? 'Tamil Nadu';
        _selectedState = _indianStates.contains(st) ? st : 'Tamil Nadu';

        final lang = profile['preferred_language'] ?? 'English';
        _selectedLanguage = _languages.contains(lang) ? lang : 'English';

        // --- NEW ADDRESS PARSING LOGIC ---
        String fullAddress = profile['address'] ?? '';
        
        // Check if the saved address contains our PIN format
        if (fullAddress.contains('PIN:')) {
          final parts = fullAddress.split('PIN:');
          String beforePin = parts[0].trim(); 
          _pincodeController.text = parts[1].trim(); 

          // Remove the trailing comma from the string before the PIN
          if (beforePin.endsWith(',')) {
            beforePin = beforePin.substring(0, beforePin.length - 1).trim();
          }

          // Split the remaining string to separate the Door No and the District
          int lastCommaIndex = beforePin.lastIndexOf(',');
          if (lastCommaIndex != -1) {
            _addressController.text = beforePin.substring(0, lastCommaIndex).trim();
            _verifiedArea = beforePin.substring(lastCommaIndex + 1).trim();
          } else {
            _addressController.text = beforePin;
          }
        } else {
          // Fallback for older profiles that don't have a PIN saved yet
          _addressController.text = fullAddress;
        }

        _isLoaded = true;
      });
    } else if (mounted) {
      setState(() {
        _selectedState = 'Tamil Nadu';
        _isLoaded = true;
      });
    }
  }

  Future<void> _verifyPinCode(String pin) async {
    setState(() => _isVerifyingPin = true);
    try {
      final response = await http.get(Uri.parse('https://api.postalpincode.in/pincode/$pin'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty && data[0]['Status'] == 'Success') {
          final postOffices = data[0]['PostOffice'] as List;
          if (postOffices.isNotEmpty) {
            final firstOffice = postOffices[0];
            final stateName = firstOffice['State'];
            final district = firstOffice['District'] ?? firstOffice['Name'] ?? '';
            
            setState(() {
              if (_indianStates.contains(stateName)) {
                _selectedState = stateName;
              }
              _verifiedArea = district;
            });
            return;
          }
        }
      }
      
      setState(() {
        _verifiedArea = "";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid PIN Code. Please enter a real Indian PIN code.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _verifiedArea = "";
      });
    } finally {
      if (mounted) setState(() => _isVerifyingPin = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final combinedAddress = "${_addressController.text.trim()}, $_verifiedArea, PIN: ${_pincodeController.text.trim()}";
      await userProfileNotifier.saveProfile({
        'full_name': _fullNameController.text.trim(),
        'address': combinedAddress,
        'mobile_number': _mobileController.text.trim(),
        'state': _selectedState ?? 'Tamil Nadu',
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
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Full name is required';
                if (v.trim().length < 3) return 'Please enter a valid full name';
                return null;
              },
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _mobileController,
              decoration: const InputDecoration(
                labelText: 'Mobile Number *',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Mobile number is required';
                }
                final regExp = RegExp(r'^[6789]\d{9}$');
                if (!regExp.hasMatch(value.trim())) {
                  return 'Please enter a valid 10-digit Indian mobile number (starts with 6-9)';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _pincodeController,
              decoration: InputDecoration(
                labelText: 'PIN Code *',
                prefixIcon: const Icon(Icons.pin_drop_outlined),
                suffixIcon: _isVerifyingPin 
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : null,
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              onChanged: (val) {
                if (val.length == 6) {
                  _verifyPinCode(val);
                }
              },
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'PIN Code is required';
                if (v.trim().length != 6) return 'PIN Code must be 6 digits';
                return null;
              },
            ),
            if (_verifiedArea.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4, bottom: 12),
                child: Text(
                  'Verified Area: $_verifiedArea',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),

            DropdownButtonFormField<String>(
              value: _selectedState,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'State / Union Territory *',
                prefixIcon: Icon(Icons.map_outlined),
              ),
              items: _indianStates.map((stateName) {
                return DropdownMenuItem(
                  value: stateName,
                  child: Text(stateName),
                );
              }).toList(),
              onChanged: (newValue) => setState(() => _selectedState = newValue),
              validator: (value) => (value == null || value.isEmpty) ? 'Please select a state' : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Door No., Building, Street Name *',
                prefixIcon: Icon(Icons.home_outlined),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Address is required';
                }
                return null;
              },
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