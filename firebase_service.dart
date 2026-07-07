import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trade.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream current user auth state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current User ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Sign in anonymously for easy testing
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Save Trade Execution in cloud Firestore
  Future<void> saveTrade(Trade trade) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('trades')
        .doc(trade.id)
        .set(trade.toJson());

    // Update the portfolio balance in the user's document
    await _firestore.collection('users').doc(userId).set({
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Stream Trade History
  Stream<List<Trade>> streamTrades() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('trades')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Trade.fromJson(doc.data())).toList();
    });
  }

  // Save Alert Settings
  Future<void> saveAlert(String symbol, double targetPrice, String type) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('alerts')
        .add({
      'symbol': symbol,
      'targetPrice': targetPrice,
      'type': type, // 'ABOVE' or 'BELOW'
      'createdAt': FieldValue.serverTimestamp(),
      'active': true,
    });
  }

  // Stream Alerts
  Stream<List<Map<String, dynamic>>> streamAlerts() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('alerts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Delete Alert
  Future<void> deleteAlert(String alertId) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('alerts')
        .doc(alertId)
        .delete();
  }
}
