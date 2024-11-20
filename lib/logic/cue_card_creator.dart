import 'dart:io';

import 'package:dnd_cuecard_app/enums/card_type.dart';
import 'package:dnd_cuecard_app/enums/rarity.dart';
import 'package:dnd_cuecard_app/logic/cue_card_database.dart';
import 'package:dnd_cuecard_app/models/cue_card.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class CueCardCreator {
  static final CueCardDatabase _cueCardDatabase = CueCardDatabase();

  static Future<void> createCueCard(String title, String requirements, String description, String box1, String box2, String notes, List<String> tags, String type, String rarity, String? iconFilePath) async {
    
    print('Application Support Directory: ${await getApplicationSupportDirectory()}');
    print('Application Documents Directory: ${await getApplicationDocumentsDirectory()}');
    print('Application Cache Directory: ${await getApplicationCacheDirectory()}');
    if (iconFilePath != null) {
      Directory appDocDirectory = await getApplicationSupportDirectory();
      String appPath = appDocDirectory.path;
      
      String targetFolder = '$appPath/images';
      Directory(targetFolder).createSync(recursive: true);
      String fileName = Uuid().v4();
      File newImageFile = await File(iconFilePath).copy('$targetFolder/$fileName');
      
      iconFilePath = newImageFile.path;
    }

    CueCard cueCard = CueCard(
      title: title == '' ? null : title,
      requirements: requirements == '' ? null : requirements,
      description: description == '' ? null : description,
      box1: box1 == '' ? null : box1,
      box2: box2 == '' ? null : box2,
      notes: notes == '' ? null : notes,
      tags: tags,
      dateCreated: DateTime.now(),
      type: type == '' ? null : CardType.values.byName(type),
      rarity: rarity == '' ? null : Rarity.values.byName(rarity),
      iconFilePath: iconFilePath,
    );
    
    await _cueCardDatabase.insertCueCard(cueCard);
  }
}