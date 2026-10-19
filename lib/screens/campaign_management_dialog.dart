import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../config/supabase_config.dart';
import '../logic/supabase_service.dart';

class CampaignManagementDialog extends StatefulWidget {
  const CampaignManagementDialog({super.key});

  @override
  State<CampaignManagementDialog> createState() =>
      _CampaignManagementDialogState();
}

class _CampaignManagementDialogState extends State<CampaignManagementDialog> {
  final _supabaseService = SupabaseService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _campaignNameController = TextEditingController();

  final _urlController = TextEditingController(text: SupabaseConfig.url);
  final _anonKeyController = TextEditingController(
    text: SupabaseConfig.anonKey,
  );
  final _webUrlController = TextEditingController(
    text: SupabaseConfig.webBaseUrl,
  );

  bool _isLoading = false;
  String? _errorMessage;
  String? _infoMessage;
  bool _showConfig = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _campaignNameController.dispose();
    _urlController.dispose();
    _anonKeyController.dispose();
    _webUrlController.dispose();
    super.dispose();
  }

  void _setMessage({String? error, String? info}) {
    setState(() {
      _errorMessage = error;
      _infoMessage = info;
    });
  }

  Future<void> _saveConfig() async {
    setState(() => _isLoading = true);
    _setMessage();
    try {
      await SupabaseConfig.saveConfig(
        url: _urlController.text,
        anonKey: _anonKeyController.text,
        webBaseUrl: _webUrlController.text,
      );
      final initialized = await _supabaseService.initializeClient(
        _urlController.text,
        _anonKeyController.text,
      );
      if (!initialized) {
        throw CloudSharingException(
          'Supabase could not be initialized. Verify the project URL and anon key.',
        );
      }
      if (mounted) {
        await context.read<AppState>().loadCampaigns();
      }
      _setMessage(info: 'Supabase configuration saved.');
      setState(() => _showConfig = false);
    } catch (e) {
      _setMessage(error: 'Failed to initialize: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _setMessage(error: 'Please enter both email and password.');
      return;
    }

    setState(() => _isLoading = true);
    _setMessage();
    try {
      await _supabaseService.signInWithPassword(
        email: email,
        password: password,
      );
      if (mounted) {
        await context.read<AppState>().loadCampaigns();
      }
      _setMessage(info: 'Signed in successfully.');
    } catch (e) {
      _setMessage(error: e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _setMessage(error: 'Please enter both email and password.');
      return;
    }

    setState(() => _isLoading = true);
    _setMessage();
    try {
      await _supabaseService.signUpWithPassword(
        email: email,
        password: password,
      );
      if (mounted) {
        await context.read<AppState>().loadCampaigns();
      }
      _setMessage(info: 'Account registered. You may now sign in.');
    } catch (e) {
      _setMessage(error: e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    _setMessage();
    try {
      await _supabaseService.signOut();
      if (mounted) {
        context.read<AppState>().setActiveCampaign(null);
        context.read<AppState>().campaigns.clear();
      }
      _setMessage(info: 'Signed out.');
    } catch (e) {
      _setMessage(error: e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createCampaign() async {
    final name = _campaignNameController.text.trim();
    if (name.isEmpty) {
      _setMessage(error: 'Please enter a campaign name.');
      return;
    }

    setState(() => _isLoading = true);
    _setMessage();
    try {
      final appState = context.read<AppState>();
      final campaign = await _supabaseService.createCampaign(name);
      _campaignNameController.clear();
      if (mounted) {
        await appState.loadCampaigns();
        appState.setActiveCampaign(campaign.id);
      }
      _setMessage(
        info:
            'Campaign "${campaign.name}" created with code: ${campaign.joinCode}',
      );
    } catch (e) {
      _setMessage(error: e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCampaign(String campaignId) async {
    setState(() => _isLoading = true);
    _setMessage();
    try {
      await _supabaseService.deleteCampaign(campaignId);
      if (mounted) {
        final appState = context.read<AppState>();
        if (appState.activeCampaignId == campaignId) {
          appState.setActiveCampaign(null);
        }
        await appState.loadCampaigns();
      }
      _setMessage(info: 'Campaign deleted.');
    } catch (e) {
      _setMessage(error: e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label copied to clipboard!')));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = _supabaseService.currentUser;
    final isConfigured = SupabaseConfig.isConfigured;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Campaigns & Cloud Sharing',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(
                      _showConfig ? Icons.settings : Icons.settings_outlined,
                    ),
                    tooltip: 'Supabase Settings',
                    onPressed: () => setState(() => _showConfig = !_showConfig),
                  ),
                ],
              ),
              const Divider(),
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              if (_infoMessage != null)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _infoMessage!,
                    style: TextStyle(color: Colors.green.shade900),
                  ),
                ),
              Expanded(
                child: _showConfig || !isConfigured
                    ? _buildConfigView()
                    : (user == null
                          ? _buildAuthView()
                          : _buildCampaignsView(appState)),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Backend Configuration',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your Supabase project URL and anon public key to enable player sharing.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Supabase Project URL',
              hintText: 'https://xyzcompany.supabase.co',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _anonKeyController,
            decoration: const InputDecoration(
              labelText: 'Supabase Anon Key',
              hintText: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _webUrlController,
            decoration: const InputDecoration(
              labelText: 'Player Web App Base URL',
              hintText: 'http://localhost:8080',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveConfig,
            child: _isLoading
                ? const CircularProgressIndicator.adaptive()
                : const Text('Save Configuration'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dungeon Master Sign In',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sign in to your DM account to manage campaigns and publish cards.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                child: const Text('Sign In'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _isLoading ? null : _signUp,
                child: const Text('Register'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignsView(AppState appState) {
    final user = _supabaseService.currentUser!;
    final campaigns = appState.campaigns;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Signed in as: ${user.email ?? user.id}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Sign Out'),
              onPressed: _isLoading ? null : _signOut,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _campaignNameController,
                decoration: const InputDecoration(
                  labelText: 'New Campaign Name',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create'),
              onPressed: _isLoading ? null : _createCampaign,
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Your Campaigns (Select active for sharing):',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: campaigns.isEmpty
              ? const Center(child: Text('No campaigns yet. Create one above!'))
              : RadioGroup<String>(
                  groupValue: appState.activeCampaignId,
                  onChanged: (id) {
                    if (id != null) appState.setActiveCampaign(id);
                  },
                  child: ListView.builder(
                    itemCount: campaigns.length,
                    itemBuilder: (context, index) {
                      final campaign = campaigns[index];
                      final isActive = appState.activeCampaignId == campaign.id;
                      final joinUrl =
                          '${SupabaseConfig.webBaseUrl}/#/join?code=${campaign.joinCode}';

                      return Card(
                        color: isActive
                            ? Theme.of(context).colorScheme.primaryContainer
                                  .withValues(alpha: 0.3)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: isActive
                              ? BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                )
                              : BorderSide.none,
                        ),
                        child: RadioListTile<String>(
                          value: campaign.id,
                          title: Text(
                            campaign.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Join Code: ${campaign.joinCode}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Player Link: $joinUrl',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          secondary: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.link, size: 20),
                                tooltip: 'Copy Player Link',
                                onPressed: () =>
                                    _copyToClipboard(joinUrl, 'Player Link'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                tooltip: 'Copy Code',
                                onPressed: () => _copyToClipboard(
                                  campaign.joinCode,
                                  'Join Code',
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                tooltip: 'Delete Campaign',
                                onPressed: () => _deleteCampaign(campaign.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
