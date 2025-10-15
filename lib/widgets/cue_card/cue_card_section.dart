import 'package:flutter/material.dart';

class CueCardSection extends StatelessWidget {
  const CueCardSection({
    super.key,
    required this.sectionName,
    required this.flex,
    required this.controller,
  });

  final String sectionName;
  final int flex;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          color: const Color.fromARGB(255, 255, 255, 255),
        ),
        child: TextField(
          controller: controller,
          expands: true,
          maxLines: null,
          textAlignVertical: TextAlignVertical.center,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(8),
              alignLabelWithHint: true),
        ),
      ),
    );
  }
}