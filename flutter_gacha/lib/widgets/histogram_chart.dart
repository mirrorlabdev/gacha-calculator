import 'package:flutter/material.dart';
import '../models/calculation_result.dart';
import '../utils/themes.dart';

class HistogramChart extends StatelessWidget {
  final ProResult result;
  final GachaTheme theme;

  const HistogramChart({
    super.key,
    required this.result,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final maxPercent = result.histogram.map((b) => b.percent).reduce((a, b) => a > b ? a : b);

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
            '─── 확률분포 ───',
            style: TextStyle(color: theme.neonCyan, fontSize: 12, letterSpacing: 1),
          ),
          const SizedBox(height: 12),

          // 히스토그램 바
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                result.histogram.length,
                (i) {
                  final bin = result.histogram[i];
                  final height = maxPercent > 0 ? (bin.percent / maxPercent) * 100 : 0.0;
                  final isP50 = bin.start <= result.p50 && result.p50 < bin.end;
                  final isP90 = bin.start <= result.p90 && result.p90 < bin.end;

                  Color barColor;
                  double opacity;
                  if (isP90) {
                    barColor = theme.neonPink;
                    opacity = 1;
                  } else if (isP50) {
                    barColor = theme.neonCyan;
                    opacity = 1;
                  } else {
                    barColor = theme.neonGreen;
                    opacity = 0.6;
                  }

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Tooltip(
                        message: '${bin.start}-${bin.end}뽑: ${bin.percent.toStringAsFixed(1)}%',
                        child: Container(
                          height: height.clamp(2, 100),
                          decoration: BoxDecoration(
                            color: barColor.withOpacity(opacity),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 레전드
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('최소 ${result.min}', style: TextStyle(fontSize: 11, color: theme.textDim)),
              Text('중앙값 ${result.p50}', style: TextStyle(fontSize: 11, color: theme.neonCyan)),
              Text('상위10% ${result.p90}', style: TextStyle(fontSize: 11, color: theme.neonPink)),
              Text('최대 ${result.max}', style: TextStyle(fontSize: 11, color: theme.textDim)),
            ],
          ),
        ],
      ),
    );
  }
}
