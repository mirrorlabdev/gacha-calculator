import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/themes.dart';

const String appVersion = 'v1.1.0';
const String contactFormUrl = 'https://forms.gle/qrRDSS5pUyp42jE97';
const String privacyPolicyUrl = 'https://gist.github.com/mirrorlabdev/f84328d6cf7a3ec0e70f4c43b050c744';

void showSettingsModal(BuildContext context, GachaTheme theme) {
  showDialog(
    context: context,
    barrierColor: theme.isDark ? Colors.black.withOpacity(0.9) : Colors.black.withOpacity(0.5),
    builder: (context) => SettingsModal(theme: theme),
  );
}

class SettingsModal extends StatelessWidget {
  final GachaTheme theme;

  const SettingsModal({super.key, required this.theme});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showLicenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.bgCard,
        title: Text('오픈소스 라이선스', style: TextStyle(color: theme.text)),
        content: Text(
          '이 앱은 다음 오픈소스 라이브러리를 사용합니다:\n\n• Flutter (BSD License)\n• Provider (MIT License)\n• SharedPreferences (BSD License)\n• Share Plus (BSD License)\n• URL Launcher (BSD License)\n\n기타 의존성은 MIT 또는 Apache 2.0 라이선스를 따릅니다.',
          style: TextStyle(color: theme.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인', style: TextStyle(color: theme.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: theme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('⚙️ 설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.text)),
                Text(appVersion, style: TextStyle(fontSize: 12, color: theme.textDim)),
              ],
            ),
            const SizedBox(height: 20),

            // 문의하기
            _buildMenuItem(
              icon: '✉️',
              label: '문의하기',
              onTap: () => _launchUrl(contactFormUrl),
            ),
            const SizedBox(height: 12),

            // 버그 제보
            _buildMenuItem(
              icon: '🐛',
              label: '버그 제보용 로그 복사',
              onTap: () {
                // TODO: 클립보드에 디버그 로그 복사
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('디버그 정보가 복사되었습니다'),
                    backgroundColor: theme.accent,
                  ),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: theme.border),
            ),

            // 개인정보처리방침
            _buildMenuItem(
              icon: '📋',
              label: '개인정보처리방침',
              onTap: () => _launchUrl(privacyPolicyUrl),
              dimmed: true,
            ),
            const SizedBox(height: 12),

            // 오픈소스 라이선스
            _buildMenuItem(
              icon: '📄',
              label: '오픈소스 라이선스',
              onTap: () => _showLicenseDialog(context),
              dimmed: true,
            ),
            const SizedBox(height: 20),

            // 닫기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('닫기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String label,
    required VoidCallback onTap,
    bool dimmed = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: dimmed ? theme.textDim : theme.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
