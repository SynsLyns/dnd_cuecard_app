import 'package:dnd_cuecard_app/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dnd_cuecard_app/widgets/cue_card_widgets/hoverable_cue_card.dart';

class CueCardLibraryView extends StatefulWidget {
  const CueCardLibraryView({super.key});

  @override
  State<CueCardLibraryView> createState() => _CueCardLibraryViewState();
}

class _CueCardLibraryViewState extends State<CueCardLibraryView> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    final cueCards = appState.cueCards;

    if (cueCards.isEmpty) {
      return const Center(child: Text('No cue cards found'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: cueCards.length,
      itemBuilder: (context, index) {
        final cueCard = cueCards[index];
        return HoverableCueCard(cueCard: cueCard);
      },
    );
  }
}

