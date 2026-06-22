// lib/screens/my_reports_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/offline_queue.dart';
import '../managers/auth_manager.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingOnline = true;
  bool _isLoadingOffline = true;

  List<dynamic> _onlineReports = [];
  List<Map<String, dynamic>> _offlineReports = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOnlineReports();
    _loadOfflineReports();
  }

  Future<void> _loadOnlineReports() async {
    setState(() => _isLoadingOnline = true);
    try {
      final data = await ApiService.getMyReports();
      if (mounted) setState(() => _onlineReports = data);
    } catch (_) {
      if (mounted) setState(() => _onlineReports = []);
    } finally {
      if (mounted) setState(() => _isLoadingOnline = false);
    }
  }

  Future<void> _loadOfflineReports() async {
    setState(() => _isLoadingOffline = true);
    try {
      final drafts = await OfflineQueue.getQueuedReports();
      if (mounted) setState(() => _offlineReports = drafts);
    } catch (_) {
      if (mounted) setState(() => _offlineReports = []);
    } finally {
      if (mounted) setState(() => _isLoadingOffline = false);
    }
  }

  Widget _buildStatusChip(String? status) {
    Color color;
    IconData icon;
    switch (status?.toLowerCase()) {
      case 'pending':
        color = Colors.orangeAccent;
        icon = Icons.hourglass_empty;
        break;
      case 'reviewing':
        color = Colors.blueAccent;
        icon = Icons.rate_review;
        break;
      case 'resolved':
        color = Colors.greenAccent;
        icon = Icons.check_circle_outline;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status?.toUpperCase() ?? "UNKNOWN",
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Reports",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.cloud), text: "Online"),
            Tab(icon: Icon(Icons.offline_bolt), text: "Offline Drafts"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadOnlineReports();
              _loadOfflineReports();
            },
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFF121212),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOnlineReports(),
            _buildOfflineReports(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ONLINE REPORTS
  // ---------------------------------------------------------------------------

  Widget _buildOnlineReports() {
    if (_isLoadingOnline) {
      return const Center(child: CircularProgressIndicator(color: Colors.blue));
    }
    if (_onlineReports.isEmpty) {
      return const Center(
        child: Text(
          "No online reports found.",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _onlineReports.length,
      itemBuilder: (context, i) {
        final report = _onlineReports[i];
        return Card(
          color: Colors.white.withOpacity(0.05),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              report['title'] ?? 'Report',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  _buildStatusChip(report['status']),
                ],
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white70),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: Colors.grey.shade900,
                    title: Text(
                      report['title'] ?? 'Report',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      report['description'] ?? 'No description',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close", style: TextStyle(color: Colors.blueAccent)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // OFFLINE REPORTS
  // ---------------------------------------------------------------------------

  Widget _buildOfflineReports() {
    if (_isLoadingOffline) {
      return const Center(child: CircularProgressIndicator(color: Colors.blue));
    }
    if (_offlineReports.isEmpty) {
      return const Center(
        child: Text(
          "No offline drafts saved.",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _offlineReports.length,
      itemBuilder: (context, i) {
        final draft = _offlineReports[i];
        return Card(
          color: Colors.white.withOpacity(0.05),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              draft['title'] ?? 'Draft',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: const Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "Pending sync",
                style: TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () async {
                await OfflineQueue.deleteReport(draft['id']);
                _loadOfflineReports();
              },
            ),
          ),
        );
      },
    );
  }
}
