import 'dart:io';
import 'package:dnd_cuecard_app/app_state.dart';
import 'package:dnd_cuecard_app/models/cue_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HoverableCueCard extends StatefulWidget {
  const HoverableCueCard({super.key, required this.cueCard});

  final CueCard cueCard;

  @override
  State<HoverableCueCard> createState() => _HoverableCueCardState();
}

class _HoverableCueCardState extends State<HoverableCueCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final borderRadius = BorderRadius.circular(8.0);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius, 
      ),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: () => appState.selectCard(widget.cueCard),
        onHover: (hovering) => setState(() => _isHovered = hovering),
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 16.0, right: 8.0),
          title: Text(
            widget.cueCard.title ?? 'Untitled',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          subtitle: Text(
            widget.cueCard.description ?? 'No description',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          leading: widget.cueCard.iconFilePath != null
              ? SizedBox(
                  width: 40,
                  height: 40,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      File(widget.cueCard.iconFilePath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : null,
          trailing: _isHovered
              ? IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => appState.removeCueCard(widget.cueCard.id!),
                )
              : null,
        ),
      ),
    );
  }
}
