import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule_config_model.dart';

class ScheduleProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, ScheduleConfigModel> _configs = {};

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ScheduleConfigModel? getConfigForPlant(String plantId) {
    return _configs[plantId];
  }

  Future<void> loadConfigs(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('schedules')
          .where('userId', isEqualTo: userId)
          .get();

      _configs.clear();
      for (var doc in snapshot.docs) {
        final config = ScheduleConfigModel.fromMap(doc.data(), doc.id);
        _configs[config.plantId] = config;
      }
    } catch (e) {
      debugPrint('Error loading schedules: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveScheduleConfig(ScheduleConfigModel config, String userId) async {
    _configs[config.plantId] = config;
    notifyListeners();

    try {
      Map<String, dynamic> data = config.toMap();
      data['userId'] = userId;

      await _firestore
          .collection('schedules')
          .doc(config.plantId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving schedule: $e');
    }
  }

  // Method untuk menandai tugas telah dikerjakan
  Future<void> performAction(String plantId, String actionType) async {
    final config = _configs[plantId];
    if (config == null) return;

    DateTime now = DateTime.now();
    Map<String, dynamic> updates = {};

    if (actionType == 'water') updates['lastWateredDate'] = now.toIso8601String();
    if (actionType == 'fertilize') updates['lastFertilizedDate'] = now.toIso8601String();
    if (actionType == 'repot') updates['lastRepottedDate'] = now.toIso8601String();
    if (actionType == 'pesticide') updates['lastPesticideDate'] = now.toIso8601String();

    try {
      await _firestore.collection('schedules').doc(plantId).update(updates);

      // Update data di memori lokal agar UI langsung berubah tanpa perlu loading ulang
      await loadConfigs((await _firestore.collection('schedules').doc(plantId).get()).data()?['userId'] ?? '');
    } catch (e) {
      debugPrint('Error updating action: $e');
    }
  }
}