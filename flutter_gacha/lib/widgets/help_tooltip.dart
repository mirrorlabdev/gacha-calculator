import 'package:flutter/material.dart';
import '../utils/themes.dart';
import 'chunked_text.dart';

const Map<String, List<String>> helpTexts = {
  'softPity': [
    '소프트 천장:',
    '일정',
    '뽑기 수',
    '이후부터',
    '매 뽑기마다',
    '확률이',
    '증가하는',
    '시스템입니다.',
    '예:',
    '원신은',
    '74뽑부터',
    '매 뽑기당',
    '+6%씩',
    '증가합니다.'
  ],
  'pickup': [
    '픽업확률:',
    '최고 등급',
    '당첨 시',
    '원하는',
    '캐릭터가',
    '나올',
    '확률입니다.',
    '50/50은',
    '절반,',
    '등급보장',
    '(22명 중 1명)은',
    '약 4.55%입니다.'
  ],
  'guarantee': [
    '확정권:',
    '[실패시 확정]은',
    '픽업 실패 시',
    '다음 당첨은',
    '100% 픽업',
    '(원신 방식),',
    '[매번 독립]은',
    '매번',
    '같은 확률로',
    '독립 시행',
    '(등급보장 방식)입니다.'
  ],
  'pity': [
    '천장:',
    '이 횟수만큼',
    '뽑으면',
    '무조건',
    '최고등급이',
    '나오는',
    '시스템입니다.',
    '0 또는',
    '체크 해제 시',
    '천장 없이',
    '순수 확률로만',
    '계산합니다.'
  ],
  'copies': [
    '목표장수:',
    '캐릭터',
    '돌파/완돌에',
    '필요한',
    '장수입니다.',
    '게임마다',
    '다릅니다.',
    '(예:',
    '원신 완돌=7장,',
    '운빨돌격대=10장)'
  ],
};

class HelpTooltip extends StatelessWidget {
  final String id;
  final GachaTheme theme;

  const HelpTooltip({
    super.key,
    required this.id,
    required this.theme,
  });

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: theme.isDark ? Colors.black.withOpacity(0.8) : Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: theme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.neonCyan),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChunkedText(
                chunks: helpTexts[id] ?? [],
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: theme.text,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.neonCyan,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    '확인',
                    style: TextStyle(
                      color: theme.isDark ? Colors.black : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showHelpDialog(context),
      behavior: HitTestBehavior.opaque,  // 전체 영역 터치 가능
      child: Container(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),  // 최소 터치 영역
        alignment: Alignment.center,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: theme.isProMode ? theme.border : const Color(0xFFE2E8F0),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '?',
              style: TextStyle(
                fontSize: 12,
                color: theme.isProMode ? theme.textDim : const Color(0xFF555555),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
