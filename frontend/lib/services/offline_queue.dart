import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class OfflineQueue {
  static Future<Database> get database async {
    return openDatabase(
      join(await getDatabasesPath(), 'reports.db'),
      onCreate: (db, version) => db.execute(
        "CREATE TABLE reports(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, description TEXT, latitude REAL, longitude REAL, file_path TEXT, media_type TEXT)"
      ),
      version: 1,
    );
  }

  static Future<void> queueReport(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('reports', data);
  }

  static Future<List<Map<String, dynamic>>> getQueuedReports() async {
    final db = await database;
    return await db.query('reports');
  }

  static Future<void> deleteReport(int id) async {
    final db = await database;
    await db.delete('reports', where: "id = ?", whereArgs: [id]);
  }
}