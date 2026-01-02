import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/changelog.dart';
import '../utils/themes.dart';

const String _lastSeenVersionKey = 'lastSeenVersion';

/// 앱 시작 시 버전 체크 후 필요하면 팝업 표시
Future<void> checkAndShowUpdatePopup(BuildContext context, GachaTheme theme) async {
  final prefs = await SharedPreferences.getInstance();
  final lastSeenVersion = prefs.getString(_lastSeenVersionKey);

  // 처음 실행이거나 버전이 다르면 팝업 표시
  if (lastSeenVersion != currentAppVersion) {
    // 현재 버전의 changelog 찾기
    final currentChangelog = changelog.where((e) => e.version == currentAppVersion).firstOrNull;

    if (currentChangelog != null && context.mounted) {
      await showUpdatePopup(context, currentChangelog, theme);
    }

    // 버전 업데이트
    await prefs.setString(_lastSeenVersionKey, currentAppVersion);
  }
}

/// 업데이트 팝업 표시
Future<void> showUpdatePopup(BuildContext context, ChangelogEntry entry, GachaTheme theme) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: theme.isDark ? Colors.black.withOpacity(0.9) : Colors.black.withOpacity(0.5),
    builder: (context) => _UpdatePopupDialog(entry: entry, theme: theme),
  );
}

class _UpdatePopupDialog extends StatelessWidget {
  final ChangelogEntry entry;
  final GachaTheme theme;

  const _UpdatePopupDialog({required this.entry, required this.theme});

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
            // 헤더
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: theme.accent),
                  ),
                  child: Text(
                    'v${entry.version}',
                    style: TextStyle(
                      color: theme.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '업데이트',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry.date,
              style: TextStyle(fontSize: 12, color: theme.textDim),
            ),
            const SizedBox(height: 16),

            // 변경사항
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: entry.changes.map((change) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: theme.accent, fontSize: 14)),
                      Expanded(
                        child: Text(
                          change,
                          style: TextStyle(color: theme.text, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // 확인 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 전체 업데이트 내역 다이얼로그 (설정에서 접근)
void showFullChangelogDialog(BuildContext context, GachaTheme theme) {
  showDialog(
    context: context,
    barrierColor: theme.isDark ? Colors.black.withOpacity(0.9) : Colors.black.withOpacity(0.5),
    builder: (context) => _FullChangelogDialog(theme: theme),
  );
}

class _FullChangelogDialog extends StatelessWidget {
  final GachaTheme theme;

  const _FullChangelogDialog({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: theme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '업데이트 내역',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.text,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: theme.textDim),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 스크롤 가능한 changelog 리스트
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: changelog.map((entry) => _ChangelogEntryCard(
                    entry: entry,
                    theme: theme,
                    isLatest: entry.version == currentAppVersion,
                  )).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

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
                child: const Text(
                  '닫기',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangelogEntryCard extends StatelessWidget {
  final ChangelogEntry entry;
  final GachaTheme theme;
  final bool isLatest;

  const _ChangelogEntryCard({
    required this.entry,
    required this.theme,
    required this.isLatest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: isLatest ? Border.all(color: theme.accent, width: 1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 버전 및 날짜
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isLatest ? theme.accent.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isLatest ? theme.accent : theme.textDim,
                  ),
                ),
                child: Text(
                  'v${entry.version}',
                  style: TextStyle(
                    color: isLatest ? theme.accent : theme.textDim,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isLatest) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '현재',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                entry.date,
                style: TextStyle(fontSize: 11, color: theme.textDim),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 변경사항
          ...entry.changes.map((change) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: theme.textDim, fontSize: 12)),
                Expanded(
                  child: Text(
                    change,
                    style: TextStyle(color: theme.text, fontSize: 12),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
