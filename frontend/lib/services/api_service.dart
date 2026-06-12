import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- AUTHENTICATION ---
  
  static Future<UserCredential?> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
    } on FirebaseAuthException catch (e) {
      debugPrint("Login error: ${e.message}");
      return null;
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }

  // --- DATABASE OPERATIONS ---

  static Future<bool> submitReport({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required String filePath, // For Firebase, you'd usually upload to Storage first, then save URL
    required String mediaType,
  }) async {
    try {
      await _db.collection('reports').add({
        "title": title,
        "description": description,
        "latitude": latitude,
        "longitude": longitude,
        "media_url": filePath, // Stored as a reference/URL
        "media_type": mediaType,
        "status": "pending",
        "created_at": FieldValue.serverTimestamp(),
        "user_id": _auth.currentUser?.uid,
      });
      return true;
    } catch (e) {
      debugPrint("SubmitReport Error: $e");
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getMyReports() async {
    try {
      final snapshot = await _db.collection('reports')
          .where('user_id', isEqualTo: _auth.currentUser?.uid)
          .get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAllReports() async {
    try {
      final snapshot = await _db.collection('reports').get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> updateReportStatus(String docId, String status) async {
    try {
      await _db.collection('reports').doc(docId).update({"status": status});
    } catch (e) {
      debugPrint("Update error: $e");
    }
  }

  // Note: Password changes in Firebase are handled via the Auth SDK
  static Future<bool> changePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
      return true;
    } catch (e) {
      return false;
    }
  }
}