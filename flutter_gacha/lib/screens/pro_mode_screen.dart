import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/gacha_provider.dart';
import '../utils/themes.dart';
import '../utils/probability_data.dart';
import '../widgets/settings_modal.dart';
import '../widgets/reset_confirm_modal.dart';
import '../widgets/help_tooltip.dart';
import '../widgets/histogram_chart.dart';

class ProModeScreen extends StatefulWidget {
  const ProModeScreen({super.key});

  @override
  State<ProModeScreen> createState() => _ProModeScreenState();
}

class _ProModeScreenState extends State<ProModeScreen> {
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
          proMode: true,
          darkMode: provider.darkMode,
        );
        final result = provider.proResult;
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

                  // 변수 패널
                  _buildVariablesPanel(provider, theme),
                  const SizedBox(height: 16),

                  // 확률분포 히스토그램
                  if (result != null) ...[
                    HistogramChart(result: result, theme: theme),
                    const SizedBox(height: 16),

                    // 통계 패널
                    _buildStatisticsPanel(result, provider, theme),
                    const SizedBox(height: 16),
                  ],

                  // 성공확률 계산
                  _buildSuccessRatePanel(provider, result, theme),
                  const SizedBox(height: 16),

                  // 체감 문구
                  if (feeling != null && result != null)
                    _buildFeelingCard(feeling, theme),
                  if (feeling != null) const SizedBox(height: 16),

                  // 공유 버튼
                  OutlinedButton(
                    onPressed: () => _handleShare(provider),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.neonGreen),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(
                      '결과 공유하기',
                      style: TextStyle(
                        color: theme.neonGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (_shareStatus.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _shareStatus,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.neonGreen, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // 면책조항
                  Text(
                    '본 앱은 참고용 확률 계산 도구이며, 계산 결과의 정확성을 보장하지 않습니다.\n과금 결정에 대한 책임은 사용자 본인에게 있습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: theme.textDim, height: 1.5),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: theme.headerGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.neonGreen, width: 2),
        boxShadow: theme.glow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                '▶',
                style: TextStyle(
                  color: theme.neonGreen,
                  fontSize: 20,
                  shadows: [Shadow(color: theme.neonGreen, blurRadius: 10)],
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '가챠 분석기 PRO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildHeaderButton(
                icon: provider.darkMode ? Icons.light_mode : Icons.dark_mode,
                onTap: () => provider.setDarkMode(!provider.darkMode),
                theme: theme,
              ),
              const SizedBox(width: 8),
              _buildHeaderButton(
                icon: Icons.settings,
                onTap: () => showSettingsModal(context, theme),
                theme: theme,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => provider.toggleMode(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.neonGreen.withOpacity(0.2),
                    border: Border.all(color: theme.neonGreen, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '기본모드',
                    style: TextStyle(
                      color: theme.neonGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(color: theme.neonGreen, blurRadius: 8)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({required IconData icon, required VoidCallback onTap, required GachaTheme theme}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildVariablesPanel(GachaProvider provider, GachaTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '─── 변수 설정 ───',
            style: TextStyle(color: theme.neonCyan, fontSize: 12, letterSpacing: 1),
          ),
          const SizedBox(height: 12),

          // 기본확률
          _buildInputRow(
            label: '기본확률',
            value: provider.rate,
            onChanged: (v) => provider.setRate(v),
            suffix: '%',
            theme: theme,
          ),

          // 천장
          _buildInputRow(
            label: '천장',
            helpId: 'pity',
            value: provider.noPity ? 0 : provider.pity.toDouble(),
            onChanged: (v) {
              if (v == 0) {
                provider.setNoPity(true);
              } else {
                provider.setNoPity(false);
                provider.setPity(v.toInt());
              }
            },
            suffix: provider.noPity ? '천장 없음' : '뽑',
            suffixColor: provider.noPity ? theme.neonPink : null,
            theme: theme,
            isInt: true,
          ),

          // 소프트 천장
          _buildSoftPityRow(provider, theme),

          // 픽업확률
          _buildPickupRateRow(provider, theme),

          // 확정권 (픽업 < 100일 때만)
          if (provider.pickupRate < 100) _buildGuaranteeRow(provider, theme),

          // 목표장수
          _buildInputRow(
            label: '목표장수',
            helpId: 'copies',
            value: provider.targetCopies.toDouble(),
            onChanged: (v) => provider.setTargetCopies(v.toInt().clamp(1, 20)),
            suffix: '장',
            theme: theme,
            isInt: true,
            width: 60,
          ),

          // 구분선
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: theme.border),
                Text('── 현재 상태 ──', style: TextStyle(color: theme.neonCyan, fontSize: 11, letterSpacing: 1)),
              ],
            ),
          ),

          // 현재 뽑기 수
          _buildCurrentPullsRow(provider, theme),

          // 확정권 상태 (50/50일 때만)
          if (provider.pickupRate < 100 && provider.guaranteeOnFail)
            _buildCurrentGuaranteeRow(provider, theme),

          // 구분선 - 비용
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: theme.border),
                Text('── 비용 ──', style: TextStyle(color: theme.neonCyan, fontSize: 11, letterSpacing: 1)),
              ],
            ),
          ),

          // 뽑당비용
          _buildInputRow(
            label: '뽑당비용',
            value: provider.pricePerPull.toDouble(),
            onChanged: (v) => provider.setPricePerPull(v.toInt()),
            suffix: '원',
            theme: theme,
            isInt: true,
          ),

          // 초기화
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Divider(color: theme.border),
          ),
          TextButton(
            onPressed: () => showResetConfirmModal(context, provider, theme),
            child: Text('초기화', style: TextStyle(color: theme.textDim, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow({
    required String label,
    String? helpId,
    required double value,
    required ValueChanged<double> onChanged,
    required String suffix,
    required GachaTheme theme,
    bool isInt = false,
    double width = 80,
    Color? suffixColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Row(
              children: [
                Text(label, style: TextStyle(color: theme.textDim, fontSize: 13)),
                if (helpId != null) HelpTooltip(id: helpId, theme: theme),
              ],
            ),
          ),
          SizedBox(
            width: width,
            child: TextField(
              controller: TextEditingController(
                text: isInt ? value.toInt().toString() : value.toString(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => onChanged(double.tryParse(v) ?? value),
              style: TextStyle(color: theme.neonGreen, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.bgInput,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: theme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: theme.border),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(suffix, style: TextStyle(color: suffixColor ?? theme.textDim, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSoftPityRow(GachaProvider provider, GachaTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Row(
              children: [
                Text('소프트 천장', style: TextStyle(color: theme.textDim, fontSize: 13)),
                HelpTooltip(id: 'softPity', theme: theme),
              ],
            ),
          ),
          SizedBox(
            width: 55,
            child: TextField(
              controller: TextEditingController(text: provider.softPityStart.toString()),
              keyboardType: TextInputType.number,
              onChanged: (v) => provider.setSoftPityStart(int.tryParse(v) ?? 0),
              style: TextStyle(
                color: provider.softPityStart > 0 ? theme.neonCyan : theme.textDim,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.bgInput,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: theme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: theme.border),
                ),
              ),
            ),
          ),
          Text(' 뽑부터 ', style: TextStyle(color: theme.textDim, fontSize: 12)),
          Text('+', style: TextStyle(color: theme.neonCyan)),
          SizedBox(
            width: 45,
            child: TextField(
              controller: TextEditingController(text: provider.softPityIncrease.toString()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => provider.setSoftPityIncrease(double.tryParse(v) ?? 6),
              style: TextStyle(
                color: provider.softPityStart > 0 ? theme.neonCyan : theme.textDim,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.bgInput,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: theme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: theme.border),
                ),
              ),
            ),
          ),
          Text(' %씩', style: TextStyle(color: theme.textDim, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPickupRateRow(GachaProvider provider, GachaTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 100,
                child: Row(
                  children: [
                    Text('픽업확률', style: TextStyle(color: theme.textDim, fontSize: 13)),
                    HelpTooltip(id: 'pickup', theme: theme),
                  ],
                ),
              ),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: TextEditingController(text: provider.pickupRate.toString()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => provider.setPickupRate(double.tryParse(v) ?? 100),
                  style: TextStyle(color: theme.neonPurple, fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.bgInput,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: theme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: theme.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('%', style: TextStyle(color: theme.textDim, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 100),
            child: Row(
              children: [
                _buildQuickButton('확정', 100, provider.pickupRate, (v) => provider.setPickupRate(v), theme),
                const SizedBox(width: 6),
                _buildQuickButton('50/50', 50, provider.pickupRate, (v) => provider.setPickupRate(v), theme),
                const SizedBox(width: 6),
                _buildQuickButton('75/25', 75, provider.pickupRate, (v) => provider.setPickupRate(v), theme),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 100, top: 4),
            child: Text(
              '당첨 시 원하는 캐릭 확률 (등급 내 n명 → ${(100 / provider.pickupRate).toStringAsFixed(1)}명 중 1명)',
              style: TextStyle(fontSize: 11, color: theme.textDim),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton(String label, double value, double current, ValueChanged<double> onTap, GachaTheme theme) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? theme.neonPurple.withOpacity(0.2) : Colors.transparent,
          border: Border.all(color: isSelected ? theme.neonPurple : theme.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? theme.neonPurple : theme.textDim,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildGuaranteeRow(GachaProvider provider, GachaTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Row(
              children: [
                Text('확정권', style: TextStyle(color: theme.textDim, fontSize: 13)),
                HelpTooltip(id: 'guarantee', theme: theme),
              ],
            ),
          ),
          _buildToggleButton('실패시 확정', true, provider.guaranteeOnFail, (v) => provider.setGuaranteeOnFail(v), theme),
          const SizedBox(width: 6),
          _buildToggleButton('매번 독립', false, !provider.guaranteeOnFail, (v) => provider.setGuaranteeOnFail(!v), theme),
          const SizedBox(width: 8),
          Text(
            provider.guaranteeOnFail ? '(원신식)' : '(등급보장식)',
            style: TextStyle(fontSize: 10, color: theme.textDim),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool value, bool isSelected, ValueChanged<bool> onTap, GachaTheme theme) {
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? theme.neonCyan.withOpacity(0.2) : Colors.transparent,
          border: Border.all(color: isSelected ? theme.neonCyan : theme.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? theme.neonCyan : theme.textDim,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPullsRow(GachaProvider provider, GachaTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputRow(
          label: '현재 뽑기 수',
          value: provider.currentPulls.toDouble(),
          onChanged: (v) => provider.setCurrentPulls(v.toInt()),
          suffix: '뽑',
          theme: theme,
          isInt: true,
        ),
        if (!provider.noPity && provider.pity > 0 && provider.currentPulls > 0)
          Padding(
            padding: const EdgeInsets.only(left: 100, bottom: 10),
            child: Text(
              provider.currentPulls ~/ provider.pity > 0
                  ? '→ 천장 ${provider.currentPulls ~/ provider.pity}바퀴 완료, 다음 천장까지 ${provider.pity - (provider.currentPulls % provider.pity)}뽑 남음'
                  : '→ 첫 천장까지 ${provider.pity - provider.currentPulls}뽑 남음',
              style: TextStyle(fontSize: 11, color: theme.neonCyan),
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentGuaranteeRow(GachaProvider provider, GachaTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text('확정권 보유', style: TextStyle(color: theme.textDim, fontSize: 13)),
          ),
          GestureDetector(
            onTap: () => provider.setCurrentGuarantee(!provider.currentGuarantee),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: provider.currentGuarantee ? theme.neonCyan.withOpacity(0.2) : Colors.transparent,
                border: Border.all(color: provider.currentGuarantee ? theme.neonCyan : theme.border),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                provider.currentGuarantee ? '예 (다음 확정)' : '아니오',
                style: TextStyle(
                  color: provider.currentGuarantee ? theme.neonCyan : theme.textDim,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsPanel(result, GachaProvider provider, GachaTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '─── 통계 (${provider.targetCopies}장 목표) ───',
            style: TextStyle(color: theme.neonCyan, fontSize: 12, letterSpacing: 1),
          ),
          const SizedBox(height: 12),

          _buildStatRow('기대값', '${result.mean.toStringAsFixed(1)}뽑', theme.neonGreen, theme),
          _buildStatRow('표준편차', '±${result.stdDev.toStringAsFixed(1)}', theme.text, theme),
          Divider(color: theme.border, height: 16),
          _buildStatRow('운 좋으면 (상위10%)', '${result.p10}뽑', const Color(0xFF4ADE80), theme),
          _buildStatRow('중앙값 (절반)', '${result.p50}뽑', theme.neonCyan, theme),
          _buildStatRow('운 나쁘면 (하위10%)', '${result.p90}뽑', const Color(0xFFFBBF24), theme),
          _buildStatRow('극악 (하위1%)', '${result.p99}뽑', theme.neonPink, theme),
          Divider(color: theme.border, height: 16),
          _buildStatRow('중앙값 비용', '${_formatNumber(result.costs['p50']!)}원', theme.text, theme),
          _buildStatRow('운나쁨 비용', '${_formatNumber(result.costs['p90']!)}원', theme.text, theme),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor, GachaTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: theme.textDim, fontSize: 13)),
          Text(value, style: TextStyle(color: valueColor, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSuccessRatePanel(GachaProvider provider, result, GachaTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.neonGreen),
        boxShadow: theme.glow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '─── 성공확률 계산 ───',
            style: TextStyle(color: theme.neonGreen, fontSize: 12, letterSpacing: 1),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Text('계획 뽑기수', style: TextStyle(color: theme.textDim, fontSize: 13)),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: TextEditingController(text: provider.plannedPulls.toString()),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => provider.setPlannedPulls(int.tryParse(v) ?? 100),
                  style: TextStyle(color: theme.neonGreen, fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.bgInput,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: theme.neonGreen),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: theme.neonGreen),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('뽑', style: TextStyle(color: theme.textDim, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),

          if (result != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.neonGreen.withOpacity(0.07),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: theme.neonGreen.withOpacity(0.27)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${provider.plannedPulls}뽑으로 ${provider.targetCopies}장 얻을 확률',
                    style: TextStyle(fontSize: 12, color: theme.textDim),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatPercent(result.plannedSuccessRate)}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.neonGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '예상비용: ${_formatNumber(provider.plannedPulls * provider.pricePerPull)}원',
                    style: TextStyle(fontSize: 12, color: theme.textDim),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeelingCard(ProbabilityFeeling feeling, GachaTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 "${feeling.event}" (${feeling.rate}%) 정도의 확률',
            style: TextStyle(fontSize: 12, color: theme.neonCyan),
          ),
          const SizedBox(height: 4),
          Text(
            feeling.feeling,
            style: TextStyle(fontSize: 11, color: theme.textDim),
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
