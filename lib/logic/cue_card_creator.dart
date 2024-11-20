import 'package:dnd_cuecard_app/enums/card_type.dart';
import 'package:dnd_cuecard_app/enums/rarity.dart';
import 'package:dnd_cuecard_app/logic/cue_card_database.dart';
import 'package:dnd_cuecard_app/models/cue_card.dart';

class CueCardCreator {
  static final CueCardDatabase _cueCardDatabase = CueCardDatabase();

  static Future<void> createCueCard(String title, String requirements, String description, String box1, String box2, String notes, List<String> tags, String type, String rarity, String? iconFilePath) async {
    
    if (iconFilePath != null) {
      // Save icon....
    }

    CueCard cueCard = CueCard(
      title: title,
      requirements: requirements,
      description: description,
      box1: box1,
      box2: box2,
      notes: notes,
      tags: tags,
      dateCreated: DateTime.now(),
      type: CardType.values.byName(type),
      rarity: Rarity.values.byName(rarity),
      iconFilePath: iconFilePath,
    );
    
    await _cueCardDatabase.insertCueCard(cueCard);
  }
}