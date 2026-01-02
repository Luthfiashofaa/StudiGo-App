import 'package:flutter/material.dart';

class Mission {
  final String id;
  final String title;
  final int progress;
  final int total;
  final String iconKey;

  const Mission({
    required this.id,
    required this.title,
    required this.progress,
    required this.total,
    required this.iconKey,
  });

  bool get isComplete => progress >= total;

  Mission copyWith({int? progress}) {
    return Mission(
      id: id,
      title: title,
      progress: progress ?? this.progress,
      total: total,
      iconKey: iconKey,
    );
  }

  IconData get icon => _iconFromKey(iconKey);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'progress': progress,
    'total': total,
    'iconKey': iconKey,
  };

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] as String,
      title: json['title'] as String,
      progress: json['progress'] as int,
      total: json['total'] as int,
      iconKey: json['iconKey'] as String,
    );
  }
}

class DayHistory {
  final int dayNumber;
  final String dateIso; // yyyy-MM-dd
  final List<String> completedMissions;

  const DayHistory({
    required this.dayNumber,
    required this.dateIso,
    required this.completedMissions,
  });

  Map<String, dynamic> toJson() => {
    'dayNumber': dayNumber,
    'dateIso': dateIso,
    'completedMissions': completedMissions,
  };

  factory DayHistory.fromJson(Map<String, dynamic> json) {
    return DayHistory(
      dayNumber: json['dayNumber'] as int,
      dateIso: json['dateIso'] as String,
      completedMissions: (json['completedMissions'] as List<dynamic>)
          .cast<String>(),
    );
  }
}

IconData _iconFromKey(String key) {
  switch (key) {
    case 'track_changes':
      return Icons.track_changes;
    case 'assignment_turned_in':
      return Icons.assignment_turned_in;
    case 'whatshot':
      return Icons.whatshot;
    case 'event_seat':
      return Icons.event_seat;
    default:
      return Icons.flag;
  }
}
