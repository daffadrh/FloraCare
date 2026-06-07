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
}