import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/authentication_service.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = AuthenticationService();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Logged in as'),
            subtitle: Text(auth.email ?? '-'),
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            value: settings.isDarkMode,
            onChanged: settings.setDarkMode,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.grid_view),
            title: const Text('Grid View'),
            subtitle:
                Text(settings.showGrid ? 'Showing cards' : 'Showing list'),
            value: settings.showGrid,
            onChanged: settings.setShowGrid,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              // ปิดหน้า Settings ก่อน แล้ว main.dart จะพาไปหน้า Login เอง
              Navigator.of(context).popUntil((route) {
                return route.isFirst;
              });
              await auth.logout();
            },
          ),
        ],
      ),
    );
  }
}
