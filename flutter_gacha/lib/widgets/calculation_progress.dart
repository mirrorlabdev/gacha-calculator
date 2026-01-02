import 'package:flutter/material.dart';
import '../utils/themes.dart';

// ========== 프로모드 터미널 스타일 진행률 바 (컴팩트) ==========
class ProModeProgressBar extends StatelessWidget {
  final double progress;  // 0.0 ~ 1.0
  final String? stage;
  final VoidCallback onCancel;
  final GachaTheme theme;

  const ProModeProgressBar({
    super.key,
    required this.progress,
    this.stage,
    required this.onCancel,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).toInt();

    // 터미널 스타일 프로그레스 바 (컴팩트)
    const barWidth = 12;
    final filledCount = (progress * barWidth).round();
    final emptyCount = barWidth - filledCount;
    final progressBar = '█' * filledCount + '░' * emptyCount;

    return GestureDetector(
      onTap: onCancel,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: theme.bgCard,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: theme.neonGreen, width: 2),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '[$progressBar] ',
                style: TextStyle(
                  fontFamily: 'D2Coding',
                  fontSize: 13,
                  color: theme.neonGreen,
                ),
              ),
              TextSpan(
                text: '$percent% ',
                style: TextStyle(
                  fontFamily: 'D2Coding',
                  fontSize: 13,
                  color: theme.neonCyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: '(탭하여 취소)',
                style: TextStyle(
                  fontFamily: 'D2Coding',
                  fontSize: 12,
                  color: theme.neonPink,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ========== 기본모드 깔끔한 스타일 진행률 바 (컴팩트) ==========
class BasicModeProgressBar extends StatelessWidget {
  final double progress;  // 0.0 ~ 1.0
  final String? stage;
  final VoidCallback onCancel;
  final GachaTheme theme;

  const BasicModeProgressBar({
    super.key,
    required this.progress,
    this.stage,
    required this.onCancel,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).toInt();

    return GestureDetector(
      onTap: onCancel,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.accent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 프로그레스 바
            SizedBox(
              width: 100,
              height: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$percent%',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '(탭하여 취소)',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
