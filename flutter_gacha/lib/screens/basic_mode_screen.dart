import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/gacha_provider.dart';
import '../utils/themes.dart';
import '../utils/probability_data.dart';
import '../widgets/settings_modal.dart';
import '../widgets/reset_confirm_modal.dart';
import '../widgets/input_field.dart';

class BasicModeScreen extends StatefulWidget {
  const BasicModeScreen({super.key});

  @override
  State<BasicModeScreen> createState() => _BasicModeScreenState();
}

class _BasicModeScreenState extends State<BasicModeScreen> {
  String _shareStatus = '';

  Future<void> _handleShare(GachaProvider provider) async {
    try {
      final shareText = provider.getShareText();
      await Share.share(shareText);
      setState(() => _shareStatus = '공유 완료!');
    } catch (e) {
      setState(() => _shareStatus = '공유 중 오류 발생');
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _shareStatus = '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GachaProvider>(
      builder: (context, provider, _) {
        final theme = GachaTheme.getTheme(
          proMode: false,
          darkMode: provider.darkMode,
        );
        final result = provider.basicResult;
        final feeling = provider.feelingData;

        return Scaffold(
          backgroundColor: theme.bg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 헤더
                  _buildHeader(context, provider, theme),
                  const SizedBox(height: 16),

                  // 픽업/등급보장 선택
                  _buildPityTypeSelector(provider, theme),
                  const SizedBox(height: 16),

                  // 확률 입력
                  GachaInputField(
                    label: provider.pityType == 'pickup' ? '픽업 확률 (%)' : '등급 확률 (%)',
                    value: provider.rate.toString(),
                    onChanged: (v) => provider.setRate(double.tryParse(v) ?? 1),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    theme: theme,
                  ),
                  const SizedBox(height: 16),

                  // 등급 내 캐릭터 수
                  if (provider.pityType == 'grade') ...[
                    GachaInputField(
                      label: '등급 내 캐릭터 수',
                      value: provider.charactersInGrade.toString(),
                      onChanged: (v) => provider.setCharactersInGrade(int.tryParse(v) ?? 22),
                      keyboardType: TextInputType.number,
                      theme: theme,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '일반 뽑기 특정캐릭 확률: ${result.effectiveRatePercent.toStringAsFixed(4)}%',
                            style: TextStyle(fontSize: 12, color: theme.textDim),
                          ),
                          if (result.cycleSuccessRate != null)
                            Text(
                              '천장 1사이클(${provider.pity}뽑)당 성공률: ${result.cycleSuccessRate!.toStringAsFixed(2)}%',
                              style: TextStyle(fontSize: 12, color: theme.success),
                            ),
                          Text(
                            '⚠️ 다른 캐릭 당첨 시 천장 리셋은 미반영 (근사치)',
                            style: TextStyle(fontSize: 12, color: theme.warning),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 천장
                  _buildPityInput(provider, theme),
                  const SizedBox(height: 16),

                  // 현재 뽑기 수
                  _buildCurrentPullsInput(provider, result, theme),
                  const SizedBox(height: 16),

                  // 1뽑 가격
                  GachaInputField(
                    label: '1뽑 가격 (원)',
                    value: provider.pricePerPull.toString(),
                    onChanged: (v) => provider.setPricePerPull(int.tryParse(v) ?? 2000),
                    keyboardType: TextInputType.number,
                    theme: theme,
                  ),
                  const SizedBox(height: 8),

                  // 초기화 버튼
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => showResetConfirmModal(context, provider, theme),
                      icon: Icon(Icons.refresh, size: 16, color: theme.textDim),
                      label: Text('초기화', style: TextStyle(fontSize: 12, color: theme.textDim)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 내가 뽑을 횟수
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.accent, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: GachaInputField(
                      label: '🎯 내가 뽑을 횟수',
                      value: provider.plannedPulls.toString(),
                      onChanged: (v) => provider.setPlannedPulls(int.tryParse(v) ?? 100),
                      keyboardType: TextInputType.number,
                      theme: theme,
                      noBorder: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 결과 카드
                  _buildResultCard(provider, result, feeling, theme),
                  const SizedBox(height: 16),

                  // 공유 버튼
                  ElevatedButton.icon(
                    onPressed: () => _handleShare(provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.share),
                    label: const Text('결과 공유하기', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  if (_shareStatus.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _shareStatus,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.success, fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // 면책조항
                  Text(
                    '본 앱은 참고용 확률 계산 도구이며, 계산 결과의 정확성을 보장하지 않습니다.\n과금 결정에 대한 책임은 사용자 본인에게 있습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: theme.textDim, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, GachaProvider provider, GachaTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: theme.headerGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Text('🎰', style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Text(
                '가챠 계산기',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1))],
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildHeaderButton(
                icon: provider.darkMode ? Icons.light_mode : Icons.dark_mode,
                onTap: () => provider.setDarkMode(!provider.darkMode),
              ),
              const SizedBox(width: 8),
              _buildHeaderButton(
                icon: Icons.settings,
                onTap: () => showSettingsModal(context, theme),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => provider.toggleMode(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    border: Border.all(color: Colors.white.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '프로모드',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildPityTypeSelector(GachaProvider provider, GachaTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => provider.setPityType('pickup'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: provider.pityType == 'pickup' ? theme.accent : theme.bgCard,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                    ),
                    child: Text(
                      '픽업 보장',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: provider.pityType == 'pickup' ? Colors.white : theme.text,
                        fontWeight: provider.pityType == 'pickup' ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => provider.setPityType('grade'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: provider.pityType == 'grade' ? theme.accent : theme.bgCard,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                    ),
                    child: Text(
                      '등급 보장',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: provider.pityType == 'grade' ? Colors.white : theme.text,
                        fontWeight: provider.pityType == 'grade' ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          provider.pityType == 'pickup'
              ? '픽업: 천장 도달 시 해당 캐릭터 확정'
              : '등급: 천장 도달 시 해당 등급 중 랜덤',
          style: TextStyle(fontSize: 12, color: theme.textDim),
        ),
      ],
    );
  }

  Widget _buildPityInput(GachaProvider provider, GachaTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('천장 (회)', style: TextStyle(fontWeight: FontWeight.w600, color: theme.text)),
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: provider.noPity,
                    onChanged: (v) => provider.setNoPity(v ?? false),
                    activeColor: theme.danger,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '천장 없음',
                  style: TextStyle(
                    fontSize: 14,
                    color: provider.noPity ? theme.danger : theme.textDim,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: provider.pity.toString())
            ..selection = TextSelection.collapsed(offset: provider.pity.toString().length),
          enabled: !provider.noPity,
          keyboardType: TextInputType.number,
          onChanged: (v) => provider.setPity(int.tryParse(v) ?? 100),
          style: TextStyle(
            fontSize: 16,
            color: provider.noPity ? theme.textDim : theme.text,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: provider.noPity ? theme.bgCard : theme.bgInput,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.border),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        if (provider.noPity)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '⚠️ 천장 없음 - 순수 확률로만 계산',
              style: TextStyle(fontSize: 12, color: theme.danger),
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentPullsInput(GachaProvider provider, result, GachaTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GachaInputField(
          label: '현재 뽑기 수',
          value: provider.currentPulls.toString(),
          onChanged: (v) => provider.setCurrentPulls(int.tryParse(v) ?? 0),
          keyboardType: TextInputType.number,
          theme: theme,
          enabled: !provider.noPity,
        ),
        if (!provider.noPity && result.hasPity && provider.currentPulls > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              result.completedCycles > 0
                  ? '→ 천장 ${result.completedCycles}바퀴 완료, 다음 천장까지 ${result.remainingPity}뽑 남음'
                  : '→ 첫 천장까지 ${result.remainingPity}뽑 남음',
              style: TextStyle(fontSize: 12, color: theme.success),
            ),
          ),
        if (provider.noPity)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '(천장 없음 - 현재 뽑기 수 무관)',
              style: TextStyle(fontSize: 12, color: theme.textDim),
            ),
          ),
      ],
    );
  }

  Widget _buildResultCard(GachaProvider provider, result, ProbabilityFeeling? feeling, GachaTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('결과 (특정 캐릭 1장)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.text)),
          const SizedBox(height: 12),

          // 성공확률
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎯 ${provider.plannedPulls}뽑 했을 때 성공확률',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatPercent(result.plannedSuccessRate)}%',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '비용: ${_formatNumber(provider.plannedPulls * provider.pricePerPull)}원 / 🍗 ${((provider.plannedPulls * provider.pricePerPull) / 20000).toStringAsFixed(1)}마리',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 50%
          _buildResultRow(
            emoji: '😊',
            label: '운 좋으면 (50%):',
            pulls: result.median,
            cost: result.costs['median']!,
            chickens: result.chickens['median']!,
            bgColor: theme.isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
            textColor: theme.isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
            subColor: theme.isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857),
          ),
          const SizedBox(height: 8),

          // 90%
          _buildResultRow(
            emoji: '😐',
            label: '거의 확실 (90%):',
            pulls: result.p90,
            cost: result.costs['p90']!,
            chickens: result.chickens['p90']!,
            bgColor: theme.isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7),
            textColor: theme.isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
            subColor: theme.isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
          ),
          const SizedBox(height: 8),

          // 99%
          _buildResultRow(
            emoji: '😭',
            label: '최악 (99%):',
            pulls: result.p99,
            cost: result.costs['p99']!,
            chickens: result.chickens['p99']!,
            bgColor: theme.isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
            textColor: theme.isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
            subColor: theme.isDark ? const Color(0xFFFECACA) : const Color(0xFFB91C1C),
          ),
          const SizedBox(height: 8),

          Text(
            '평균: ${result.expected is double ? (result.expected as double).toStringAsFixed(1) : result.expected}뽑',
            style: TextStyle(fontSize: 14, color: theme.textDim),
          ),

          // 체감 문구
          if (feeling != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.isDark ? const Color(0xFF312E81) : const Color(0xFFE0E7FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 ${formatPercent(result.plannedSuccessRate)}% 확률이란?',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"${feeling.event}" (${feeling.rate}%)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.isDark ? const Color(0xFFC7D2FE) : const Color(0xFF312E81),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feeling.feeling,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow({
    required String emoji,
    required String label,
    required int pulls,
    required int cost,
    required String chickens,
    required Color bgColor,
    required Color textColor,
    required Color subColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$emoji $label $pulls뽑',
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          ),
          Text(
            '${_formatNumber(cost)}원 / 🍗 $chickens마리',
            style: TextStyle(color: subColor),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
