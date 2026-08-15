import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _reviewNotifications = true;
  bool _systemNotifications = true;

  void _showNotifications() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void update(VoidCallback change) {
              setState(change);
              setSheetState(() {});
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SheetHeading(
                      icon: Icons.notifications_none,
                      title: 'Notifications',
                    ),
                    SwitchListTile(
                      value: _reviewNotifications,
                      activeThumbColor: AppColors.primary,
                      title: const Text('Review queue updates'),
                      subtitle: const Text(
                        'Notify me when documents require attention.',
                      ),
                      onChanged: (value) => update(
                        () => _reviewNotifications = value,
                      ),
                    ),
                    SwitchListTile(
                      value: _systemNotifications,
                      activeThumbColor: AppColors.primary,
                      title: const Text('System updates'),
                      subtitle: const Text(
                        'Receive processing and classifier status alerts.',
                      ),
                      onChanged: (value) => update(
                        () => _systemNotifications = value,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showInfoSheet({
    required String title,
    required IconData icon,
    required String description,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SheetHeading(icon: icon, title: title),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.background,
      ),
      body: AppGradientBackground(child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      size: 58,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 52),
                  _SettingsItem(
                    icon: Icons.notifications_none,
                    title: 'Notifications',
                    onTap: _showNotifications,
                  ),
                  const SizedBox(height: 12),
                  _SettingsItem(
                    icon: Icons.lock_outline,
                    title: 'Privacy & Security',
                    onTap: () => _showInfoSheet(
                      title: 'Privacy & Security',
                      icon: Icons.lock_outline,
                      description:
                          'Your account uses JWT authentication. Documents and analytics are available only to authenticated users.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingsItem(
                    icon: Icons.help_outline,
                    title: 'Help and Support',
                    onTap: () => _showInfoSheet(
                      title: 'Help and Support',
                      icon: Icons.help_outline,
                      description:
                          'For assistance, contact your system administrator or include the displayed error message when reporting a problem.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingsItem(
                    icon: Icons.info_outline,
                    title: 'About',
                    onTap: () => _showInfoSheet(
                      title: 'About',
                      icon: Icons.info_outline,
                      description:
                          'HITL AI Classifier\nVersion 1.0.0\nHuman-guided document classification and analytics.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      )),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHeading extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SheetHeading({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
