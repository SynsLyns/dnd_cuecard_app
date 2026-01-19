import 'dart:async';
import 'dart:io';

import 'package:dnd_cuecard_app/app_state.dart';
import 'package:dnd_cuecard_app/models/cue_card.dart';
import 'package:dnd_cuecard_app/models/tag.dart';
import 'package:dnd_cuecard_app/widgets/tag/tag_chip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dnd_cuecard_app/widgets/cue_card/hoverable_cue_card.dart';

class CueCardLibraryView extends StatefulWidget {
  const CueCardLibraryView({super.key});

  @override
  State<CueCardLibraryView> createState() => _CueCardLibraryViewState();
}

class _CueCardLibraryViewState extends State<CueCardLibraryView> {
  final List<Tag> _selectedTags = [];
  int _cueCardsPerPage = 1;

  Timer? _debounce;

  void _onSearchChanged(AppState appState, [String? text, List<Tag>? tags]) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      appState.updateFilteredCueCards(text: text, tags: tags);
    });
  }

  @override
  Widget build(BuildContext context) {
    AppState appState = context.watch<AppState>();
    final List<CueCard> filteredCueCards = appState.cueCards;

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTagList(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildAutocomplete()
          ),
          Expanded(
            child: filteredCueCards.isEmpty
                ? _buildEmptyState()
                : _buildCardListWithPagination(appState, filteredCueCards),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('No matching cue cards found'),
    );
  }

  Widget _buildCardListWithPagination(AppState appState, List<CueCard> filteredCueCards) {
    return Column(
      children: [
        Expanded(
          child: _buildCardList(appState, filteredCueCards),
        ),
        _buildPaginationControls(appState),
      ],
    );
  }

  Widget _buildCardList(AppState appState, List<CueCard> filteredCueCards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        _cueCardsPerPage = (availableHeight / 72.0).floor();
        if (_cueCardsPerPage < 1) _cueCardsPerPage = 1;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          appState.setItemsPerPage(_cueCardsPerPage);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: filteredCueCards.length,
          itemBuilder: (context, index) {
            final cueCard = filteredCueCards[index];
            return _buildCardItem(cueCard, appState);
          },
        );
      },
    );
  }

  Widget _buildCardItem(CueCard cueCard, AppState appState) {
    final cardWidget = HoverableCueCard(cueCard: cueCard);
    
    if (appState.isRelationshipMode) {
      return Draggable<CueCard>(
        data: cueCard,
        feedback: _buildDraggableFeedback(cueCard),
        child: cardWidget,
      );
    }
    return cardWidget;
  }

  Widget _buildDraggableFeedback(CueCard cueCard) {
    return Material(
      elevation: 6,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(8),
        color: Colors.white,
        child: Row(
          children: [
            if (cueCard.iconFilePath != null)
              SizedBox(
                width: 40,
                height: 40,
                child: Image.file(File(cueCard.iconFilePath!), fit: BoxFit.cover),
              ),
            const SizedBox(width: 8),
            Expanded(child: Text(cueCard.title ?? 'Untitled')),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls(AppState appState) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: appState.currentPage > 1
                ? () => appState.goToPage(appState.currentPage - 1)
                : null,
          ),
          Text('Page ${appState.currentPage} of ${appState.totalPages}'),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: appState.currentPage < appState.totalPages
                ? () => appState.goToPage(appState.currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTagList() {
    AppState appState = context.watch<AppState>();
    return _selectedTags.isEmpty ? const SizedBox(height: 32) :
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _selectedTags.map((tag) {
          void removeTag(Tag tag) {
            setState(() {
              _selectedTags.remove(tag);
              _onSearchChanged(appState, null, _selectedTags);
            });
          }
          return TagChip(
            tag: tag.name,
            onRemove: () => removeTag(tag),
          );
        }).toList(),
      );
  }

  Widget _buildAutocomplete() {
    AppState appState = context.watch<AppState>();
    List<Tag> suggestions = appState.tags;
    late final TextEditingController controller;
    late final FocusNode focusNode;

    void addTag(Tag tag) {
      controller.clear();
      focusNode.unfocus();
      if (_selectedTags.any((t) => t.name == tag.name)) return;
      setState(() {
        _selectedTags.add(tag);
        _onSearchChanged(appState, null, _selectedTags);
      });
    }

    return Autocomplete<Tag>(
      key: ValueKey(suggestions.map((tag) => tag.id).join(',')),
      optionsBuilder: (TextEditingValue textEditingValue) {
        return suggestions.where((option) =>
            !_selectedTags.any((t) => t.name == option.name) &&
            (textEditingValue.text.isEmpty ||
                option.name.toLowerCase().contains(textEditingValue.text.toLowerCase())));
      },
      displayStringForOption: (option) => option.name,
      onSelected: addTag,
      fieldViewBuilder:
          (context, textEditingController, textFocusNode, onFieldSubmitted) {
        textEditingController.addListener(() {
          if (appState.searchText != textEditingController.text) {
            _onSearchChanged(appState, textEditingController.text);
          }
        });
        controller = textEditingController;
        focusNode = textFocusNode;
        return TextField(
          controller: textEditingController,
          focusNode: textFocusNode,
          decoration: const InputDecoration(
            labelText: 'Search by tag or title',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (String value) {
            final tag = suggestions.firstWhere(
                (element) => element.name.toLowerCase() == value.toLowerCase(),
                orElse: () => Tag(name: ''));
            if (tag.name.isNotEmpty) {
              addTag(tag);
            }
          },
        );
      },
    );
  }
}


