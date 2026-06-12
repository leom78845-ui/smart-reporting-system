import 'package:connectivity_plus/connectivity_plus.dart';
import 'offline_queue.dart';
import 'api_service.dart';

class SyncManager {
  static void initialize() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      if (!results.contains(ConnectivityResult.none)) {
        final drafts = await OfflineQueue.getQueuedReports();
        for (var report in drafts) {
          bool success = await ApiService.submitReport(
            title: report['title'],
            description: report['description'],
            latitude: report['latitude'],
            longitude: report['longitude'],
            filePath: report['file_path'],
            mediaType: report['media_type'],
          );
          if (success) {
            await OfflineQueue.deleteReport(report['id']);
          }
        }
      }
    });
  }
}