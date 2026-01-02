import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/calculation_result.dart';
import '../providers/gacha_provider.dart';
import '../utils/themes.dart';

class ResultImageCapture {
  static Future<void> captureAndShare(
    BuildContext context,
    GachaProvider provider,
    GachaTheme theme,
  ) async {
    if (!provider.hasCalculated || provider.proResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('먼저 계산을 실행해주세요.')),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: theme.bgCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: theme.neonGreen, strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text('이미지 생성 중...', style: TextStyle(color: theme.text, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Create the widget to capture
      final captureWidget = _ResultCard(
        provider: provider,
        result: provider.proResult!,
        theme: theme,
      );

      // Create a repaint boundary key
      final repaintBoundaryKey = GlobalKey();

      // Create an overlay entry to render the widget offscreen
      final overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: -10000, // Render offscreen
          top: -10000,
          child: RepaintBoundary(
            key: repaintBoundaryKey,
            child: Material(
              color: Colors.transparent,
              child: captureWidget,
            ),
          ),
        ),
      );

      // Insert the overlay
      Overlay.of(context).insert(overlayEntry);

      // Wait for the widget to be rendered
      await Future.delayed(const Duration(milliseconds: 100));

      // Capture the image
      final boundary = repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Failed to find render boundary');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      // Remove the overlay
      overlayEntry.remove();

      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/gacha_result_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Share the image
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '가챠 계산기 PRO 결과',
      );
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 생성 실패: $e')),
        );
      }
    }
  }
}

class _ResultCard extends StatelessWidget {
  final GachaProvider provider;
  final ProResult result;
  final GachaTheme theme;

  const _ResultCard({
    required this.provider,
    required this.result,
    required this.theme,
  });

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  String _formatPercent(double value) {
    if (value >= 99.99) return '99.99';
    if (value <= 0.01) return '0.01';
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: theme.headerGradient,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.neonGreen, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '▶',
                  style: TextStyle(color: theme.neonGreen, fontSize: 18),
                ),
                const SizedBox(width: 8),
                const Text(
                  '가챠 분석기 PRO',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Variables Panel
          _buildSection(
            title: '변수 설정',
            titleColor: theme.neonCyan,
            children: [
              _buildRow('기본확률', '${provider.rate}%'),
              _buildRow('천장', provider.noPity ? '없음' : '${provider.pity}뽑'),
              if (provider.softPityStart > 0) ...[
                _buildRow('소프트 천장', '${provider.softPityStart}뽑부터 +${provider.softPityIncrease}%'),
              ],
              if (provider.pickupRate < 100) ...[
                _buildRow('픽업확률', '${provider.pickupRate}% (${provider.guaranteeOnFail ? '실패시확정' : '매번독립'})'),
              ],
              _buildRow('뽑기당 가격', '${_formatNumber(provider.pricePerPull)}원'),
            ],
          ),
          const SizedBox(height: 12),

          // Statistics Panel
          _buildSection(
            title: '${provider.targetCopies}장 목표 통계',
            titleColor: theme.neonCyan,
            children: [
              _buildRow('기대값', '${result.mean.toStringAsFixed(1)}뽑', valueColor: theme.neonGreen),
              _buildRow('표준편차', '±${result.stdDev.toStringAsFixed(1)}'),
              const SizedBox(height: 8),
              _buildRow('운 좋으면 (상위10%)', '${result.p10}뽑', valueColor: const Color(0xFF4ADE80)),
              _buildRow('중앙값 (절반)', '${result.p50}뽑', valueColor: theme.neonCyan),
              _buildRow('운 나쁘면 (하위10%)', '${result.p90}뽑', valueColor: const Color(0xFFFBBF24)),
              _buildRow('극악 (하위1%)', '${result.p99}뽑', valueColor: theme.neonPink),
            ],
          ),
          const SizedBox(height: 12),

          // Cost Panel
          _buildSection(
            title: '예상 비용',
            titleColor: theme.neonCyan,
            children: [
              _buildRow('중앙값 비용', '${_formatNumber(result.costs['p50'] ?? 0)}원'),
              _buildRow('운나쁨 비용', '${_formatNumber(result.costs['p90'] ?? 0)}원'),
            ],
          ),
          const SizedBox(height: 12),

          // Success Rate Panel
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.neonGreen),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '─── 성공확률 계산 ───',
                  style: TextStyle(color: theme.neonGreen, fontSize: 11, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${provider.plannedPulls}뽑 성공률',
                      style: TextStyle(color: theme.textDim, fontSize: 13),
                    ),
                    Text(
                      '${_formatPercent(result.plannedSuccessRate)}%',
                      style: TextStyle(
                        color: theme.neonGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Footer
          Text(
            '가챠 계산기 PRO',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: theme.textDim),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Color titleColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '─── $title ───',
            style: TextStyle(color: titleColor, fontSize: 11, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: theme.textDim, fontSize: 12)),
          Text(value, style: TextStyle(color: valueColor ?? theme.text, fontSize: 12)),
        ],
      ),
    );
  }
}

