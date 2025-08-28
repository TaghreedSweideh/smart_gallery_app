import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = false;
  bool smartSuggestions = true;
  bool notifications = true;
  String language = 'English';

  void showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Settings', style: TextStyle(color: Colors.black87)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance
          _buildSectionTitle('Appearance'),
          Card(
            color: Colors.white,
            child: ListTile(
              leading: Icon(
                darkMode ? Icons.nightlight_round : Icons.wb_sunny,
                color: Colors.grey[600],
              ),
              title: const Text(
                'Dark Mode',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Switch to dark theme'),
              trailing: Switch(
                value: darkMode,
                onChanged: (v) => setState(() => darkMode = v),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Smart Features
          _buildSectionTitle('Smart Features'),
          Card(
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  title: const Text(
                    'Smart Suggestions',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Learn from your deletion behavior'),
                  trailing: Switch(
                    value: smartSuggestions,
                    onChanged: (v) => setState(() => smartSuggestions = v),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.notifications, color: Colors.grey[600]),
                  title: const Text(
                    'Notifications',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Get notified about duplicates'),
                  trailing: Switch(
                    value: notifications,
                    onChanged: (v) => setState(() => notifications = v),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Language
          _buildSectionTitle('Language'),
          Card(
            color: Colors.white,
            child: ListTile(
              leading: Icon(Icons.language, color: Colors.grey[600]),
              title: const Text(
                'App Language',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Choose your preferred language'),
              trailing: DropdownButton<String>(
                value: language,
                items: const [
                  DropdownMenuItem(value: 'English', child: Text('English')),
                  DropdownMenuItem(value: 'Arabic', child: Text('العربية')),
                  DropdownMenuItem(value: 'French', child: Text('Français')),
                  DropdownMenuItem(value: 'Spanish', child: Text('Español')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => language = value);
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Storage
          _buildSectionTitle('Storage'),
          Card(
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.grey[600]),
                  title: const Text(
                    'Clear Cache',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Free up storage space'),
                  trailing: const Text(
                    '2.4 GB',
                    style: TextStyle(color: Colors.grey),
                  ),
                  onTap: () =>
                      showAlert('Cache cleared', 'Cache cleared successfully!'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.red[600]),
                  title: const Text(
                    'Delete All Blurred',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  subtitle: const Text(
                    'Permanently remove blurred images',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  trailing: const Text(
                    '4 photos',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () => showAlert(
                    'Delete Blurred',
                    'All blurred images would be deleted',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // About
          _buildSectionTitle('About'),
          Card(
            color: Colors.white,
            child: ListTile(
              leading: Icon(Icons.info_outline, color: Colors.grey[600]),
              title: const Text(
                'Smart Gallery',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Version 1.0.0'),
                  SizedBox(height: 4),
                  Text('Intelligently organize and manage your photos'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}
