import 'dart:async';
import 'package:flutter/material.dart';
import '../models/plant_model.dart';
import '../services/inventory_service.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryService _service = InventoryService();
  StreamSubscription<List<Plant>>? _subscription;

  List<Plant> _allPlants = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Search & Filtering states
  String _searchQuery = '';
  String _selectedSunlightFilter = 'All';
  bool _filterNeedsWaterOnly = false;
  String _sortBy = 'nextWatering'; // nextWatering, nameAsc, nameDesc, hydration

  InventoryProvider();

  // Initialize stream subscription for the current user
  void init(String userId) {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = _service.streamUserPlants(userId).listen(
      (plants) {
        _allPlants = plants;
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

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedSunlightFilter => _selectedSunlightFilter;
  bool get filterNeedsWaterOnly => _filterNeedsWaterOnly;
  String get sortBy => _sortBy;
  List<Plant> get allPlantsRaw => _allPlants;

  // Filtered and sorted plants list
  List<Plant> get plants {
    List<Plant> filtered = List.from(_allPlants);

    // Apply Search Query filter (by name or species)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((p) => p.name.toLowerCase().contains(query) || p.species.toLowerCase().contains(query))
          .toList();
    }

    // Apply Sunlight Requirement filter
    if (_selectedSunlightFilter != 'All') {
      filtered = filtered
          .where((p) => p.sunlightRequirement.toLowerCase() == _selectedSunlightFilter.toLowerCase())
          .toList();
    }

    // Apply Needs Water Only filter
    if (_filterNeedsWaterOnly) {
      filtered = filtered.where((p) => p.needsWatering).toList();
    }

    // Apply Sorting
    switch (_sortBy) {
      case 'nameAsc':
        filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'nameDesc':
        filtered.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 'hydration':
        filtered.sort((a, b) => a.hydrationProgress.compareTo(b.hydrationProgress));
        break;
      case 'nextWatering':
      default:
        filtered.sort((a, b) => a.daysUntilWatering.compareTo(b.daysUntilWatering));
        break;
    }

    return filtered;
  }

  // Filter update calls
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSunlightFilter(String filter) {
    _selectedSunlightFilter = filter;
    notifyListeners();
  }

  void setNeedsWaterOnly(bool value) {
    _filterNeedsWaterOnly = value;
    notifyListeners();
  }

  void setSortBy(String criteria) {
    _sortBy = criteria;
    notifyListeners();
  }

  // CRUD Operations delegate
  Future<void> addPlant(Plant plant) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.addPlant(plant);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePlant(Plant plant) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.updatePlant(plant);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePlant(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.deletePlant(id);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Quick Action: Water plant today
  Future<void> waterPlant(Plant plant) async {
    final updated = plant.copyWith(
      lastWatered: DateTime.now(),
    );
    await updatePlant(updated);
  }
}
