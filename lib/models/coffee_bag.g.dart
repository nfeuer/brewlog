// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coffee_bag.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CoffeeBagAdapter extends TypeAdapter<CoffeeBag> {
  @override
  final int typeId = 1;

  @override
  CoffeeBag read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CoffeeBag(
      id: fields[0] as String,
      userId: fields[1] as String,
      customTitle: fields[2] as String,
      labelPhotoPath: fields[3] as String?,
      coffeeName: fields[4] as String,
      roaster: fields[5] as String,
      farmer: fields[6] as String?,
      variety: fields[7] as String?,
      elevation: fields[8] as String?,
      beanAroma: fields[9] as String?,
      datePurchased: fields[10] as DateTime?,
      price: fields[11] as double?,
      bagSizeGrams: fields[12] as double?,
      roastDate: fields[13] as DateTime?,
      openDate: fields[14] as DateTime?,
      finishedDate: fields[15] as DateTime?,
      bagStatusIndex: fields[16] as int,
      totalCups: fields[17] as int,
      avgScore: fields[18] as double?,
      bestCupId: fields[19] as String?,
      createdAt: fields[20] as DateTime,
      updatedAt: fields[21] as DateTime,
      fieldVisibility: (fields[22] as Map?)?.cast<String, bool>(),
      recommendedRestDays: fields[23] as int?,
      processingMethods: (fields[24] as List?)?.cast<String>(),
      region: fields[25] as String?,
      harvestDate: fields[26] as DateTime?,
      roastLevel: fields[27] as String?,
      roastProfile: fields[28] as String?,
      beanSize: fields[29] as String?,
      certifications: (fields[30] as List?)?.cast<String>(),
      customProcessingMethod: fields[31] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CoffeeBag obj) {
    writer
      ..writeByte(32)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.customTitle)
      ..writeByte(3)
      ..write(obj.labelPhotoPath)
      ..writeByte(4)
      ..write(obj.coffeeName)
      ..writeByte(5)
      ..write(obj.roaster)
      ..writeByte(6)
      ..write(obj.farmer)
      ..writeByte(7)
      ..write(obj.variety)
      ..writeByte(8)
      ..write(obj.elevation)
      ..writeByte(9)
      ..write(obj.beanAroma)
      ..writeByte(10)
      ..write(obj.datePurchased)
      ..writeByte(11)
      ..write(obj.price)
      ..writeByte(12)
      ..write(obj.bagSizeGrams)
      ..writeByte(13)
      ..write(obj.roastDate)
      ..writeByte(14)
      ..write(obj.openDate)
      ..writeByte(15)
      ..write(obj.finishedDate)
      ..writeByte(16)
      ..write(obj.bagStatusIndex)
      ..writeByte(17)
      ..write(obj.totalCups)
      ..writeByte(18)
      ..write(obj.avgScore)
      ..writeByte(19)
      ..write(obj.bestCupId)
      ..writeByte(20)
      ..write(obj.createdAt)
      ..writeByte(21)
      ..write(obj.updatedAt)
      ..writeByte(22)
      ..write(obj.fieldVisibility)
      ..writeByte(23)
      ..write(obj.recommendedRestDays)
      ..writeByte(24)
      ..write(obj.processingMethods)
      ..writeByte(25)
      ..write(obj.region)
      ..writeByte(26)
      ..write(obj.harvestDate)
      ..writeByte(27)
      ..write(obj.roastLevel)
      ..writeByte(28)
      ..write(obj.roastProfile)
      ..writeByte(29)
      ..write(obj.beanSize)
      ..writeByte(30)
      ..write(obj.certifications)
      ..writeByte(31)
      ..write(obj.customProcessingMethod);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoffeeBagAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
