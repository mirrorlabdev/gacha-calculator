import 'package:flutter/material.dart';
import '../providers/gacha_provider.dart';
import '../utils/themes.dart';

void showResetConfirmModal(BuildContext context, GachaProvider provider, GachaTheme theme) {
  showDialog(
    context: context,
    barrierColor: theme.isDark ? Colors.black.withOpacity(0.9) : Colors.black.withOpacity(0.5),
    builder: (context) => ResetConfirmModal(provider: provider, theme: theme),
  );
}

class ResetConfirmModal extends StatelessWidget {
  final GachaProvider provider;
  final GachaTheme theme;

  const ResetConfirmModal({
    super.key,
    required this.provider,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: theme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 16),
            Text(
              '초기화',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '모든 계산 설정값이 초기화됩니다.\n(모드/테마는 유지)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.textDim,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '취소',
                      style: TextStyle(color: theme.textDim),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      provider.reset();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.danger,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '초기화',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
