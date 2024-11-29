import 'package:dnd_cuecard_app/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/cue_card_creator_view.dart';
import 'screens/cue_card_library_view.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: 'DnD Cue Cards',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLibraryVisible = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              if (_isLibraryVisible)
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: constraints.maxWidth / 4,
                  child: CueCardLibraryView(),
                ),
              IconButton(
                icon: Icon(_isLibraryVisible ? Icons.chevron_left : Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _isLibraryVisible = !_isLibraryVisible;
                  });
                },
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: CueCardCreatorView(),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}