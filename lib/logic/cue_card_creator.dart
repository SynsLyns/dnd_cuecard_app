import 'dart:io';
import 'dart:ui';

import 'package:dnd_cuecard_app/logic/cue_card_database.dart';
import 'package:dnd_cuecard_app/models/card_type.dart';
import 'package:dnd_cuecard_app/models/cue_card.dart';
import 'package:dnd_cuecard_app/models/rarity.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

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
    if (iconFilePath == null) {
      return null;
    }

    Directory appDocDirectory = await getApplicationSupportDirectory();
    String appPath = appDocDirectory.path;
    String targetFolder = '$appPath/images';

    if (iconFilePath.startsWith(targetFolder)) {
      return iconFilePath;
    }

    // Ensure the target folder exists.
    await Directory(targetFolder).create(recursive: true);
  
    File file = File(iconFilePath);
    List<int> imageBytes = await file.readAsBytes();
    String hash = md5.convert(imageBytes).toString();

    // Check if the file already exists in the target folder by comparing hashes.
    String existingFilePath = '$targetFolder/$hash';
    if (await File(existingFilePath).exists()) {
      return existingFilePath;
    }

    // If it's a new image from outside the app's directory, copy it.
    String newFileName = '$hash.png';
    File newImageFile = await File(iconFilePath).copy('$targetFolder/$newFileName');
    
    return newImageFile.path;
  }

  static Future<List<String>> getAllIconFilePaths() async {
    Directory appDocDirectory = await getApplicationSupportDirectory();
    String targetFolder = '${appDocDirectory.path}/images';
    Directory imageDirectory = Directory(targetFolder);

    if (!await imageDirectory.exists()) {
      return [];
    }

    List<String> iconPaths = [];
    await for (var entity in imageDirectory.list(recursive: false, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.png')) {
        iconPaths.add(entity.path);
      }
    }
    return iconPaths;
  }
}