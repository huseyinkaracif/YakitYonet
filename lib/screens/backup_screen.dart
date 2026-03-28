import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/google_drive_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  String _backupPref = 'off';
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _backupPref = prefs.getString('backup_preference') ?? 'off';
      _loading = false;
    });
  }

  Future<void> _savePrefs(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backup_preference', value);
    setState(() => _backupPref = value);
    if (value != 'off') _handleBackup();
  }

  Future<void> _handleBackup() async {
    setState(() => _syncing = true);
    final success = await GoogleDriveService.instance.backupToDrive();
    setState(() => _syncing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Yedekleme başarıyla tamamlandı!'
              : 'Yedekleme başarısız. Google hesabınızı kontrol edin.'),
          backgroundColor:
              success ? AppTheme.successColor : AppTheme.dangerColor,
        ),
      );
    }
  }

  Future<void> _handleRestore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Geri Yükle'),
        content: const Text(
          'Buluttaki verileriniz mevcut yerel verilerinizin üzerine yazılacaktır. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Evet, Geri Yükle'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _syncing = true);
    final success = await GoogleDriveService.instance.restoreFromDrive();
    setState(() => _syncing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Veriler başarıyla geri yüklendi!'
              : 'Geri yükleme başarısız veya yedek bulunamadı.'),
          backgroundColor:
              success ? AppTheme.successColor : AppTheme.dangerColor,
        ),
      );
      if (success) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/splash', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded,
                        color: AppTheme.textPrimaryFor(context)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Yedekleme Ayarları',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryFor(context),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: AppTheme.dividerFor(context)),

            Expanded(
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.accent))
                  : StreamBuilder(
                      stream: GoogleDriveService.instance.onUserChanged,
                      initialData: GoogleDriveService.instance.currentUser,
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Status card
                              Container(
                                decoration: AppTheme.cardDecorationFor(context),
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: user != null
                                            ? AppTheme.successColor
                                                .withValues(alpha: 0.1)
                                            : AppTheme.surfaceAltFor(context),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: Border.all(
                                          color: user != null
                                              ? AppTheme.successColor
                                                  .withValues(alpha: 0.25)
                                              : AppTheme.borderFor(context),
                                        ),
                                      ),
                                      child: Icon(
                                        user != null
                                            ? Icons.cloud_done_rounded
                                            : Icons.cloud_off_rounded,
                                        color: user != null
                                            ? AppTheme.successColor
                                            : AppTheme.textHintFor(context),
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user != null
                                                ? 'Google Drive Bağlı'
                                                : 'Google Drive Yedekleme',
                                            style: TextStyle(
                                              color: AppTheme.textPrimaryFor(context),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            user != null
                                                ? user.displayName ??
                                                    user.email
                                                : 'Verilerinizi güvenle yedekleyin.',
                                            style: TextStyle(
                                              color: AppTheme.textSecondaryFor(context),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              if (user == null) ...[
                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton.icon(
                                    onPressed: _syncing
                                        ? null
                                        : () async {
                                            setState(() => _syncing = true);
                                            await GoogleDriveService.instance
                                                .signIn();
                                            setState(
                                                () => _syncing = false);
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.surfaceFor(context),
                                      foregroundColor:
                                          AppTheme.textPrimaryFor(context),
                                      side: BorderSide(
                                          color: AppTheme.borderFor(context)),
                                      elevation: 0,
                                    ),
                                    icon: _syncing
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppTheme.accent,
                                            ),
                                          )
                                        : Image.network(
                                            'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                                            height: 22,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                                    Icons.login_rounded,
                                                    size: 22),
                                          ),
                                    label: const Text(
                                      'Google ile Bağlan',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Yedekleme ve geri yükleme özelliklerini kullanmak için giriş yapmanız gerekmektedir.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: AppTheme.textHintFor(context),
                                      fontSize: 12,
                                      height: 1.5),
                                ),
                              ] else ...[
                                // Auto backup options
                                Text(
                                  'OTOMATİK YEDEKLEME',
                                  style: TextStyle(
                                    color: AppTheme.textSecondaryFor(context),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildOption(
                                    'off',
                                    'Kapalı',
                                    Icons.cloud_off_rounded,
                                    'Otomatik yedekleme yapılmaz'),
                                _buildOption(
                                    'weekly',
                                    'Haftalık',
                                    Icons.date_range_rounded,
                                    'Her hafta otomatik yedeklenir'),
                                _buildOption(
                                    'monthly',
                                    'Aylık',
                                    Icons.calendar_month_rounded,
                                    'Her ay otomatik yedeklenir'),
                                const SizedBox(height: 20),

                                // Actions
                                Text(
                                  'MANUEL İŞLEMLER',
                                  style: TextStyle(
                                    color: AppTheme.textSecondaryFor(context),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _syncing ? null : _handleBackup,
                                    icon: _syncing
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.cloud_upload_rounded),
                                    label: Text(_syncing
                                        ? 'Eşitleniyor...'
                                        : 'Şimdi Yedekle'),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                SizedBox(
                                  height: 52,
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        _syncing ? null : _handleRestore,
                                    icon: const Icon(
                                        Icons.cloud_download_rounded),
                                    label: const Text(
                                        'Drive\'dan Geri Yükle'),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                Center(
                                  child: TextButton.icon(
                                    onPressed: () =>
                                        GoogleDriveService.instance
                                            .signOut(),
                                    icon: const Icon(Icons.logout_rounded,
                                        color: AppTheme.dangerColor,
                                        size: 18),
                                    label: const Text(
                                      'Google Hesabından Çıkış Yap',
                                      style: TextStyle(
                                          color: AppTheme.dangerColor,
                                          fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],

                              if (_syncing) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Lütfen bekleyin, işlem tamamlanıyor...',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: AppTheme.textHintFor(context),
                                      fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
      String value, String label, IconData icon, String desc) {
    final isSelected = _backupPref == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isSelected
        ? (isDark ? AppTheme.accent.withValues(alpha: 0.15) : AppTheme.accentLight)
        : AppTheme.surfaceFor(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _savePrefs(value),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgCol,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.accent : AppTheme.borderFor(context),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.accent.withValues(alpha: 0.12)
                      : AppTheme.surfaceAltFor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon,
                    color: isSelected
                        ? AppTheme.accent
                        : AppTheme.textSecondaryFor(context),
                    size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppTheme.textPrimaryFor(context)
                            : AppTheme.textSecondaryFor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: TextStyle(
                          color: AppTheme.textHintFor(context), fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
