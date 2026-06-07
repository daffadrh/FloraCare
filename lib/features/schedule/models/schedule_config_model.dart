class ScheduleConfigModel {
  final String plantId;
  final int waterIntervalDays;
  final bool isFertilizingEnabled;
  final int fertilizeIntervalDays;
  final bool isRepottingEnabled;
  final int repotIntervalDays;
  final bool isRotatingEnabled;
  final int rotateIntervalDays;
  final bool isPesticideEnabled;
  final int pesticideIntervalDays;

  ScheduleConfigModel({
    required this.plantId,
    required this.waterIntervalDays,
    required this.isFertilizingEnabled,
    required this.fertilizeIntervalDays,
    required this.isRepottingEnabled,
    required this.repotIntervalDays,
    required this.isRotatingEnabled,
    required this.rotateIntervalDays,
    required this.isPesticideEnabled,
    required this.pesticideIntervalDays,
  });

  factory ScheduleConfigModel.fromMap(Map<String, dynamic> data, String id) {
    return ScheduleConfigModel(
      plantId: data['plantId'] ?? id,
      waterIntervalDays: data['waterIntervalDays'] ?? 1,
      isFertilizingEnabled: data['isFertilizingEnabled'] ?? false,
      fertilizeIntervalDays: data['fertilizeIntervalDays'] ?? 14,
      isRepottingEnabled: data['isRepottingEnabled'] ?? false,
      repotIntervalDays: data['repotIntervalDays'] ?? 30,
      isRotatingEnabled: data['isRotatingEnabled'] ?? false,
      rotateIntervalDays: data['rotateIntervalDays'] ?? 7,
      isPesticideEnabled: data['isPesticideEnabled'] ?? false,
      pesticideIntervalDays: data['pesticideIntervalDays'] ?? 30,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plantId': plantId,
      'waterIntervalDays': waterIntervalDays,
      'isFertilizingEnabled': isFertilizingEnabled,
      'fertilizeIntervalDays': fertilizeIntervalDays,
      'isRepottingEnabled': isRepottingEnabled,
      'repotIntervalDays': repotIntervalDays,
      'isRotatingEnabled': isRotatingEnabled,
      'rotateIntervalDays': rotateIntervalDays,
      'isPesticideEnabled': isPesticideEnabled,
      'pesticideIntervalDays': pesticideIntervalDays,
    };
  }
}