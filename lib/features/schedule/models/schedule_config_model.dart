class ScheduleConfigModel {
  final String plantId;
  final int waterIntervalDays;
  final bool isFertilizingEnabled;
  final int fertilizeIntervalDays;
  final bool isRepottingEnabled;
  final int repotIntervalMonths; // Diubah menjadi bulan
  final bool isPesticideEnabled;
  final int pesticideIntervalDays;

  // Tanggal terakhir setiap perawatan dilakukan
  final DateTime lastWateredDate;
  final DateTime lastFertilizedDate;
  final DateTime lastRepottedDate;
  final DateTime lastPesticideDate;

  ScheduleConfigModel({
    required this.plantId,
    required this.waterIntervalDays,
    required this.isFertilizingEnabled,
    required this.fertilizeIntervalDays,
    required this.isRepottingEnabled,
    required this.repotIntervalMonths,
    required this.isPesticideEnabled,
    required this.pesticideIntervalDays,
    required this.lastWateredDate,
    required this.lastFertilizedDate,
    required this.lastRepottedDate,
    required this.lastPesticideDate,
  });

  factory ScheduleConfigModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic dateData) {
      if (dateData == null) return DateTime.now();
      if (dateData is String) return DateTime.tryParse(dateData) ?? DateTime.now();
      // Jika suatu saat menggunakan Timestamp dari Firestore
      try { return dateData.toDate(); } catch (_) { return DateTime.now(); }
    }

    return ScheduleConfigModel(
      plantId: data['plantId'] ?? id,
      waterIntervalDays: data['waterIntervalDays'] ?? 1,
      isFertilizingEnabled: data['isFertilizingEnabled'] ?? false,
      fertilizeIntervalDays: data['fertilizeIntervalDays'] ?? 14,
      isRepottingEnabled: data['isRepottingEnabled'] ?? false,
      repotIntervalMonths: data['repotIntervalMonths'] ?? 6, // Default 6 bulan
      isPesticideEnabled: data['isPesticideEnabled'] ?? false,
      pesticideIntervalDays: data['pesticideIntervalDays'] ?? 30,
      lastWateredDate: parseDate(data['lastWateredDate']),
      lastFertilizedDate: parseDate(data['lastFertilizedDate']),
      lastRepottedDate: parseDate(data['lastRepottedDate']),
      lastPesticideDate: parseDate(data['lastPesticideDate']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plantId': plantId,
      'waterIntervalDays': waterIntervalDays,
      'isFertilizingEnabled': isFertilizingEnabled,
      'fertilizeIntervalDays': fertilizeIntervalDays,
      'isRepottingEnabled': isRepottingEnabled,
      'repotIntervalMonths': repotIntervalMonths,
      'isPesticideEnabled': isPesticideEnabled,
      'pesticideIntervalDays': pesticideIntervalDays,
      'lastWateredDate': lastWateredDate.toIso8601String(),
      'lastFertilizedDate': lastFertilizedDate.toIso8601String(),
      'lastRepottedDate': lastRepottedDate.toIso8601String(),
      'lastPesticideDate': lastPesticideDate.toIso8601String(),
    };
  }
}