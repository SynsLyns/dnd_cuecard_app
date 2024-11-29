import 'dart:io';
import 'dart:ui';

import 'package:dnd_cuecard_app/logic/cue_card_database.dart';
import 'package:dnd_cuecard_app/models/card_type.dart';
import 'package:dnd_cuecard_app/models/cue_card.dart';
import 'package:dnd_cuecard_app/models/rarity.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class CueCardCreator {
  static final CueCardDatabase _cueCardDatabase = CueCardDatabase();

  static Future<void> createCueCard(String title, String requirements, String description, String box1, String box2, String notes, List<String> tags, int? type, int? rarity, String? iconFilePath) async {
    iconFilePath = await getIconFilePath(iconFilePath);

    CueCard cueCard = CueCard(
      title: title == '' ? null : title,
      requirements: requirements == '' ? null : requirements,
      description: description == '' ? null : description,
      box1: box1 == '' ? null : box1,
      box2: box2 == '' ? null : box2,
      notes: notes == '' ? null : notes,
      tags: tags,
      dateCreated: DateTime.now(),
      type: type,
      rarity: rarity,
      iconFilePath: iconFilePath,
    );
    
    await _cueCardDatabase.insertCueCard(cueCard);
  }

  static Future<void> updateCueCard(int id, String title, String requirements, String description, String box1, String box2, String notes, List<String> tags, int? type, int? rarity, String? iconFilePath) async {
    iconFilePath = await getIconFilePath(iconFilePath);

    CueCard cueCard = CueCard(
      id: id,
      title: title == '' ? null : title,
      requirements: requirements == '' ? null : requirements,
      description: description == '' ? null : description,
      box1: box1 == '' ? null : box1,
      box2: box2 == '' ? null : box2,
      notes: notes == '' ? null : notes,
      tags: tags,
      dateCreated: DateTime.now(),
      type: type,
      rarity: rarity,
      iconFilePath: iconFilePath,
    );
    
    await _cueCardDatabase.updateCueCard(cueCard);
  }

  static Future<void> createCardType(String name, Color color) async {
    await _cueCardDatabase.insertCardType(CardType(name: name, color: color));
  }

  static Future<void> createRarity(String name, Color color) async {
    await _cueCardDatabase.insertRarity(Rarity(name: name, color: color));
  }

  static Future<String?> getIconFilePath(String? iconFilePath) async {
    Directory appDocDirectory = await getApplicationSupportDirectory();
    String appPath = appDocDirectory.path;
    if (iconFilePath != null && !iconFilePath.startsWith(appPath)) {
      String targetFolder = '$appPath/images';
      Directory(targetFolder).createSync(recursive: true);
      String fileName = '${Uuid().v4()}.png';
      File newImageFile = await File(iconFilePath).copy('$targetFolder/$fileName');
      
      return newImageFile.path;
    }
    return iconFilePath;
  }
}