import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/storage_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _vibrationEnabled = true;
  bool _pushNotificationEnabled = true;
  String _versionLabel = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadVersion();
  }

  Future<void> _loadSettings() async {
    final vibrationEnabled = await StorageService.loadVibrationEnabled();
    final pushNotificationEnabled =
        await StorageService.loadPushNotificationEnabled();

    if (!mounted) return;
    setState(() {
      _vibrationEnabled = vibrationEnabled;
      _pushNotificationEnabled = pushNotificationEnabled;
    });
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();

    if (!mounted) return;
    setState(() {
      _versionLabel = 'v${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.vibration),
                  title: const Text('진동 알림'),
                  subtitle: const Text('나쁜 자세가 지속되면 진동으로 알려드려요.'),
                  value: _vibrationEnabled,
                  activeTrackColor: const Color(0xFFF5B3BC),
                  onChanged: (value) {
                    setState(() => _vibrationEnabled = value);
                    StorageService.saveVibrationEnabled(value);
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_none),
                  title: const Text('푸시 알림'),
                  subtitle: const Text('추후 제공될 기능이에요.'),
                  value: _pushNotificationEnabled,
                  activeTrackColor: const Color(0xFFF5B3BC),
                  onChanged: (value) {
                    setState(() => _pushNotificationEnabled = value);
                    StorageService.savePushNotificationEnabled(value);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    '로그아웃',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: _signOut,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Text(
                _versionLabel,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
