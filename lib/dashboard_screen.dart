import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart'; 

class DashboardOverviewScreen extends StatelessWidget {
  final void Function(int, [String?, String?]) onNavigate;

  const DashboardOverviewScreen({super.key, required this.onNavigate});

  void _showActivityDetailModal(BuildContext context, Map<String, dynamic> item) {
    final topic = item['topic'] ?? 'General';
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

    if (displayContent.contains('[END OF DRAFT]')) {
      displayContent = displayContent.split('[END OF DRAFT]')[0].trim();
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isAnAppeal ? kRoyalBlue.withOpacity(0.1) : const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isAnAppeal ? Icons.gavel_rounded : Icons.description_rounded,
                color: isAnAppeal ? kRoyalBlue : const Color(0xFF10B981),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isAnAppeal ? "Appeal Analysis & Draft" : "RTI Application Draft",
                style: const TextStyle(fontWeight: FontWeight.bold, color: kTextSlate, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("AI Summary:", style: TextStyle(fontWeight: FontWeight.bold, color: kRoyalBlue, fontSize: 14)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kBackgroundOffWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: MarkdownBody(
                    data: item['analysis_summary'] ?? "Analyzing...",
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 14, height: 1.4, color: kTextSlate),
                      strong: const TextStyle(fontWeight: FontWeight.bold, color: kTextSlate),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isAnAppeal ? "Generated Appeal Draft:" : "Generated Application Draft:",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: kRoyalBlue, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kBackgroundOffWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: MarkdownBody(
                    data: displayContent,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 14, height: 1.5, color: kTextSlate),
                      strong: const TextStyle(fontWeight: FontWeight.bold, color: kTextSlate),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close", style: TextStyle(color: kTextSecondary, fontWeight: FontWeight.w600)),
          ),
          if (!isRegional)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kRoyalBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                generateAndPrintPdf(item['full_draft'] ?? "", context, isAppeal: isAnAppeal);
              },
              icon: const Icon(Icons.picture_as_pdf, size: 16),
              label: const Text("Generate PDF"),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      return const Center(child: Text("Please log in to view your dashboard."));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 850;

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: Supabase.instance.client
              .from('scan_history')
              .stream(primaryKey: ['id'])
              .order('created_at', ascending: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: kRoyalBlue));
            }

            final history = snapshot.data ?? [];
            final totalRtis = history.length;
            final activeAppeals = history.where((item) => item['filing_date'] != null && (item['notification_ids'] as List?)?.isNotEmpty == true).length;
            final rejectionsAnalyzed = history.where((item) => !item['topic'].toString().contains('New RTI')).length;

            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Quick Actions ──
                  if (isMobile)
                    Column(
                      children: [
                        _buildQuickAction(Icons.document_scanner, "Scan Rejection", "AI Analysis", kRoyalBlue, () => onNavigate(4)),
                        const SizedBox(height: 12),
                        _buildQuickAction(Icons.note_add, "Draft New", "RTI Application", const Color(0xFF10B981), () => onNavigate(1)),
                        const SizedBox(height: 12),
                        _buildQuickAction(Icons.library_books, "Templates", "Pre-built formats", const Color(0xFFF59E0B), () => onNavigate(2)),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(child: _buildQuickAction(Icons.document_scanner, "Scan Rejection", "AI Analysis", kRoyalBlue, () => onNavigate(4))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildQuickAction(Icons.note_add, "Draft New", "RTI Application", const Color(0xFF10B981), () => onNavigate(1))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildQuickAction(Icons.library_books, "Templates", "Pre-built formats", const Color(0xFFF59E0B), () => onNavigate(2))),
                      ],
                    ),
                  SizedBox(height: isMobile ? 24 : 32),

