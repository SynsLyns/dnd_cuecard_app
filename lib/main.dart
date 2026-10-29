import 'dart:convert';

import 'package:dnd_cuecard_app/app_state.dart';
import 'package:dnd_cuecard_app/models/initiative_app_state.dart';
import 'package:dnd_cuecard_app/logic/database_backup_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';

import 'screens/cue_card_creator_view.dart';
import 'screens/cue_card_library_view.dart';
import 'screens/initiative_tracker_view.dart';
import 'config/supabase_config.dart';
import 'logic/supabase_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensure backup exists or create one on startup
  await DatabaseBackupManager.ensureRecentBackup();

  // Load Supabase configuration and initialize client if configured
  await SupabaseConfig.loadSavedConfig();
  if (SupabaseConfig.isConfigured) {
    await SupabaseService().initializeClient();
  }

  // Get the current window controller
  final windowController = await WindowController.fromCurrentEngine();
  final arguments = windowController.arguments.isNotEmpty
      ? jsonDecode(windowController.arguments)
      : <String, dynamic>{};

  // Run different apps based on the window type
  // TODO: use a enum here instead of stringly typed routes
  if (arguments['route'] == 'initiative') {
    runApp(
      InitiativeTrackerApp(campaignId: arguments['campaign_id'] as String?),
    );
  } else {
    runApp(const MyApp());
  }
}

/// Build the initiative tracker app for child windows
class InitiativeTrackerApp extends StatelessWidget {
  const InitiativeTrackerApp({super.key, this.campaignId});

  final String? campaignId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => InitiativeAppState(campaignId: campaignId),
      child: MaterialApp(
        title: 'Initiative Tracker',
        theme: AppTheme.light,
        home: const InitiativeTrackerView(),
      ),
    );
  }
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
        theme: AppTheme.light,
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
  final GlobalKey<ScaffoldState> _mobileScaffoldKey =
      GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Scaffold(
            key: _mobileScaffoldKey,
            drawer: Drawer(
              width: constraints.maxWidth * 0.88,
              child: const CueCardLibraryView(),
            ),
            appBar: AppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              leading: IconButton(
                tooltip: 'Open card library',
                icon: const Icon(Icons.menu),
                onPressed: () => _mobileScaffoldKey.currentState?.openDrawer(),
              ),
              title: const Text('DnD Cue Cards'),
            ),
            body: const CueCardCreatorView(),
          );
        }

        final sidebarWidth = (constraints.maxWidth * 0.28).clamp(280.0, 340.0);
        return Scaffold(
          body: Row(
            children: [
              Container(
                color: AppColors.sidebar,
                child: Row(
                  children: [
                    ClipRect(
                      child: AnimatedContainer(
                        width: _isLibraryVisible ? sidebarWidth : 0,
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeInOutCubic,
                        child: OverflowBox(
                          alignment: Alignment.centerLeft,
                          minWidth: sidebarWidth,
                          maxWidth: sidebarWidth,
                          child: IgnorePointer(
                            ignoring: !_isLibraryVisible,
                            child: AnimatedSlide(
                              offset: _isLibraryVisible
                                  ? Offset.zero
                                  : const Offset(-1, 0),
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeInOutCubic,
                              child: SizedBox(
                                width: sidebarWidth,
                                child: const CueCardLibraryView(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      child: Center(
                        child: IconButton(
                          tooltip: _isLibraryVisible
                              ? 'Collapse card library'
                              : 'Expand card library',
                          style: IconButton.styleFrom(
                            foregroundColor: AppColors.matcha,
                            backgroundColor: AppColors.sidebar,
                            minimumSize: const Size(44, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(child: CueCardCreatorView()),
            ],
          ),
        );
      },
    );
  }
}
