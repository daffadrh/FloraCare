import 'package:cloud_firestore/cloud_firestore.dart';

class Plant {
  final String id;
  final String userId;
  final String name;
  final String species;
  final DateTime lastWatered;
  final int wateringFrequencyDays;
  final DateTime? lastFertilized;
  final int? fertilizingFrequencyDays;
  final String sunlightRequirement; // Low, Medium, Bright Indirect, Direct, etc.
  final String? imageUrl;
  final String notes;

  const Plant({
    required this.id,
    required this.userId,
    required this.name,
    required this.species,
    required this.lastWatered,
    required this.wateringFrequencyDays,
    this.lastFertilized,
    this.fertilizingFrequencyDays,
    required this.sunlightRequirement,
    this.imageUrl,
    required this.notes,
  });

  // Calculate the next watering date
  DateTime get nextWateringDate {
    return lastWatered.add(Duration(days: wateringFrequencyDays));
  }

  // Calculate the days remaining until next watering
  int get daysUntilWatering {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWater = DateTime(nextWateringDate.year, nextWateringDate.month, nextWateringDate.day);
    return nextWater.difference(today).inDays;
  }

  // Check if plant needs watering today or is overdue
  bool get needsWatering {
    return daysUntilWatering <= 0;
  }

  // Calculate hydration progress (1.0 = fully hydrated/just watered, 0.0 = completely dry/due for water)
  double get hydrationProgress {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastWater = DateTime(lastWatered.year, lastWatered.month, lastWatered.day);
    
    final elapsedDays = today.difference(lastWater).inDays;
    if (elapsedDays <= 0) return 1.0;
    if (elapsedDays >= wateringFrequencyDays) return 0.0;
    
    return (wateringFrequencyDays - elapsedDays) / wateringFrequencyDays;
  }

  // Helper method to copy plant with updated values
  Plant copyWith({
    String? id,
    String? userId,
    String? name,
    String? species,
    DateTime? lastWatered,
    int? wateringFrequencyDays,
    DateTime? lastFertilized,
    int? fertilizingFrequencyDays,
    String? sunlightRequirement,
    String? imageUrl,
    String? notes,
  }) {
    return Plant(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      species: species ?? this.species,
      lastWatered: lastWatered ?? this.lastWatered,
      wateringFrequencyDays: wateringFrequencyDays ?? this.wateringFrequencyDays,
      lastFertilized: lastFertilized ?? this.lastFertilized,
      fertilizingFrequencyDays: fertilizingFrequencyDays ?? this.fertilizingFrequencyDays,
      sunlightRequirement: sunlightRequirement ?? this.sunlightRequirement,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'species': species,
      'lastWatered': Timestamp.fromDate(lastWatered),
      'wateringFrequencyDays': wateringFrequencyDays,
      'lastFertilized': lastFertilized != null ? Timestamp.fromDate(lastFertilized!) : null,
      'fertilizingFrequencyDays': fertilizingFrequencyDays,
      'sunlightRequirement': sunlightRequirement,
      'imageUrl': imageUrl,
      'notes': notes,
    };
  }

  // Create Plant from Firestore Map
  factory Plant.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic field) {
      if (field is Timestamp) {
        return field.toDate();
      } else if (field is String) {
        return DateTime.parse(field);
      } else {
        return DateTime.now();
      }
    }

    return Plant(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      species: map['species'] ?? '',
      lastWatered: parseDate(map['lastWatered']),
      wateringFrequencyDays: map['wateringFrequencyDays'] ?? 7,
      lastFertilized: map['lastFertilized'] != null ? parseDate(map['lastFertilized']) : null,
      fertilizingFrequencyDays: map['fertilizingFrequencyDays'],
      sunlightRequirement: map['sunlightRequirement'] ?? 'Medium',
      imageUrl: map['imageUrl'],
      notes: map['notes'] ?? '',
    );
  }
}
