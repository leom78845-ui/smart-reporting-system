import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/offline_queue.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  bool _isLoading = true;
  List<dynamic> _onlineReports = [];
  List<Map<String, dynamic>> _offlineReports = [];

  @override
  void initState() {
    super.initState();
    _loadAllReports();
  }

  Future<void> _loadAllReports() async {
    setState(() => _isLoading = true);
    try {
      _onlineReports = await ApiService.getMyReports();
      _offlineReports = await OfflineQueue.getQueuedReports();
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDraft(int id) async {
    await OfflineQueue.deleteReport(id);
    _loadAllReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Reports')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllReports,
              child: (_onlineReports.isEmpty && _offlineReports.isEmpty)
                  ? ListView(children: const [
                      SizedBox(height: 50),
                      Center(child: Text("No reports found."))
                    ])
                  : ListView(
                      children: [
                        ..._offlineReports.map((item) => Card(
                              color: Colors.orange.shade50,
                              child: ListTile(
                                title: Text(item['title'] ?? 'Draft'),
                                subtitle: const Text("Status: Pending Upload"),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteDraft(item['id']),
                                ),
                              ),
                            )),
                        ..._onlineReports.map((report) => Card(
                              child: ListTile(
                                title: Text(report['title']),
                                subtitle: Text("Status: ${report['status']}"),
                              ),
                            )),
                      ],
                    ),
            ),
    );
  }
}