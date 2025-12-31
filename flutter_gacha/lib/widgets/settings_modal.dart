import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/themes.dart';

const String appVersion = 'v0.7.3';
const String contactFormUrl = 'https://forms.gle/qrRDSS5pUyp42jE97';
const String privacyPolicyUrl = 'https://gist.github.com/mirrorlabdev/f84328d6cf7a3ec0e70f4c43b050c744';

void showSettingsModal(BuildContext context, GachaTheme theme) {
  showDialog(
    context: context,
    barrierColor: theme.isDark ? Colors.black.withOpacity(0.9) : Colors.black.withOpacity(0.5),
    builder: (context) => SettingsModal(theme: theme),
  );
}

class SettingsModal extends StatefulWidget {
  final GachaTheme theme;

  const SettingsModal({super.key, required this.theme});

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  bool _copied = false;

  GachaTheme get theme => widget.theme;

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _copyDebugLog() async {
    final debugInfo = StringBuffer();
    debugInfo.writeln('=== 가챠 계산기 디버그 로그 ===');
    debugInfo.writeln('앱 버전: $appVersion');
    debugInfo.writeln('플랫폼: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
    debugInfo.writeln('Dart 버전: ${Platform.version}');
    debugInfo.writeln('시간: ${DateTime.now().toIso8601String()}');
    debugInfo.writeln('==============================');

    await Clipboard.setData(ClipboardData(text: debugInfo.toString()));

    setState(() => _copied = true);

    // 2초 후 원래 텍스트로 복원
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
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
              icon: _copied ? '✓' : '🐛',
              label: _copied ? '복사됨' : '버그 제보용 로그 복사',
              onTap: _copied ? null : _copyDebugLog,
              highlight: _copied,
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
    VoidCallback? onTap,
    bool dimmed = false,
    bool highlight = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: highlight ? theme.success.withAlpha(30) : null,
          border: Border.all(color: highlight ? theme.success : theme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              icon,
              style: TextStyle(
                fontSize: 16,
                color: highlight ? theme.success : null,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: highlight ? theme.success : (dimmed ? theme.textDim : theme.text),
                fontWeight: highlight ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