// ========== 기본모드 이미지 캡처 ==========

class BasicResultImageCapture {
  static Future<void> captureAndShare(
    BuildContext context,
    GachaProvider provider,
    GachaTheme theme,
  ) async {
    if (!provider.hasCalculated || provider.basicResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 계산을 실행해주세요.')),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: theme.bgCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: theme.accent, strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text('이미지 생성 중...', style: TextStyle(color: theme.text, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final captureWidget = _BasicResultCard(
        provider: provider,
        result: provider.basicResult!,
        theme: theme,
      );

      final repaintBoundaryKey = GlobalKey();

      final overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: -10000,
          top: -10000,
          child: RepaintBoundary(
            key: repaintBoundaryKey,
            child: Material(
              color: Colors.transparent,
              child: captureWidget,
            ),
          ),
        ),
      );

      Overlay.of(context).insert(overlayEntry);
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary = repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Failed to find render boundary');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      overlayEntry.remove();

      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/gacha_result_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '가챠 계산기 결과',
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 생성 실패: $e')),
        );
      }
    }
  }
}

class _BasicResultCard extends StatelessWidget {
  final GachaProvider provider;
  final BasicResult result;
  final GachaTheme theme;

  const _BasicResultCard({
    required this.provider,
    required this.result,
    required this.theme,
  });

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  String _formatPercent(double value) {
    if (value >= 99.99) return '99.99';
    if (value <= 0.01) return '0.01';
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final pityTypeLabel = provider.pityType == 'pickup' ? '픽업 보장' : '등급 보장';

    return Container(
      width: 360,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '가챠 계산기',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Variables Panel
          _buildSection(
            title: '변수 설정',
            children: [
              _buildRow('보장 타입', pityTypeLabel),
              _buildRow('확률', '${provider.rate}%'),
              _buildRow('천장', provider.noPity ? '없음' : '${provider.pity}뽑'),
              if (provider.pityType == 'grade') ...[
                _buildRow('등급 내 캐릭터', '${provider.charactersInGrade}개'),
                _buildRow('등급 당첨 시 리셋', provider.gradeResetOnHit ? '예' : '아니오'),
              ],
              _buildRow('뽑기당 가격', '${_formatNumber(provider.pricePerPull)}원'),
            ],
          ),
          const SizedBox(height: 12),

          // Results Panel
          _buildSection(
            title: '결과',
            children: [
              _buildRow('50% 확률', '${result.median}뽑', valueColor: theme.accent),
              _buildRow('', '${_formatNumber(result.costs['median'] ?? 0)}원', dimValue: true),
              const SizedBox(height: 4),
              _buildRow('90% 확률', '${result.p90}뽑', valueColor: Colors.orange),
              _buildRow('', '${_formatNumber(result.costs['p90'] ?? 0)}원', dimValue: true),
              const SizedBox(height: 4),
              _buildRow('99% 확률', '${result.p99}뽑', valueColor: Colors.red),
              _buildRow('', '${_formatNumber(result.costs['p99'] ?? 0)}원', dimValue: true),
            ],
          ),
          const SizedBox(height: 12),

          // Success Rate Panel
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.accent),
            ),
            child: Column(
              children: [
                Text(
                  '${provider.plannedPulls}뽑 성공률',
                  style: TextStyle(color: theme.textDim, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatPercent(result.plannedSuccessRate)}%',
                  style: TextStyle(
                    color: theme.accent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '예상 비용: ${_formatNumber(provider.plannedPulls * provider.pricePerPull)}원',
                  style: TextStyle(color: theme.textDim, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Footer
          Text(
            '가챠 계산기',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: theme.textDim),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: theme.accent, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor, bool dimValue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: theme.textDim, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              color: dimValue ? theme.textDim : (valueColor ?? theme.text),
              fontSize: dimValue ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
