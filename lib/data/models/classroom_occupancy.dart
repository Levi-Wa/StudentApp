class ClassroomPair {
  final int pairId;
  final int pairNumb;
  final String timeStart;
  final String timeEnd;

  ClassroomPair({
    required this.pairId,
    required this.pairNumb,
    required this.timeStart,
    required this.timeEnd,
  });

  factory ClassroomPair.fromJson(Map<String, dynamic> json) {
    return ClassroomPair(
      pairId: json['Pair_ID'] is int
          ? json['Pair_ID'] as int
          : int.tryParse(json['Pair_ID']?.toString() ?? '0') ?? 0,
      pairNumb: json['PairNumb'] is int
          ? json['PairNumb'] as int
          : int.tryParse(json['PairNumb']?.toString() ?? '1') ?? 1,
      timeStart: json['TimeStart']?.toString() ?? '',
      timeEnd: json['TimeEnd']?.toString() ?? '',
    );
  }

  String get timeFormatted => '$timeStart — $timeEnd';
}

class Classroom {
  final int audId;
  final String audName;
  final String audTypeName;
  final int volume;

  Classroom({
    required this.audId,
    required this.audName,
    required this.audTypeName,
    required this.volume,
  });

  factory Classroom.fromJson(Map<String, dynamic> json) {
    return Classroom(
      audId: json['Aud_ID'] is int
          ? json['Aud_ID'] as int
          : int.tryParse(json['Aud_ID']?.toString() ?? '0') ?? 0,
      audName: json['AudName']?.toString().trim() ?? '',
      audTypeName: json['AudTypeName']?.toString().trim() ?? '',
      volume: json['Volume'] is int
          ? json['Volume'] as int
          : int.tryParse(json['Volume']?.toString() ?? '0') ?? 0,
    );
  }
}

class ClassroomBuilding {
  final int buildingId;
  final String buildingName;
  final List<Classroom> auds;

  ClassroomBuilding({
    required this.buildingId,
    required this.buildingName,
    required this.auds,
  });

  factory ClassroomBuilding.fromJson(Map<String, dynamic> json) {
    final rawAuds = json['Auds'];
    final List<Classroom> audsList = [];
    if (rawAuds is List) {
      for (final a in rawAuds) {
        if (a is Map<String, dynamic>) {
          audsList.add(Classroom.fromJson(a));
        }
      }
    }

    return ClassroomBuilding(
      buildingId: json['Building_ID'] is int
          ? json['Building_ID'] as int
          : int.tryParse(json['Building_ID']?.toString() ?? '0') ?? 0,
      buildingName: json['BuildingName']?.toString().trim() ?? '',
      auds: audsList,
    );
  }
}

class ClassroomOccupancyData {
  final List<ClassroomPair> pairs;
  final List<ClassroomBuilding> buildings;

  ClassroomOccupancyData({
    required this.pairs,
    required this.buildings,
  });

  factory ClassroomOccupancyData.fromJson(Map<String, dynamic> json) {
    final rawPairs = json['Pairs'];
    final List<ClassroomPair> pairsList = [];
    if (rawPairs is List) {
      for (final p in rawPairs) {
        if (p is Map<String, dynamic>) {
          pairsList.add(ClassroomPair.fromJson(p));
        }
      }
    }

    final rawBuildings = json['Buildings'];
    final List<ClassroomBuilding> buildingsList = [];
    if (rawBuildings is List) {
      for (final b in rawBuildings) {
        if (b is Map<String, dynamic>) {
          buildingsList.add(ClassroomBuilding.fromJson(b));
        }
      }
    }

    return ClassroomOccupancyData(
      pairs: pairsList,
      buildings: buildingsList,
    );
  }
}
