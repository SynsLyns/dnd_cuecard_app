import 'dart:io';

import 'package:dnd_cuecard_app/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: ListTile(
            title: Text(cueCard.title ?? 'Untitled'),
            subtitle: Text(cueCard.description ?? 'No description'),
            leading: cueCard.iconFilePath != null 
              ? SizedBox(
                  width: 40,
                  height: 40,
                  child: Image.file(
                    File(cueCard.iconFilePath!),
                    fit: BoxFit.cover,
                  ),
                )
              : null,
            onTap: () {
              appState.selectCard(cueCard);
            },
          ),
        );
      },
    );
  }
}

