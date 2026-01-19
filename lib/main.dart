import 'package:dnd_cuecard_app/app_state.dart';
import 'package:dnd_cuecard_app/logic/database_backup_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/cue_card_creator_view.dart';
import 'screens/cue_card_library_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensure backup exists or create one on startup
  await DatabaseBackupManager.ensureRecentBackup();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final appState = AppState();
        appState.init();
        return appState;
      },
      child: MaterialApp(
        title: 'DnD Cue Cards',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.light),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
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
              Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    if (_isLibraryVisible)
                      Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        width: constraints.maxWidth / 4,
                        child: CueCardLibraryView(),
                      ),
                    Flex(
                      direction: Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            _isLibraryVisible
                                ? Icons.chevron_left
                              : Icons.chevron_right,
                        ),
                        onPressed: () {
                          setState(() {
                            _isLibraryVisible = !_isLibraryVisible;
                          });
                        },
                      ),
                      ]
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: CueCardCreatorView(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}