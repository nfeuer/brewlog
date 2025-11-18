import 'package:hive/hive.dart';
import '../utils/constants.dart';
import 'cup.dart';

part 'shared_cup.g.dart';

@HiveType(typeId: HiveTypeIds.sharedCup)
class SharedCup extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String originalCupId;

  @HiveField(2)
  String originalUserId;

  @HiveField(3)
  String originalUsername;

  @HiveField(4)
  String receivedByUserId;

  // Denormalized cup data for offline access
  @HiveField(5)
  Cup cupData;

  @HiveField(6)
  DateTime sharedAt;

  SharedCup({
    required this.id,
    required this.originalCupId,
    required this.originalUserId,
    required this.originalUsername,
    required this.receivedByUserId,
    required this.cupData,
    DateTime? sharedAt,
  }) : sharedAt = sharedAt ?? DateTime.now();

  // Convert to/from JSON for Firebase sync
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalCupId': originalCupId,
      'originalUserId': originalUserId,
      'originalUsername': originalUsername,
      'receivedByUserId': receivedByUserId,
      'cupData': cupData.toJson(),
      'sharedAt': sharedAt.toIso8601String(),
    };
  }

  factory SharedCup.fromJson(Map<String, dynamic> json) {
    return SharedCup(
      id: json['id'] as String,
      originalCupId: json['originalCupId'] as String,
      originalUserId: json['originalUserId'] as String,
      originalUsername: json['originalUsername'] as String,
      receivedByUserId: json['receivedByUserId'] as String,
      cupData: Cup.fromJson(json['cupData'] as Map<String, dynamic>),
      sharedAt: DateTime.parse(json['sharedAt'] as String),
    );
  }

  // Generate QR code data
  Map<String, dynamic> toQrData() {
    return {
      'type': 'brewlog_cup',
      'version': '1.0',
      'cupId': originalCupId,
      'creatorUsername': originalUsername,
      'data': cupData.toJson(),
    };
  }

  // Parse QR code data
  static SharedCup fromQrData(
    Map<String, dynamic> qrData,
    String receiverUserId,
    String newSharedCupId,
  ) {
    final cupJson = qrData['data'] as Map<String, dynamic>;
    final cup = Cup.fromJson(cupJson);

    return SharedCup(
      id: newSharedCupId,
      originalCupId: qrData['cupId'] as String,
      originalUserId: cup.userId,
      originalUsername: qrData['creatorUsername'] as String,
      receivedByUserId: receiverUserId,
      cupData: cup,
      sharedAt: DateTime.now(),
    );
  }
}
