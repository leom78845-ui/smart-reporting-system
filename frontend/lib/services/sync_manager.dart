// lib/services/sync_manager.dart

import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'offline_queue.dart';
import 'api_service.dart';
import '../utils/constants.dart';

class SyncManager {
  static Timer? _timer;

  // ---------------------------------------------------------------------------
  // INITIALIZE SYNC MANAGER
  // ---------------------------------------------------------------------------
  static void initialize() {
    // Cancel any existing timer
    _timer?.cancel();

    // Run sync every X seconds
    _timer = Timer.periodic(
      Duration(seconds: AppConstants.syncIntervalSeconds),
      (_) => _attemptSync(),
    );
  }

  // ---------------------------------------------------------------------------
  // ATTEMPT SYNC
  // ---------------------------------------------------------------------------
  static Future<void> _attemptSync() async {
    final conn = await Connectivity().checkConnectivity();
    final isOffline = (conn is List)
        ? (conn.contains(ConnectivityResult.none) || conn.isEmpty)
        : (conn == ConnectivityResult.none);
    if (isOffline) {
      return; // no internet
    }

    final drafts = await OfflineQueue.getQueuedReports();
    if (drafts.isEmpty) return;

    for (final draft in drafts) {
      try {
        final filePath = draft['file_path'] as String?;
        final mediaType = draft['media_type'] ?? "image";

        if (filePath == null) continue;

        final file = File(filePath);
        final mediaUrl = await ApiService.uploadMedia(file);

        if (mediaUrl == null) continue;

        final success = await ApiService.submitReport(
          title: draft['title'] ?? "Untitled",
          description: draft['description'] ?? "",
          latitude: (draft['latitude'] as num).toDouble(),
          longitude: (draft['longitude'] as num).toDouble(),
          mediaUrl: mediaUrl,
          mediaType: mediaType,
          mediaCapturedAt: draft['media_captured_at'] as String?,
        );

        if (success) {
          await OfflineQueue.deleteReport(draft['id'] as int);
        }
      } catch (_) {
        // Skip failed draft, will retry next cycle
        continue;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // STOP SYNC MANAGER
  // ---------------------------------------------------------------------------
  static void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
