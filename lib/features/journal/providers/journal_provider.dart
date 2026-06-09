import 'dart:async';
import 'package:flutter/material.dart';
import '../models/journal_model.dart';
import '../services/journal_service.dart';

class JournalProvider extends ChangeNotifier {
  final JournalService _service = JournalService();
  StreamSubscription<List<HealthLog>>? _subscription;

  List<HealthLog> _allLogs = [];
  bool _isLoading = false;
  String? _errorMessage;

  bool _filterActiveOnly = false; 

  JournalProvider();

  void init(String plantId) {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = _service.streamPlantHealthLogs(plantId).listen(
      (logs) {
        _allLogs = logs;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get filterActiveOnly => _filterActiveOnly;

  List<HealthLog> get logs {
    List<HealthLog> filtered = List.from(_allLogs);

    if (_filterActiveOnly) {
      filtered = filtered.where((log) => !log.isRecovered).toList();
    }

    return filtered;
  }

  // Mengubah status filter
  void setFilterActiveOnly(bool value) {
    _filterActiveOnly = value;
    notifyListeners();
  }

  Future<void> addHealthLog(HealthLog log) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.addHealthLog(log);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateHealthLog(HealthLog log) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.updateHealthLog(log);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteHealthLog(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.deleteHealthLog(id);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRecovered(HealthLog log) async {
    final updated = log.copyWith(isRecovered: true);
    await updateHealthLog(updated);
  }
}