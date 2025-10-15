import 'package:dnd_cuecard_app/app_state.dart';
import 'package:dnd_cuecard_app/models/cue_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dnd_cuecard_app/widgets/cue_card_widgets/hoverable_cue_card.dart';

class CueCardLibraryView extends StatefulWidget {
  const CueCardLibraryView({super.key});

  @override
  State<CueCardLibraryView> createState() => _CueCardLibraryViewState();
}

class _CueCardLibraryViewState extends State<CueCardLibraryView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppState appState = context.watch<AppState>();
    final List<CueCard> allCueCards = appState.cueCards;

    final filteredCueCards = allCueCards.where((cueCard) {
      return (cueCard.title ?? '').toLowerCase().contains(_searchText.toLowerCase());
    }).toList();

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: filteredCueCards.isEmpty
                ? Center(
                    child: Text(
                      _searchText.isEmpty
                          ? 'No cue cards found'
                          : 'No matching cue cards found',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: filteredCueCards.length,
                    itemBuilder: (context, index) {
                      final cueCard = filteredCueCards[index];
                      return HoverableCueCard(cueCard: cueCard);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

