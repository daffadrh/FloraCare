import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String userId;
  final String plantId;
  final String plantName;
  final String taskType;
  final DateTime dueDate;
  final bool isCompleted;
  final String notes;

  TaskModel({
    required this.id,
    required this.userId,
    required this.plantId,
    required this.plantName,
    required this.taskType,
    required this.dueDate,
    this.isCompleted = false,
    this.notes = '',
  });

  factory TaskModel.fromMap(Map<String, dynamic> data, String documentId) {
    return TaskModel(
      id: documentId,
      userId: data['userId'] ?? '',
      plantId: data['plantId'] ?? '',
      plantName: data['plantName'] ?? 'Unknown Plant',
      taskType: data['taskType'] ?? 'Watering',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] ?? false,
      notes: data['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'plantId': plantId,
      'plantName': plantName,
      'taskType': taskType,
      'dueDate': Timestamp.fromDate(dueDate),
      'isCompleted': isCompleted,
      'notes': notes,
    };
  }
}