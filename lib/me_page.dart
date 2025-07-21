import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nirva_app/user_profile_page.dart';
import 'package:nirva_app/update_data_page.dart';
import 'package:nirva_app/providers/user_provider.dart';
import 'package:nirva_app/hive_data_viewer_page.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 用户信息卡片
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    context.read<UserProvider>().user.displayName,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    debugPrint('User profile tapped');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserProfilePage(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              _buildHardwareCard(), // Nirva Necklace 卡片
              const SizedBox(height: 16),

              // 设置选项卡片
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Column(
                  children: [
                    _buildSettingsOption(
                      icon: Icons.restart_alt,
                      title: 'Onboarding',
                      subtitle: 'Restart the setup process',
                      onTap: () {
                        debugPrint('Onboarding tapped');
                      },
                    ),
                    const Divider(height: 1),
                    _buildSettingsOption(
                      icon: Icons.access_time,
                      title: 'Reflection Time',
                      subtitle: 'Set when you want daily reflections',
                      onTap: () {
                        debugPrint('Reflection Time tapped');
                      },
                    ),
                    const Divider(height: 1),
                    _buildSettingsOption(
                      icon: Icons.privacy_tip,
                      title: 'Privacy Controls',
                      subtitle: 'Manage your data and sharing preferences',
                      onTap: () {
                        debugPrint('Privacy Controls tapped');
                      },
                    ),
                    const Divider(height: 1),
                    _buildSettingsOption(
                      icon: Icons.upload,
                      title: 'Update Data',
                      subtitle: 'Upload your recorded audio',
                      onTap: () {
                        debugPrint('Update Data tapped');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UpdateDataPage(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildSettingsOption(
                      icon: Icons.storage,
                      title: 'Local Data',
                      subtitle: 'View local data stored in Hive',
                      onTap: () {
                        debugPrint('Local Data tapped');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HiveDataViewerPage(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildSettingsOption(
                      icon: Icons.settings,
                      title: 'Nirva Settings',
                      subtitle: 'Customize Nirva\'s voice',
                      onTap: () {
                        debugPrint('Nirva Settings tapped');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 24, color: Colors.black),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  // Nirva Necklace 卡片
  // ignore: unused_element
  Widget _buildHardwareCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.water_drop, size: 40, color: Colors.amber),
        title: const Text(
          'Nirva Necklace',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: const [
            Icon(Icons.circle, size: 8, color: Colors.green),
            SizedBox(width: 4),
            Text('Connected', style: TextStyle(color: Colors.green)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('88%', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: () {
          debugPrint('Nirva Necklace tapped');
        },
      ),
    );
  }
}
