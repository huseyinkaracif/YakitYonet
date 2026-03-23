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
    
    // If turning on, maybe do an initial backup
    if (value != 'off') {
       _handleBackup();
    }
  }

  Future<void> _handleBackup() async {
    setState(() => _syncing = true);
    final success = await GoogleDriveService.instance.backupToDrive();
    setState(() => _syncing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Yedekleme başarıyla tamamlandı!' : 'Yedekleme başarısız oldu. Lütfen Google hesabınızı kontrol edin.'),
          backgroundColor: success ? AppTheme.accentGreen : AppTheme.accentRed,
        ),
      );
    }
  }

  Future<void> _handleRestore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('Geri Yükle', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Buluttaki verileriniz mevcut yerel verilerinizin üzerine yazılacaktır. Devam etmek istiyor musunuz?', 
          style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Evet, Geri Yükle')),
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
          content: Text(success ? 'Veriler başarıyla geri yüklendi!' : 'Geri yükleme başarısız oldu veya yedek bulunamadı.'),
          backgroundColor: success ? AppTheme.accentGreen : AppTheme.accentRed,
        ),
      );
      if (success) {
        // App needs to refresh if data changed significantly, maybe pop back to home
        Navigator.of(context).pushNamedAndRemoveUntil('/splash', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text('Yedekleme Ayarları',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                ]),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.accentBlue))
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
                                // Google Drive section
                                Container(
                                  decoration: AppTheme.glassDecoration,
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.accentPurple.withValues(alpha: 0.15),
                                        ),
                                        child: const Icon(Icons.cloud_rounded, size: 40, color: AppTheme.accentPurple),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text('Google Drive Yedekleme',
                                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 8),
                                      Text(
                                        user != null 
                                          ? '${user.displayName} hesabı ile bağlandınız.'
                                          : 'Verilerinizi güvenli bir şekilde Google Drive\'ın uygulama klasöründe yedekleyin.',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                if (user == null) ...[
                                  // Login button
                                  SizedBox(
                                    height: 56,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        setState(() => _syncing = true);
                                        await GoogleDriveService.instance.signIn();
                                        setState(() => _syncing = false);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black87,
                                      ),
                                      icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg', height: 24, 
                                        errorBuilder: (_, __, ___) => const Icon(Icons.login_rounded)),
                                      label: const Text('Google ile Bağlan', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('Yedekleme ve geri yükleme özelliklerini kullanmak için giriş yapmanız gerekmektedir.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
                                ] else ...[
                                  // Auto backup options
                                  const Text('Otomatik Yedekleme Sıklığı',
                                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 12),
                                  _buildOption('off', 'Kapalı', Icons.cloud_off_rounded, 'Otomatik yedekleme yapılmaz'),
                                  _buildOption('weekly', 'Haftalık', Icons.date_range_rounded, 'Her hafta otomatik yedeklenir'),
                                  _buildOption('monthly', 'Aylık', Icons.calendar_month_rounded, 'Her ay otomatik yedeklenir'),
                                  const SizedBox(height: 24),
                                  // Manual backup button
                                  SizedBox(
                                    height: 52,
                                    child: ElevatedButton.icon(
                                      onPressed: _syncing ? null : _handleBackup,
                                      icon: _syncing 
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryDark))
                                        : const Icon(Icons.cloud_upload_rounded),
                                      label: Text(_syncing ? 'Eşitleniyor...' : 'Şimdi Yedekle'),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Restore button
                                  SizedBox(
                                    height: 52,
                                    child: OutlinedButton.icon(
                                      onPressed: _syncing ? null : _handleRestore,
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: _syncing ? AppTheme.textHint : AppTheme.accentPurple),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      icon: const Icon(Icons.cloud_download_rounded, color: AppTheme.accentPurple),
                                      label: const Text('Drive\'dan Geri Yükle', style: TextStyle(color: AppTheme.accentPurple)),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  // Sign out
                                  TextButton.icon(
                                    onPressed: () => GoogleDriveService.instance.signOut(),
                                    icon: const Icon(Icons.logout_rounded, color: AppTheme.accentRed, size: 20),
                                    label: const Text('Google Hesabından Çıkış Yap', style: TextStyle(color: AppTheme.accentRed)),
                                  ),
                                ],
                                
                                if (_syncing) ...[
                                  const SizedBox(height: 12),
                                  const Text('Lütfen bekleyin, işlem tamamlanıyor...', 
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
                                ],
                              ],
                            ),
                          );
                        }
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(String value, String label, IconData icon, String desc) {
    final isSelected = _backupPref == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _savePrefs(value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentPurple.withValues(alpha: 0.12) : AppTheme.surfaceOverlay,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.accentPurple : AppTheme.dividerColor.withValues(alpha: 0.5),
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
          child: Row(children: [
            Icon(icon, color: isSelected ? AppTheme.accentPurple : AppTheme.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary, fontSize: 15, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
              ]),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppTheme.accentPurple, size: 22),
          ]),
        ),
      ),
    );
  }
}
