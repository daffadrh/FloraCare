import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/journal_model.dart';

class JournalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'health_logs'; 

  Stream<List<HealthLog>> streamPlantHealthLogs(String plantId) {
    return _firestore
        .collection(_collectionName)
        .where('plantId', isEqualTo: plantId)
        .snapshots()
        .map((snapshot) {
          List<HealthLog> logs = snapshot.docs
              .map((doc) => HealthLog.fromMap(doc.id, doc.data()))
              .toList();
          
          logs.sort((a, b) => b.date.compareTo(a.date));
          
          return logs;
        });
  }

  Future<void> addHealthLog(HealthLog log) async {
    await _firestore.collection(_collectionName).add(log.toMap());
  }

  Future<void> updateHealthLog(HealthLog log) async {
    await _firestore.collection(_collectionName).doc(log.id).update(log.toMap());
  }

  Future<void> deleteHealthLog(String id) async {
    await _firestore.collection(_collectionName).doc(id).delete();
  }

  Future<void> toggleRecoveryStatus(String logId, bool isRecovered) async {
    await _firestore.collection(_collectionName).doc(logId).update({
      'isRecovered': isRecovered,
    });
  }
}