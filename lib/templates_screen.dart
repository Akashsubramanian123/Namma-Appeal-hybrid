import 'dart:ui';
import 'package:flutter/material.dart';
import 'main.dart'; 

class TemplatesScreen extends StatelessWidget {
  final void Function(int, [String?]) onNavigate;

  const TemplatesScreen({super.key, required this.onNavigate});

  // ── TEMPLATE DATA ──
  final List<Map<String, dynamic>> _templates = const [
    {
      "title": "Road Maintenance",
      "icon": Icons.add_road,
      "desc": "Request details on road repair budgets, contractor details, and timelines.",
      "prompt": "I want to file an RTI to the local municipal corporation regarding the poor condition of the main road in my area. Please ask for the allocated budget, the contractor details, and the planned timeline for repairs."
    },
    {
      "title": "Exam Answer Sheets",
      "icon": Icons.school,
      "desc": "Request a certified copy of your answer sheets from a university or board.",
      "prompt": "Draft an RTI application to the University exam controller requesting a certified copy of my answer sheet for the recent semester exams. Ask for the grading key as well."
    },
    {
      "title": "Pending Pension",
      "icon": Icons.account_balance_wallet,
      "desc": "Inquire about the status of delayed pension disbursement.",
      "prompt": "Draft an RTI to the EPFO/Pension department asking for the exact daily status of my pension file and the reason for the delay in disbursement."
    },
    {
      "title": "FIR Status",
      "icon": Icons.local_police,
      "desc": "Ask the Police Department for the action taken report on an FIR.",
      "prompt": "Draft an RTI to the local Police Station requesting the detailed Action Taken Report (ATR) on an FIR I filed last month, including the names of the investigating officers."
    },
    {
      "title": "MPLADS Funds",
      "icon": Icons.location_city,
      "desc": "Request expenditure details of your local MP's development fund.",
      "prompt": "Draft an RTI asking for the complete expenditure details and list of completed projects under the MPLADS fund for my constituency over the last 2 years."
    },
    {
      "title": "Property Tax",
      "icon": Icons.home_work,
      "desc": "Get assessment details and calculation logic for property tax.",
      "prompt": "Draft an RTI to the municipal corporation requesting the exact formula and measurement details used to calculate the property tax for my residential building."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
        
        // ── RESPONSIVE GRID VARIABLES ──
        int crossAxisCount = 3;
        double childAspectRatio = 1.1; // Desktop (Square-ish)

        if (isMobile) {
          crossAxisCount = 2;
          childAspectRatio = 0.75; // ── MOBILE: Makes cards TALLER to prevent text overflow! ──
        } else if (isTablet) {
          crossAxisCount = 2;
          childAspectRatio = 1.0; 
        }

        // For extremely small/narrow phones
        if (constraints.maxWidth < 400) {
          crossAxisCount = 1;
          childAspectRatio = 2.2; 
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "RTI Template Library",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kTextSlate),
              ),
              const SizedBox(height: 8),
              const Text(
                "Select a pre-built legal framework to fast-track your application.",
                style: TextStyle(color: kTextSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // Disables inner scrolling
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: childAspectRatio, // Applies the responsive height!
                ),
                itemCount: _templates.length,
                itemBuilder: (context, index) {
                  final t = _templates[index];
                  return _buildTemplateCard(t, context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> t, BuildContext context) {
    return InkWell(
      onTap: () {
        onNavigate(1, t['prompt']); 
      },
      borderRadius: BorderRadius.circular(20),
      child: PremiumGlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kRoyalBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(t['icon'] as IconData, color: kRoyalBlue, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              t['title'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, color: kTextSlate, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Expanded forces the description to take remaining space without blowing out the bottom
            Expanded(
              child: Text(
                t['desc'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(color: kTextSecondary, fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}