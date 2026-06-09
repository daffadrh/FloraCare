import 'package:cloud_firestore/cloud_firestore.dart';

class HealthLog {
  final String id;
  final String plantId; 
  final String userId; 
  final DateTime date;
  final String symptoms;
  final String diagnosis;
  final String? photoUrl;
  final String notes;
  final bool isRecovered; 

  const HealthLog({
    required this.id,
    required this.plantId,
    required this.userId,
    required this.date,
    required this.symptoms,
    required this.diagnosis,
    this.photoUrl,
    required this.notes,
    this.isRecovered = false,
  });

  HealthLog copyWith({
    String? id,
    String? plantId,
    String? userId,
    DateTime? date,
    String? symptoms,
    String? diagnosis,
    String? photoUrl,
    String? notes,
    bool? isRecovered,
  }) {
    return HealthLog(
      id: id ?? this.id,
      plantId: plantId ?? this.plantId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      symptoms: symptoms ?? this.symptoms,
      diagnosis: diagnosis ?? this.diagnosis,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
      isRecovered: isRecovered ?? this.isRecovered,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plantId': plantId,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'symptoms': symptoms,
      'diagnosis': diagnosis,
      'photoUrl': photoUrl,
      'notes': notes,
      'isRecovered': isRecovered,
    };
  }

  factory HealthLog.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic field) {
      if (field is Timestamp) {
        return field.toDate();
      } else if (field is String) {
        return DateTime.parse(field);
      } else {
        return DateTime.now();
      }
    }

    return HealthLog(
      id: id,
      plantId: map['plantId'] ?? '',
      userId: map['userId'] ?? '',
      date: parseDate(map['date']),
      symptoms: map['symptoms'] ?? '',
      diagnosis: map['diagnosis'] ?? '',
      photoUrl: map['photoUrl'],
      notes: map['notes'] ?? '',
      isRecovered: map['isRecovered'] ?? false,
    );
  }
}
