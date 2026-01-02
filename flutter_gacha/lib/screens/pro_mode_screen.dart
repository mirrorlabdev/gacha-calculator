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
import '../widgets/result_image_capture.dart';
import '../widgets/calculation_progress.dart';
import '../widgets/chunked_text.dart';

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 헤더 (고정, glow 효과 포함)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildHeader(context, provider, theme),
                ),
                const SizedBox(height: 16),

                // 스크롤 영역 (순수 컨텐츠, glow 없음)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 변수 패널
                        _buildVariablesPanel(provider, theme),
                        const SizedBox(height: 16),

                        // 계산하기 버튼 또는 진행률 바
                        if (provider.isCalculating)
                          ProModeProgressBar(
                            progress: provider.calcProgress,
                            stage: provider.calcStage,
                            onCancel: () => provider.cancelCalculation(),
                            theme: theme,
                          )
                        else
                          OutlinedButton(
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              provider.calculate();
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.neonGreen, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              backgroundColor: theme.neonGreen.withOpacity(0.1),
                              alignment: Alignment.center,
                            ),
                            child: Text(
                              '계산하기',
                              style: TextStyle(
                                color: theme.neonGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),

                        // 확률분포 히스토그램
                        if (provider.hasCalculated && result != null) ...[
                          HistogramChart(result: result, theme: theme),
                          const SizedBox(height: 16),

                          // 통계 패널
                          _buildStatisticsPanel(result, provider, theme),
                          const SizedBox(height: 16),

                          // 성공확률 계산
                          _buildSuccessRatePanel(provider, result, theme),
                          const SizedBox(height: 16),

                          // 체감 문구
                          if (feeling != null)
                            _buildFeelingCard(feeling, theme),
                          if (feeling != null) const SizedBox(height: 16),

                          // 공유 버튼들
                          Row(
                            children: [
                              // 텍스트 공유
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _handleShare(provider),
                                  icon: Icon(Icons.text_snippet, size: 16, color: theme.neonGreen),
                                  label: Text(
                                    '텍스트 공유',
                                    style: TextStyle(
                                      color: theme.neonGreen,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: theme.neonGreen),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 이미지 공유
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => ResultImageCapture.captureAndShare(context, provider, theme),
                                  icon: Icon(Icons.image, size: 16, color: theme.neonCyan),
                                  label: Text(
                                    '이미지 공유',
                                    style: TextStyle(
                                      color: theme.neonCyan,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: theme.neonCyan),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

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
                        Center(
                          child: ChunkedText(
                            chunks: const ['본 앱은', '참고용', '확률 계산', '도구이며,', '계산 결과의', '정확성을', '보장하지', '않습니다.', '과금 결정에', '대한 책임은', '사용자', '본인에게', '있습니다.'],
                            style: TextStyle(fontSize: 10, color: theme.textDim, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, GachaProvider provider, GachaTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: theme.headerGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.neonGreen, width: 2),
        boxShadow: theme.glow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
              Text(
                '▶',
                style: TextStyle(
                  color: theme.neonGreen,
                  fontSize: 20,
                  shadows: [Shadow(color: theme.neonGreen, blurRadius: 10)],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    '가챠 계산기 PRO',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeaderButton(
                icon: provider.darkMode ? Icons.light_mode : Icons.dark_mode,
                onTap: () => provider.setDarkMode(!provider.darkMode),
                theme: theme,
              ),
              const SizedBox(width: 6),
              _buildHeaderButton(
                icon: Icons.settings,
                onTap: () => showSettingsModal(context, theme),
                theme: theme,
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => provider.toggleMode(false),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),  // 최소 터치 영역
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: theme.neonGreen.withOpacity(0.2),
                    border: Border.all(color: theme.neonGreen, width: 2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    widthFactor: 1.0,
                    heightFactor: 1.0,
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
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),  // 최소 터치 영역
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
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
            onValidate: (v) {
              final r = provider.validateRate(v);
              return _ProRangeAdjustResult(
                wasAdjusted: r.adjusted,
                message: r.message,
                correctedValue: r.value,
              );
            },
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
            onValidate: provider.noPity ? null : (v) {
              final r = provider.validatePity(v);
              return _ProRangeAdjustResult(
                wasAdjusted: r.adjusted,
                message: r.message,
                correctedValue: r.value.toDouble(),
              );
            },
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
            onValidate: (v) {
              final r = provider.validateTargetCopies(v);
              return _ProRangeAdjustResult(
                wasAdjusted: r.adjusted,
                message: r.message,
                correctedValue: r.value.toDouble(),
              );
            },
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
            onValidate: (v) {
              final r = provider.validatePrice(v);
              return _ProRangeAdjustResult(
                wasAdjusted: r.adjusted,
                message: r.message,
                correctedValue: r.value.toDouble(),
              );
            },
          ),

          // 초기화
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Divider(color: theme.border),
          ),
          TextButton(
            onPressed: () => showResetConfirmModal(context, provider, theme),
            style: TextButton.styleFrom(alignment: Alignment.center),
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
    _ProRangeAdjustResult Function(String value)? onValidate,
  }) {
    return _ProInputRow(
      label: label,
      helpId: helpId,
      value: value,
      onChanged: onChanged,
      suffix: suffix,
      theme: theme,
      isInt: isInt,
      width: width,
      suffixColor: suffixColor,
      onValidate: onValidate,
    );
  }

  Widget _buildSoftPityRow(GachaProvider provider, GachaTheme theme) {
    return _SoftPityRow(provider: provider, theme: theme);
  }

  Widget _buildPickupRateRow(GachaProvider provider, GachaTheme theme) {
    return _PickupRateRow(provider: provider, theme: theme);
  }

  Widget _buildGuaranteeRow(GachaProvider provider, GachaTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('확정권', style: TextStyle(color: theme.textDim, fontSize: 13)),
                  HelpTooltip(id: 'guarantee', theme: theme),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToggleButton('실패시 확정', true, provider.guaranteeOnFail, (v) => provider.setGuaranteeOnFail(v), theme),
                  const SizedBox(width: 6),
                  _buildToggleButton('매번 독립', false, !provider.guaranteeOnFail, (v) => provider.setGuaranteeOnFail(v), theme),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          ChunkedText(
            chunks: provider.guaranteeOnFail ? const ['(원신식', '50/50)'] : const ['(등급보장식)'],
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
        constraints: const BoxConstraints(minHeight: 44),  // 최소 터치 영역
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? theme.neonCyan.withOpacity(0.2) : Colors.transparent,
          border: Border.all(color: isSelected ? theme.neonCyan : theme.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Align(
          alignment: Alignment.center,
          widthFactor: 1.0,
          heightFactor: 1.0,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? theme.neonCyan : theme.textDim,
              fontSize: 12,
            ),
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
          onValidate: (v) {
            final r = provider.validateCurrentPulls(v);
            return _ProRangeAdjustResult(
              wasAdjusted: r.adjusted,
              message: r.message,
              correctedValue: r.value.toDouble(),
            );
          },
        ),
        if (!provider.noPity && provider.pity > 0 && provider.currentPulls > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: provider.currentPulls ~/ provider.pity > 0
                ? ChunkedText(
                    chunks: ['→', '천장', '${provider.currentPulls ~/ provider.pity}바퀴', '완료,', '다음 천장까지', '${provider.pity - (provider.currentPulls % provider.pity)}뽑', '남음'],
                    style: TextStyle(fontSize: 11, color: theme.neonCyan),
                  )
                : ChunkedText(
                    chunks: ['→', '첫 천장까지', '${provider.pity - provider.currentPulls}뽑', '남음'],
                    style: TextStyle(fontSize: 11, color: theme.neonCyan),
                  ),
          ),
      ],
    );
  }

  Widget _buildCurrentGuaranteeRow(GachaProvider provider, GachaTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('확정권 보유', style: TextStyle(color: theme.textDim, fontSize: 13)),
          GestureDetector(
            onTap: () => provider.setCurrentGuarantee(!provider.currentGuarantee),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),  // 최소 터치 영역
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: provider.currentGuarantee ? theme.neonCyan.withOpacity(0.2) : Colors.transparent,
                border: Border.all(color: provider.currentGuarantee ? theme.neonCyan : theme.border),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Align(
                alignment: Alignment.center,
                widthFactor: 1.0,
                heightFactor: 1.0,
                child: Text(
                  provider.currentGuarantee ? '예 (다음 확정)' : '아니오',
                  style: TextStyle(
                    color: provider.currentGuarantee ? theme.neonCyan : theme.textDim,
                    fontSize: 12,
                  ),
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
          ChunkedText(
            chunks: ['───', '통계', '(${provider.targetCopies}장 목표)', '───'],
            style: TextStyle(color: theme.neonCyan, fontSize: 12, letterSpacing: 1),
          ),
          const SizedBox(height: 12),

          _buildStatRow('기대값', '${result.mean.toStringAsFixed(1)}뽑', theme.neonGreen, theme),
          _buildStatRow('표준편차', '±${result.stdDev.toStringAsFixed(1)}', theme.text, theme),
          Divider(color: theme.border, height: 16),
          _buildStatRow('운\u00A0좋으면 (상위10%)', '${result.p10}뽑', const Color(0xFF4ADE80), theme),
          _buildStatRow('중앙값 (절반)', '${result.p50}뽑', theme.neonCyan, theme),
          _buildStatRow('운\u00A0나쁘면 (하위10%)', '${result.p90}뽑', const Color(0xFFFBBF24), theme),
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
          const SizedBox(width: 8),
          Text(value, style: TextStyle(color: valueColor, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSuccessRatePanel(GachaProvider provider, result, GachaTheme theme) {
    return _SuccessRatePanel(provider: provider, result: result, theme: theme);
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
            '💡 "${feeling.event}" (${feeling.rate}%) 정도의\u00A0확률',
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

// 범위 조정 결과 (pro mode용, message는 청크 배열)
class _ProRangeAdjustResult {
  final bool wasAdjusted;
  final List<String>? message;  // 한글 줄바꿈 최적화를 위한 청크 배열
  final double correctedValue;

  const _ProRangeAdjustResult({
    required this.wasAdjusted,
    this.message,
    required this.correctedValue,
  });
}

// StatefulWidget for input row with empty value support
class _ProInputRow extends StatefulWidget {
  final String label;
  final String? helpId;
  final double value;
  final ValueChanged<double> onChanged;
  final String suffix;
  final GachaTheme theme;
  final bool isInt;
  final double width;
  final Color? suffixColor;
  final _ProRangeAdjustResult Function(String value)? onValidate;

  const _ProInputRow({
    required this.label,
    this.helpId,
    required this.value,
    required this.onChanged,
    required this.suffix,
    required this.theme,
    this.isInt = false,
    this.width = 80,
    this.suffixColor,
    this.onValidate,
  });

  @override
  State<_ProInputRow> createState() => _ProInputRowState();
}

class _ProInputRowState extends State<_ProInputRow> {
  late TextEditingController _controller;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.isInt ? widget.value.toInt().toString() : widget.value.toString(),
    );
  }

  @override
  void didUpdateWidget(_ProInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newText = widget.isInt ? widget.value.toInt().toString() : widget.value.toString();
    if (!_hasFocus && newText != _controller.text) {
      _controller.text = newText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange(bool hasFocus) {
    setState(() => _hasFocus = hasFocus);
    // 포커스를 잃을 때 범위 검증
    if (!hasFocus && widget.onValidate != null) {
      final result = widget.onValidate!(_controller.text);
      if (result.wasAdjusted) {
        final newText = widget.isInt
            ? result.correctedValue.toInt().toString()
            : result.correctedValue.toString();
        _controller.text = newText;
        widget.onChanged(result.correctedValue);
        if (result.message != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: ChunkedText(chunks: result.message!),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label, style: TextStyle(color: widget.theme.textDim, fontSize: 13)),
              if (widget.helpId != null) HelpTooltip(id: widget.helpId!, theme: widget.theme),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: widget.width,
                child: Focus(
                  onFocusChange: _handleFocusChange,
                  child: TextField(
                    controller: _controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) {
                      if (v.isEmpty) return;
                      widget.onChanged(double.tryParse(v) ?? 0);
                    },
                    style: TextStyle(color: widget.theme.neonGreen, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: widget.theme.bgInput,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: widget.theme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: widget.theme.border),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(widget.suffix, style: TextStyle(color: widget.suffixColor ?? widget.theme.textDim, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// StatefulWidget for soft pity row
class _SoftPityRow extends StatefulWidget {
  final GachaProvider provider;
  final GachaTheme theme;

  const _SoftPityRow({required this.provider, required this.theme});

  @override
  State<_SoftPityRow> createState() => _SoftPityRowState();
}

class _SoftPityRowState extends State<_SoftPityRow> {
  late TextEditingController _startController;
  late TextEditingController _increaseController;
  bool _startHasFocus = false;
  bool _increaseHasFocus = false;

  @override
  void initState() {
    super.initState();
    _startController = TextEditingController(text: widget.provider.softPityStart.toString());
    _increaseController = TextEditingController(text: widget.provider.softPityIncrease.toString());
  }

  @override
  void didUpdateWidget(_SoftPityRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_startHasFocus && widget.provider.softPityStart.toString() != _startController.text) {
      _startController.text = widget.provider.softPityStart.toString();
    }
    if (!_increaseHasFocus && widget.provider.softPityIncrease.toString() != _increaseController.text) {
      _increaseController.text = widget.provider.softPityIncrease.toString();
    }
  }

  @override
  void dispose() {
    _startController.dispose();
    _increaseController.dispose();
    super.dispose();
  }

  void _handleStartFocusChange(bool hasFocus) {
    setState(() => _startHasFocus = hasFocus);
    if (!hasFocus) {
      final r = widget.provider.validateSoftPityStart(_startController.text);
      if (r.adjusted) {
        _startController.text = r.value.toString();
        widget.provider.setSoftPityStart(r.value);
        if (r.message != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: ChunkedText(chunks: r.message!), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  void _handleIncreaseFocusChange(bool hasFocus) {
    setState(() => _increaseHasFocus = hasFocus);
    if (!hasFocus) {
      final r = widget.provider.validateSoftPityIncrease(_increaseController.text);
      if (r.adjusted) {
        _increaseController.text = r.value.toString();
        widget.provider.setSoftPityIncrease(r.value);
        if (r.message != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: ChunkedText(chunks: r.message!), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final theme = widget.theme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('소프트 천장', style: TextStyle(color: theme.textDim, fontSize: 13)),
              HelpTooltip(id: 'softPity', theme: theme),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 55,
                child: Focus(
                  onFocusChange: _handleStartFocusChange,
                  child: TextField(
                    controller: _startController,
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      if (v.isEmpty) return;
                      provider.setSoftPityStart(int.tryParse(v) ?? 0);
                    },
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
              ),
              Text(' 뽑부터 ', style: TextStyle(color: theme.textDim, fontSize: 12)),
              Text('+', style: TextStyle(color: theme.neonCyan)),
              SizedBox(
                width: 45,
                child: Focus(
                  onFocusChange: _handleIncreaseFocusChange,
                  child: TextField(
                    controller: _increaseController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) {
                      if (v.isEmpty) return;
                      provider.setSoftPityIncrease(double.tryParse(v) ?? 0);
                    },
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
              ),
              Text(' %씩', style: TextStyle(color: theme.textDim, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// StatefulWidget for pickup rate row
class _PickupRateRow extends StatefulWidget {
  final GachaProvider provider;
  final GachaTheme theme;

  const _PickupRateRow({required this.provider, required this.theme});

  @override
  State<_PickupRateRow> createState() => _PickupRateRowState();
}

class _PickupRateRowState extends State<_PickupRateRow> {
  late TextEditingController _controller;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.provider.pickupRate.toString());
  }

  @override
  void didUpdateWidget(_PickupRateRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasFocus && widget.provider.pickupRate.toString() != _controller.text) {
      _controller.text = widget.provider.pickupRate.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange(bool hasFocus) {
    setState(() => _hasFocus = hasFocus);
    if (!hasFocus) {
      final r = widget.provider.validatePickupRate(_controller.text);
      if (r.adjusted) {
        _controller.text = r.value.toString();
        widget.provider.setPickupRate(r.value);
        if (r.message != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: ChunkedText(chunks: r.message!), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  Widget _buildQuickButton(String label, double value, double current, ValueChanged<double> onTap, GachaTheme theme) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),  // 최소 터치 영역
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? theme.neonPurple.withOpacity(0.2) : Colors.transparent,
          border: Border.all(color: isSelected ? theme.neonPurple : theme.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Align(
          alignment: Alignment.center,
          widthFactor: 1.0,
          heightFactor: 1.0,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? theme.neonPurple : theme.textDim,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final theme = widget.theme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('픽업확률', style: TextStyle(color: theme.textDim, fontSize: 13)),
                  HelpTooltip(id: 'pickup', theme: theme),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 70,
                    child: Focus(
                      onFocusChange: _handleFocusChange,
                      child: TextField(
                        controller: _controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (v) {
                          if (v.isEmpty) return;
                          final parsed = double.tryParse(v);
                          if (parsed == null || parsed <= 0) return;
                          provider.setPickupRate(parsed);
                        },
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
                  ),
                  const SizedBox(width: 8),
                  Text('%', style: TextStyle(color: theme.textDim, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildQuickButton('확정', 100, provider.pickupRate, (v) => provider.setPickupRate(v), theme),
              _buildQuickButton('50/50', 50, provider.pickupRate, (v) => provider.setPickupRate(v), theme),
              _buildQuickButton('75/25', 75, provider.pickupRate, (v) => provider.setPickupRate(v), theme),
            ],
          ),
          const SizedBox(height: 4),
          ChunkedText(
            chunks: ['당첨 시', '원하는 캐릭', '확률', '(등급 내 n명 →', '${(100 / provider.pickupRate).toStringAsFixed(1)}명 중 1명)'],
            style: TextStyle(fontSize: 11, color: theme.textDim),
          ),
        ],
      ),
    );
  }
}

// StatefulWidget for success rate panel
class _SuccessRatePanel extends StatefulWidget {
  final GachaProvider provider;
  final dynamic result;
  final GachaTheme theme;

  const _SuccessRatePanel({required this.provider, required this.result, required this.theme});

  @override
  State<_SuccessRatePanel> createState() => _SuccessRatePanelState();
}

class _SuccessRatePanelState extends State<_SuccessRatePanel> {
  late TextEditingController _controller;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.provider.plannedPulls.toString());
  }

  @override
  void didUpdateWidget(_SuccessRatePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasFocus && widget.provider.plannedPulls.toString() != _controller.text) {
      _controller.text = widget.provider.plannedPulls.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange(bool hasFocus) {
    setState(() => _hasFocus = hasFocus);
    if (!hasFocus) {
      final r = widget.provider.validatePlannedPulls(_controller.text);
      if (r.adjusted) {
        _controller.text = r.value.toString();
        widget.provider.setPlannedPulls(r.value);
        if (r.message != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: ChunkedText(chunks: r.message!), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final result = widget.result;
    final theme = widget.theme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.neonGreen),
        // glow 제거: 스크롤 캡처 호환성을 위해 글로우 효과 제거
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
                child: Focus(
                  onFocusChange: _handleFocusChange,
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      if (v.isEmpty) return;
                      provider.setPlannedPulls(int.tryParse(v) ?? 0);
                    },
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
                  ChunkedText(
                    chunks: ['${provider.plannedPulls}뽑으로', '${provider.targetCopies}장', '얻을 확률'],
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
                  ChunkedText(
                    chunks: ['예상비용:', '${_formatNumber(provider.plannedPulls * provider.pricePerPull)}원'],
                    style: TextStyle(fontSize: 12, color: theme.textDim),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
