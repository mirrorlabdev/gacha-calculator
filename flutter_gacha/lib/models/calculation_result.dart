// ========== 기본 모드 결과 ==========
class BasicResult {
  final int median;
  final int p90;
  final int p99;
  final double expected;
  final Map<String, int> costs;
  final Map<String, String> chickens;
  final double effectiveRatePercent;
  final double plannedSuccessRate;
  final double? cycleSuccessRate;
  final double? firstCycleSuccessRate;
  final int? remainingPity;
  final int completedCycles;
  final bool hasPity;

  const BasicResult({
    this.median = 0,
    this.p90 = 0,
    this.p99 = 0,
    this.expected = 0,
    this.costs = const {'median': 0, 'p90': 0, 'p99': 0},
    this.chickens = const {'median': '0', 'p90': '0', 'p99': '0'},
    this.effectiveRatePercent = 0,
    this.plannedSuccessRate = 0,
    this.cycleSuccessRate,
    this.firstCycleSuccessRate,
    this.remainingPity,
    this.completedCycles = 0,
    this.hasPity = false,
  });
}

// ========== 히스토그램 데이터 ==========
class HistogramBin {
  final int start;
  final int end;
  final double percent;

  const HistogramBin({
    required this.start,
    required this.end,
    required this.percent,
  });
}

// ========== 프로 모드 결과 ==========
class ProResult {
  final double mean;
  final double stdDev;
  final int min;
  final int max;
  final int p10;
  final int p25;
  final int p50;
  final int p75;
  final int p90;
  final int p95;
  final int p99;
  final List<HistogramBin> histogram;
  final double plannedSuccessRate;
  final Map<String, int> costs;
  final int targetCopies;

  const ProResult({
    required this.mean,
    required this.stdDev,
    required this.min,
    required this.max,
    required this.p10,
    required this.p25,
    required this.p50,
    required this.p75,
    required this.p90,
    required this.p95,
    required this.p99,
    required this.histogram,
    required this.plannedSuccessRate,
    required this.costs,
    required this.targetCopies,
  });
}
