// lib/services/offline_queue.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class OfflineQueue {
  static Database? _db;
  static final List<Map<String, dynamic>> _memoryQueue = [];

  // Enforce SQLite usage only on Android and iOS devices
  static bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // ---------------------------------------------------------------------------
  // INITIALIZE DATABASE
  // ---------------------------------------------------------------------------
  static Future<void> _initDb() async {
    if (!_isMobile) return;
    if (_db != null) return;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "offline_reports.db");

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE reports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            description TEXT,
            latitude REAL,
            longitude REAL,
            file_path TEXT,
            media_type TEXT
          )
        ''');
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SAVE REPORT TO QUEUE
  // ---------------------------------------------------------------------------
  static Future<void> queueReport(Map<String, dynamic> report) async {
    if (!_isMobile) {
      final copy = Map<String, dynamic>.from(report);
      copy['id'] = _memoryQueue.length + 1;
      _memoryQueue.add(copy);
      return;
    }
    await _initDb();
    await _db!.insert("reports", report);
  }

  // ---------------------------------------------------------------------------
  // GET ALL QUEUED REPORTS
  // ---------------------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> getQueuedReports() async {
    if (!_isMobile) {
      return _memoryQueue;
    }
    await _initDb();
    return await _db!.query("reports");
  }

  // ---------------------------------------------------------------------------
  // DELETE REPORT BY ID
  // ---------------------------------------------------------------------------
  static Future<void> deleteReport(int id) async {
    if (!_isMobile) {
      _memoryQueue.removeWhere((item) => item['id'] == id);
      return;
    }
    await _initDb();
    await _db!.delete("reports", where: "id = ?", whereArgs: [id]);
  }

  // ---------------------------------------------------------------------------
  // CLEAR ALL REPORTS (OPTIONAL)
  // ---------------------------------------------------------------------------
  static Future<void> clearAllReports() async {
    if (!_isMobile) {
      _memoryQueue.clear();
      return;
    }
    await _initDb();
    await _db!.delete("reports");
  }
}
