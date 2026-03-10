import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config.dart';
import '../../providers/theme_provider.dart';
import '../../services/scenario_cache_service.dart';
import '../../services/progress_tracking_service.dart';

/// Settings screen for app configuration
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _backendUrlController = TextEditingController();
  bool _customBackendUrl = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _backendUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _customBackendUrl = prefs.getBool('custom_backend_url') ?? false;
      _backendUrlController.text = prefs.getString('backend_url') ?? AppConfig.backendUrl;
    });
  }

  Future<void> _saveBackendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('custom_backend_url', _customBackendUrl);
    if (_customBackendUrl) {
      await prefs.setString('backend_url', _backendUrlController.text);
    } else {
      await prefs.remove('backend_url');
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Backend URL updated. Restart app to apply changes.',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: Colors.greenAccent.withValues(alpha: 0.8),
        ),
      );
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: Text(
          'Clear Cache',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        content: Text(
          'This will clear all cached scenarios. Continue?',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Clear', style: GoogleFonts.outfit(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ScenarioCacheService().clearCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cache cleared', style: GoogleFonts.outfit()),
            backgroundColor: Colors.greenAccent.withValues(alpha: 0.8),
          ),
        );
      }
    }
  }

  Future<void> _clearProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: Text(
          'Clear Progress',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        content: Text(
          'This will delete all your progress, badges, and streak. This cannot be undone. Continue?',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete All', style: GoogleFonts.outfit(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ProgressTrackingService().clearProgress();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All progress cleared', style: GoogleFonts.outfit()),
            backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFF1E1E2E);
    const primary = Color(0xFF6C63FF);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Section
          _buildSectionHeader('Appearance'),
          _buildSettingCard(
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: themeMode == ThemeMode.dark ? 'Dark Mode' : 'Light Mode',
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).toggleTheme();
              },
              activeTrackColor: primary.withValues(alpha: 0.5),
              activeThumbColor: primary,
            ),
          ),
          const SizedBox(height: 24),

          // Backend Section
          _buildSectionHeader('Backend'),
          _buildSettingCard(
            icon: Icons.dns_outlined,
            title: 'Custom Backend URL',
            subtitle: _customBackendUrl ? 'Enabled' : 'Use Default',
            trailing: Switch(
              value: _customBackendUrl,
              onChanged: (value) {
                setState(() {
                  _customBackendUrl = value;
                });
              },
              activeTrackColor: primary.withValues(alpha: 0.5),
              activeThumbColor: primary,
            ),
          ),
          if (_customBackendUrl) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A3E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backend URL',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _backendUrlController,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'https://your-backend.com',
                      hintStyle: GoogleFonts.outfit(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveBackendUrl,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Save URL',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Data Section
          _buildSectionHeader('Data'),
          _buildSettingCard(
            icon: Icons.delete_outline,
            title: 'Clear Scenario Cache',
            subtitle: 'Remove cached scenarios',
            onTap: _clearCache,
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.clear_all,
            title: 'Clear All Progress',
            subtitle: 'Delete badges, streak, and history',
            onTap: _clearProgress,
            dangerous: true,
          ),
          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          _buildSettingCard(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: '1.0.0+1',
          ),
          _buildSettingCard(
            icon: Icons.dns_outlined,
            title: 'Current Backend',
            subtitle: AppConfig.backendUrl,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool dangerous = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: dangerous
                ? Colors.redAccent.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: dangerous ? Colors.redAccent : Colors.white70,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: dangerous ? Colors.redAccent : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing case final widget?) widget,
            if (onTap != null && trailing == null)
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white38,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