                  // ── Statistics Cards ──
                  if (isMobile)
                    Column(
                      children: [
                        _buildStatCard("Total RTIs Drafted", "$totalRtis", Icons.folder_shared, "Lifetime", () => onNavigate(5, null, 'All')),
                        const SizedBox(height: 12),
                        _buildStatCard("Active Tracking", "$activeAppeals", Icons.gavel, "Reminders set", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen()))),
                        const SizedBox(height: 12),
                        _buildStatCard("Rejections Analyzed", "$rejectionsAnalyzed", Icons.document_scanner_outlined, "AI Processed", () => onNavigate(5, null, 'Rejections')),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(child: _buildStatCard("Total RTIs Drafted", "$totalRtis", Icons.folder_shared, "Lifetime", () => onNavigate(5, null, 'All'))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard("Active Tracking", "$activeAppeals", Icons.gavel, "Reminders set", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen())))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard("Rejections Analyzed", "$rejectionsAnalyzed", Icons.document_scanner_outlined, "AI Processed", () => onNavigate(5, null, 'Rejections'))),
                      ],
                    ),
                  SizedBox(height: isMobile ? 24 : 32),

                  // ── Charts & Recent Activity ──
                  if (isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PremiumGlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Activity Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextSlate)),
                              const SizedBox(height: 8),
                              const Text("Real-time summary of your RTI activities", style: TextStyle(color: kTextSecondary, fontSize: 13)),
                              const SizedBox(height: 30),
                              SizedBox(
                                height: 200,
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: (totalRtis + 2).toDouble(),
                                    barGroups: [
                                      _makeBarData(0, totalRtis.toDouble(), kRoyalBlue),
                                      _makeBarData(1, activeAppeals.toDouble(), const Color(0xFF10B981)),
                                      _makeBarData(2, rejectionsAnalyzed.toDouble(), const Color(0xFFF59E0B)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        PremiumGlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextSlate)),
                              const SizedBox(height: 12),
                              if (history.isEmpty)
                                const Padding(padding: EdgeInsets.only(top: 8.0), child: Text("No recent activity. Draft an RTI to see it here!", style: TextStyle(color: kTextSecondary))),
                              ...history.take(5).map((item) {
                                final topic = item['topic'] ?? 'General RTI';
                                final dateStr = item['created_at'] != null ? DateTime.parse(item['created_at']).toLocal().toString().split(' ')[0] : '';
                                final isNewRti = topic.toString().contains('New RTI');
                                
                                return _buildActivityItem(
                                  isNewRti ? Icons.auto_awesome : Icons.document_scanner,
                                  isNewRti ? "Drafted Application" : "Scanned Rejection",
                                  topic, dateStr, isNewRti ? const Color(0xFF10B981) : kRoyalBlue,
                                  () => _showActivityDetailModal(context, item),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: PremiumGlassCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Activity Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextSlate)),
                                const SizedBox(height: 8),
                                const Text("Real-time summary of your RTI activities", style: TextStyle(color: kTextSecondary, fontSize: 13)),
                                const SizedBox(height: 30),
                                SizedBox(
                                  height: 250,
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: (totalRtis + 2).toDouble(),
                                      barGroups: [
                                        _makeBarData(0, totalRtis.toDouble(), kRoyalBlue),
                                        _makeBarData(1, activeAppeals.toDouble(), const Color(0xFF10B981)),
                                        _makeBarData(2, rejectionsAnalyzed.toDouble(), const Color(0xFFF59E0B)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 1,
                          child: PremiumGlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextSlate)),
                                const SizedBox(height: 12),
                                if (history.isEmpty)
                                  const Padding(padding: EdgeInsets.only(top: 8.0), child: Text("No recent activity. Draft an RTI to see it here!", style: TextStyle(color: kTextSecondary))),
                                ...history.take(5).map((item) {
                                  final topic = item['topic'] ?? 'General RTI';
                                  final dateStr = item['created_at'] != null ? DateTime.parse(item['created_at']).toLocal().toString().split(' ')[0] : '';
                                  final isNewRti = topic.toString().contains('New RTI');
                                  
                                  return _buildActivityItem(
                                    isNewRti ? Icons.auto_awesome : Icons.document_scanner,
                                    isNewRti ? "Drafted Application" : "Scanned Rejection",
                                    topic, dateStr, isNewRti ? const Color(0xFF10B981) : kRoyalBlue,
                                    () => _showActivityDetailModal(context, item),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      }
    );
  }

  BarChartGroupData _makeBarData(int x, double y, Color color) {
    return BarChartGroupData(x: x, barRods: [BarChartRodData(toY: y, color: color, width: 22, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]);
  }

  Widget _buildQuickAction(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color, size: 28)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kTextSlate)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: kTextSecondary)),
            ])),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, String trend, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: PremiumGlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: kRoyalBlue.withOpacity(0.7), size: 24),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(trend, style: const TextStyle(fontSize: 11, color: kTextSecondary, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: kTextSlate, letterSpacing: -1)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 13, color: kTextSecondary, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(IconData icon, String title, String desc, String time, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: color.withOpacity(0.08),
        splashColor: color.withOpacity(0.15),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 16, color: color)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: kTextSlate, fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: kTextSecondary)),
              ])),
              Text(time, style: const TextStyle(fontSize: 11, color: kTextSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}