import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/plant_model.dart';

class InventoryService {
  final _mockController = StreamController<List<Plant>>.broadcast();
  final List<Plant> _mockPlants = [];

  InventoryService() {
    if (!_isFirebaseAvailable) {
      _initMockData();
    }
  }

  // Check if Firebase was successfully initialized
  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Set up mock data for offline runs
  void _initMockData() {
    final now = DateTime.now();
    _mockPlants.addAll([
      Plant(
        id: 'mock_plant_1',
        userId: 'mock_user',
        name: 'Monty',
        species: 'Monstera Deliciosa',
        lastWatered: now.subtract(const Duration(days: 4)),
        wateringFrequencyDays: 7,
        lastFertilized: now.subtract(const Duration(days: 15)),
        fertilizingFrequencyDays: 30,
        sunlightRequirement: 'Bright Indirect',
        imageUrl: null, // UI will render a fallback plant icon or colored placeholder
        notes: 'Enjoys high humidity. Clean leaves monthly with a damp cloth.',
      ),
      Plant(
        id: 'mock_plant_2',
        userId: 'mock_user',
        name: 'Slyther',
        species: 'Sansevieria (Snake Plant)',
        lastWatered: now.subtract(const Duration(days: 14)),
        wateringFrequencyDays: 21,
        lastFertilized: null,
        fertilizingFrequencyDays: null,
        sunlightRequirement: 'Low to Medium',
        imageUrl: null,
        notes: 'Extremely resilient. Do not overwater. Allow soil to dry completely.',
      ),
      Plant(
        id: 'mock_plant_3',
        userId: 'mock_user',
        name: 'Ivy',
        species: 'Golden Pothos',
        lastWatered: now.subtract(const Duration(days: 6)),
        wateringFrequencyDays: 5, // Overdue for watering!
        lastFertilized: now.subtract(const Duration(days: 20)),
        fertilizingFrequencyDays: 30,
        sunlightRequirement: 'Medium Indirect',
        imageUrl: null,
        notes: 'Vines are growing nicely. Propagate clippings in water soon.',
      ),
    ]);
    _mockController.add(List.from(_mockPlants));
  }

  // Stream of all plants for a user
  Stream<List<Plant>> streamUserPlants(String userId) {
    if (_isFirebaseAvailable) {
      return FirebaseFirestore.instance
          .collection('plants')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => Plant.fromMap(doc.id, doc.data())).toList();
      });
    } else {
      // Return local stream
      Timer.run(() => _mockController.add(List.from(_mockPlants)));
      return _mockController.stream;
    }
  }

  // Create/Add a plant
  Future<void> addPlant(Plant plant) async {
    if (_isFirebaseAvailable) {
      try {
        await FirebaseFirestore.instance.collection('plants').add(plant.toMap());
      } catch (e) {
        throw Exception('Failed to add plant to Firestore: $e');
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 400));
      final newPlant = plant.copyWith(
        id: 'mock_plant_${DateTime.now().millisecondsSinceEpoch}',
      );
      _mockPlants.add(newPlant);
      _mockController.add(List.from(_mockPlants));
    }
  }

  // Update a plant
  Future<void> updatePlant(Plant plant) async {
    if (_isFirebaseAvailable) {
      try {
        await FirebaseFirestore.instance
            .collection('plants')
            .doc(plant.id)
            .update(plant.toMap());
      } catch (e) {
        throw Exception('Failed to update plant in Firestore: $e');
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 400));
      final index = _mockPlants.indexWhere((p) => p.id == plant.id);
      if (index != -1) {
        _mockPlants[index] = plant;
        _mockController.add(List.from(_mockPlants));
      } else {
        throw Exception('Plant not found in local mock database.');
      }
    }
  }

  // Delete a plant
  Future<void> deletePlant(String plantId) async {
    if (_isFirebaseAvailable) {
      try {
        await FirebaseFirestore.instance.collection('plants').doc(plantId).delete();
      } catch (e) {
        throw Exception('Failed to delete plant from Firestore: $e');
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 300));
      _mockPlants.removeWhere((p) => p.id == plantId);
      _mockController.add(List.from(_mockPlants));
    }
  }
}
