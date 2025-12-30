import 'dart:math';
import '../models/calculation_result.dart';

// ========== 기본 모드 계산 ==========
class BasicCalculator {
  static BasicResult calculate({
    required double rate,
    required int pity,
    required int pricePerPull,
    required int currentPulls,
    required String pityType,
    required int charactersInGrade,
    required int plannedPulls,
    required bool noPity,
    required bool gradeResetOnHit,
  }) {
    final gradeRate = rate / 100;
    if (gradeRate <= 0 || gradeRate > 1) return const BasicResult();
    if (plannedPulls < 1) return const BasicResult();
    if (pricePerPull < 0) return const BasicResult();

    final hasPity = !noPity && pity > 0;
    final validCurrentPulls = hasPity ? (currentPulls % pity) : 0;
    final remainingPity = hasPity ? (pity - validCurrentPulls) : null;
    final completedCycles = hasPity ? (currentPulls ~/ pity) : 0;

    if (pityType == 'pickup') {
      final effectiveRate = gradeRate;

      double getSuccessRate(int n) {
        if (hasPity && remainingPity != null && n >= remainingPity) return 1;
        return (1 - pow(1 - effectiveRate, n)).toDouble();
      }

      int findPullsForProb(double targetProb) {
        if (effectiveRate >= 1) return 1;
        if (targetProb <= 0) return 1;
        if (targetProb >= 1) return hasPity && remainingPity != null ? remainingPity : 99999;
        final pullsNeeded = (log(1 - targetProb) / log(1 - effectiveRate)).ceil();
        if (hasPity && remainingPity != null && pullsNeeded > remainingPity) {
          return remainingPity;
        }
        return pullsNeeded;
      }

      final expected = hasPity && remainingPity != null
          ? min(1 / effectiveRate, remainingPity.toDouble())
          : 1 / effectiveRate;
      final median = findPullsForProb(0.5);
      final p90 = findPullsForProb(0.9);
      final p99 = findPullsForProb(0.99);
      final plannedSuccessRate = getSuccessRate(plannedPulls) * 100;

      final costs = {
        'median': median * pricePerPull,
        'p90': p90 * pricePerPull,
        'p99': p99 * pricePerPull,
      };

      final chickens = {
        'median': (costs['median']! / 20000).toStringAsFixed(1),
        'p90': (costs['p90']! / 20000).toStringAsFixed(1),
        'p99': (costs['p99']! / 20000).toStringAsFixed(1),
      };

      return BasicResult(
        median: median,
        p90: p90,
        p99: p99,
        expected: expected,
        costs: costs,
        chickens: chickens,
        effectiveRatePercent: effectiveRate * 100,
        plannedSuccessRate: plannedSuccessRate,
        remainingPity: remainingPity,
        completedCycles: completedCycles,
        hasPity: hasPity,
      );
    } else {
      // 등급 보장 모드
      if (charactersInGrade < 1) return const BasicResult();

      final charRate = 1 / charactersInGrade;
      final specificCharRate = gradeRate * charRate;

      if (!hasPity) {
        double getSuccessRate(int n) => (1 - pow(1 - specificCharRate, n)).toDouble();

        int findPullsForProb(double targetProb) {
          if (specificCharRate >= 1) return 1;
          if (targetProb <= 0) return 1;
          if (targetProb >= 1) return 99999;
          return (log(1 - targetProb) / log(1 - specificCharRate)).ceil();
        }

        final median = findPullsForProb(0.5);
        final p90 = findPullsForProb(0.9);
        final p99 = findPullsForProb(0.99);
        final expected = 1 / specificCharRate;
        final plannedSuccessRate = getSuccessRate(plannedPulls) * 100;

        final costs = {
          'median': median * pricePerPull,
          'p90': p90 * pricePerPull,
          'p99': p99 * pricePerPull,
        };

        final chickens = {
          'median': (costs['median']! / 20000).toStringAsFixed(1),
          'p90': (costs['p90']! / 20000).toStringAsFixed(1),
          'p99': (costs['p99']! / 20000).toStringAsFixed(1),
        };

        return BasicResult(
          median: median,
          p90: p90,
          p99: p99,
          expected: expected,
          costs: costs,
          chickens: chickens,
          effectiveRatePercent: specificCharRate * 100,
          plannedSuccessRate: plannedSuccessRate,
          remainingPity: null,
          completedCycles: 0,
          hasPity: false,
        );
      }

      // ========== 등급 당첨 시 천장 리셋 (DP) ==========
      if (gradeResetOnHit) {
        final g = gradeRate;  // 등급 당첨 확률
        final c = charRate;   // 등급 내 특정 캐릭 확률

        // f[j] = 천장 카운트가 j일 때 아직 원하는 캐릭 못 뽑았을 확률
        var f = List<double>.filled(pity, 0);
        f[validCurrentPulls] = 1.0;

        double getSuccessRateByPulls(int n) {
          if (n <= 0) return 0;

          var state = List<double>.from(f);
          for (var pull = 0; pull < n; pull++) {
            final newState = List<double>.filled(pity, 0);
            for (var j = 0; j < pity; j++) {
              if (state[j] < 1e-15) continue;

              if (j < pity - 1) {
                // 일반 뽑기: g×c → 성공, g×(1-c) → 리셋, (1-g) → j+1
                // 성공은 state에서 빠짐
                newState[0] += state[j] * g * (1 - c);  // 다른 캐릭 → 리셋
                newState[j + 1] += state[j] * (1 - g); // 꽝 → 카운트 증가
              } else {
                // 천장 (j == pity-1): c → 성공, (1-c) → 리셋
                // 성공은 state에서 빠짐
                newState[0] += state[j] * (1 - c);  // 다른 캐릭 → 리셋
              }
            }
            state = newState;
          }

          final failProb = state.reduce((a, b) => a + b);
          return 1 - failProb;
        }

        int findPullsForProb(double targetProb) {
          if (targetProb <= 0) return 1;
          if (targetProb >= 1) return pity * 100;

          var state = List<double>.from(f);
          for (var n = 1; n <= pity * 100; n++) {
            final newState = List<double>.filled(pity, 0);
            for (var j = 0; j < pity; j++) {
              if (state[j] < 1e-15) continue;

              if (j < pity - 1) {
                newState[0] += state[j] * g * (1 - c);
                newState[j + 1] += state[j] * (1 - g);
              } else {
                newState[0] += state[j] * (1 - c);
              }
            }
            state = newState;

            final failProb = state.reduce((a, b) => a + b);
            if (1 - failProb >= targetProb) return n;
          }
          return pity * 100;
        }

        // 기대값 계산 (DP로 계산)
        double calcExpected() {
          var state = List<double>.from(f);
          var expected = 0.0;
          for (var n = 1; n <= pity * 200; n++) {
            final newState = List<double>.filled(pity, 0);
            var successThisPull = 0.0;

            for (var j = 0; j < pity; j++) {
              if (state[j] < 1e-15) continue;

              if (j < pity - 1) {
                successThisPull += state[j] * g * c;
                newState[0] += state[j] * g * (1 - c);
                newState[j + 1] += state[j] * (1 - g);
              } else {
                successThisPull += state[j] * c;
                newState[0] += state[j] * (1 - c);
              }
            }

            expected += n * successThisPull;
            state = newState;

            if (state.reduce((a, b) => a + b) < 1e-12) break;
          }
          return expected;
        }

        final median = findPullsForProb(0.5);
        final p90 = findPullsForProb(0.9);
        final p99 = findPullsForProb(0.99);
        final expectedPulls = calcExpected();
        final plannedSuccessRate = getSuccessRateByPulls(plannedPulls) * 100;

        final costs = {
          'median': median * pricePerPull,
          'p90': p90 * pricePerPull,
          'p99': p99 * pricePerPull,
        };

        final chickens = {
          'median': (costs['median']! / 20000).toStringAsFixed(1),
          'p90': (costs['p90']! / 20000).toStringAsFixed(1),
          'p99': (costs['p99']! / 20000).toStringAsFixed(1),
        };

        return BasicResult(
          median: median,
          p90: p90,
          p99: p99,
          expected: expectedPulls,
          costs: costs,
          chickens: chickens,
          effectiveRatePercent: specificCharRate * 100,
          plannedSuccessRate: plannedSuccessRate,
          remainingPity: remainingPity,
          completedCycles: completedCycles,
          hasPity: true,
        );
      }

      // ========== 등급 당첨 시 천장 리셋 안 함 (기존) ==========
      final remaining = remainingPity!;
      final failFirstCycle = pow(1 - specificCharRate, remaining - 1) * (1 - charRate);
      final successFirstCycle = 1 - failFirstCycle;
      final failNormalCycle = pow(1 - specificCharRate, pity - 1) * (1 - charRate);
      final successNormalCycle = 1 - failNormalCycle;

      double getSuccessRateByPulls(int n) {
        if (n <= 0) return 0;

        if (n <= remaining) {
          if (n < remaining) {
            return (1 - pow(1 - specificCharRate, n)).toDouble();
          } else {
            return successFirstCycle;
          }
        }

        final pullsAfterFirst = n - remaining;
        final fullCyclesAfterFirst = pullsAfterFirst ~/ pity;
        final remainingInCycle = pullsAfterFirst % pity;

        var failProb = failFirstCycle;
        failProb *= pow(failNormalCycle, fullCyclesAfterFirst);

        if (remainingInCycle > 0) {
          failProb *= pow(1 - specificCharRate, remainingInCycle);
        }

        return 1 - failProb;
      }

      int findPullsForProb(double targetProb) {
        final maxPulls = pity * 100;
        for (var n = 1; n <= maxPulls; n++) {
          if (getSuccessRateByPulls(n) >= targetProb) return n;
        }
        return maxPulls;
      }

      final median = findPullsForProb(0.5);
      final p90 = findPullsForProb(0.9);
      final p99 = findPullsForProb(0.99);

      final expectedCycles = 1 / successNormalCycle;
      final expectedPulls = remaining + (expectedCycles - 1) * pity;
      final plannedSuccessRate = getSuccessRateByPulls(plannedPulls) * 100;

      final costs = {
        'median': median * pricePerPull,
        'p90': p90 * pricePerPull,
        'p99': p99 * pricePerPull,
      };

      final chickens = {
        'median': (costs['median']! / 20000).toStringAsFixed(1),
        'p90': (costs['p90']! / 20000).toStringAsFixed(1),
        'p99': (costs['p99']! / 20000).toStringAsFixed(1),
      };

      return BasicResult(
        median: median,
        p90: p90,
        p99: p99,
        expected: expectedPulls,
        costs: costs,
        chickens: chickens,
        effectiveRatePercent: specificCharRate * 100,
        cycleSuccessRate: successNormalCycle * 100,
        firstCycleSuccessRate: successFirstCycle * 100,
        plannedSuccessRate: plannedSuccessRate,
        remainingPity: remaining,
        completedCycles: completedCycles,
        hasPity: true,
      );
    }
  }
}

// ========== 프로 모드 계산 (DP 알고리즘) ==========
class ProCalculator {
  static ProResult? calculate({
    required double rate,
    required int pity,
    required bool noPity,
    required int softPityStart,
    required double softPityIncrease,
    required double pickupRate,
    required bool guaranteeOnFail,
    required int targetCopies,
    required int plannedPulls,
    required int pricePerPull,
    required int currentPulls,
    required bool currentGuarantee,
  }) {
    try {
      final baseRate = rate / 100;
      if (baseRate <= 0 || baseRate > 1) return null;

      final hasPity = !noPity && pity > 0;
      final hasSoftPity = softPityStart > 0 && (!hasPity || softPityStart < pity);
      final softPityRate = softPityIncrease / 100;
      final winRate = pickupRate / 100;

      // 스택 기반 확률 함수
      double getRateAtStack(int stackCount) {
        if (!hasSoftPity || stackCount < softPityStart) return baseRate;
        final softPulls = stackCount - softPityStart + 1;
        return min(1.0, baseRate + softPityRate * softPulls);
      }

      // ========== 1카피 픽업 분포 계산 ==========
      List<double> calculateSinglePickupDist(int startPity, bool startGuarantee) {
        final remainingToPity = hasPity ? pity - startPity : 999999;
        const eps = 1e-12;
        const hardCap = 50000;
        final maxPulls = hasPity ? remainingToPity : hardCap;

        // 최고등급 당첨 분포
        final hitDist = List<double>.filled(min(maxPulls + 1, hardCap + 1), 0);
        var survival = 1.0;
        var actualMax = maxPulls;

        for (var k = 1; k <= maxPulls && k < hitDist.length; k++) {
          final stack = startPity + k;
          final pullRate = getRateAtStack(stack);

          if (hasPity && k == remainingToPity) {
            hitDist[k] = survival;
            survival = 0;
            actualMax = k;
            break;
          } else {
            hitDist[k] = survival * pullRate;
            survival *= (1 - pullRate);

            if (!hasPity && survival < eps) {
              actualMax = k;
              break;
            }
          }
        }

        // winRate = 1이면 당첨 = 픽업
        if (winRate >= 1) return hitDist;

        // ========== 독립 모드 ==========
        if (!guaranteeOnFail) {
          final effectiveRate = baseRate * winRate;
          const safeMax = 20000;
          final maxIndie = min(safeMax, hasPity ? (pity / winRate).ceil() * 3 : (20 / effectiveRate).ceil());

          final result = List<double>.filled(maxIndie + 1, 0);

          final effectivePity = hasPity ? pity : (15 / baseRate).ceil();
          var survivalState = List<double>.filled(effectivePity + 1, 0);
          survivalState[startPity] = 1;

          for (var k = 1; k <= maxIndie; k++) {
            final newSurvival = List<double>.filled(effectivePity + 1, 0);

            for (var i = 0; i < effectivePity; i++) {
              if (survivalState[i] < 1e-12) continue;

              final pullRate = getRateAtStack(i + 1);
              final actualPullRate = (hasPity && i + 1 >= pity) ? 1.0 : pullRate;

              result[k] += survivalState[i] * actualPullRate * winRate;
              newSurvival[0] += survivalState[i] * actualPullRate * (1 - winRate);

              if (actualPullRate < 1 && i + 1 < effectivePity) {
                newSurvival[i + 1] += survivalState[i] * (1 - actualPullRate);
              }
            }

            survivalState = newSurvival;
            final totalSurv = survivalState.reduce((a, b) => a + b);
            if (totalSurv < 1e-12) break;
          }

          return result;
        }

        // ========== 50/50 모드 ==========
        final freshMaxPulls = hasPity ? pity : min(2000, (10 / baseRate).ceil());
        final safeSize = hasPity ? pity * 3 : 5000;
        final result = List<double>.filled(safeSize + 1, 0);

        if (startGuarantee) {
          for (var k = 1; k < hitDist.length; k++) {
            if (k < result.length) result[k] = hitDist[k];
          }
        } else {
          // 바로 성공
          for (var k = 1; k < hitDist.length; k++) {
            if (k < result.length) result[k] += hitDist[k] * winRate;
          }

          // 실패 후 확정
          final freshDist = List<double>.filled(freshMaxPulls + 1, 0);
          var freshSurv = 1.0;
          for (var k = 1; k <= freshMaxPulls; k++) {
            final pullRate = getRateAtStack(k);
            if (hasPity && k == pity) {
              freshDist[k] = freshSurv;
              freshSurv = 0;
            } else {
              freshDist[k] = freshSurv * pullRate;
              freshSurv *= (1 - pullRate);
            }
          }

          // Convolution
          for (var first = 1; first < hitDist.length; first++) {
            final failProb = hitDist[first] * (1 - winRate);
            if (failProb < 1e-12) continue;
            for (var second = 1; second < freshDist.length; second++) {
              if (first + second < result.length) {
                result[first + second] += failProb * freshDist[second];
              }
            }
          }
        }

        return result;
      }

      // ========== 현재 상태 ==========
      final currentPity = hasPity ? (currentPulls % pity) : currentPulls;

      // ========== 첫 카피 분포 ==========
      final firstCopyDist = calculateSinglePickupDist(currentPity, currentGuarantee);

      // ========== N카피 분포 ==========
      List<double> multiCopyDist;
      const safeMaxTotal = 50000;

      if (targetCopies == 1) {
        multiCopyDist = firstCopyDist;
      } else {
        final freshCopyDist = calculateSinglePickupDist(0, false);
        multiCopyDist = List<double>.from(firstCopyDist);

        for (var copy = 1; copy < targetCopies; copy++) {
          final newDist = List<double>.filled(
            min(safeMaxTotal, multiCopyDist.length + freshCopyDist.length),
            0,
          );
          for (var i = 0; i < multiCopyDist.length; i++) {
            if (multiCopyDist[i] < 1e-12) continue;
            for (var j = 1; j < freshCopyDist.length; j++) {
              if (freshCopyDist[j] < 1e-12) continue;
              if (i + j < newDist.length) {
                newDist[i + j] += multiCopyDist[i] * freshCopyDist[j];
              }
            }
          }
          multiCopyDist = newDist;
        }
      }

      // ========== 분포 정규화 ==========
      if (multiCopyDist.isEmpty) return null;
      final sumProb = multiCopyDist.reduce((a, b) => a + b);
      if (sumProb <= 0) return null;
      if (hasPity && (sumProb - 1).abs() > 1e-8) {
        for (var i = 0; i < multiCopyDist.length; i++) {
          multiCopyDist[i] /= sumProb;
        }
      }

      // ========== 통계 계산 ==========
      final cdf = List<double>.filled(multiCopyDist.length, 0);
      cdf[0] = multiCopyDist[0];
      for (var i = 1; i < multiCopyDist.length; i++) {
        cdf[i] = cdf[i - 1] + multiCopyDist[i];
      }

      int findPercentile(double p) {
        for (var i = 0; i < cdf.length; i++) {
          if (cdf[i] >= p) return i;
        }
        return cdf.length - 1;
      }

      var mean = 0.0;
      for (var i = 1; i < multiCopyDist.length; i++) {
        mean += i * multiCopyDist[i];
      }

      var variance = 0.0;
      for (var i = 1; i < multiCopyDist.length; i++) {
        variance += multiCopyDist[i] * pow(i - mean, 2);
      }
      final stdDev = sqrt(variance);

      final p10 = findPercentile(0.1);
      final p25 = findPercentile(0.25);
      final p50 = findPercentile(0.5);
      final p75 = findPercentile(0.75);
      final p90 = findPercentile(0.9);
      final p95 = findPercentile(0.95);
      final p99 = findPercentile(0.99);

      var minVal = 1, maxVal = multiCopyDist.length - 1;
      for (var i = 1; i < multiCopyDist.length; i++) {
        if (multiCopyDist[i] > 0.0001) {
          minVal = i;
          break;
        }
      }
      for (var i = multiCopyDist.length - 1; i >= 1; i--) {
        if (multiCopyDist[i] > 0.0001) {
          maxVal = i;
          break;
        }
      }

      // ========== 히스토그램 데이터 ==========
      const binCount = 30;
      final range = maxVal - minVal + 1;
      final binSize = max(1, (range / binCount).ceil());
      final histogram = <HistogramBin>[];

      for (var i = 0; i < binCount; i++) {
        final binStart = minVal + i * binSize;
        final binEnd = min(binStart + binSize, maxVal + 1);
        var binProb = 0.0;
        for (var k = binStart; k < binEnd && k < multiCopyDist.length; k++) {
          binProb += multiCopyDist[k];
        }
        histogram.add(HistogramBin(
          start: binStart,
          end: binEnd,
          percent: binProb * 100,
        ));
      }

      // N뽑 성공확률
      final safeIndex = plannedPulls;
      final plannedSuccessRate = (safeIndex < cdf.length ? cdf[safeIndex] : 1.0) * 100;

      return ProResult(
        mean: mean,
        stdDev: stdDev,
        min: minVal,
        max: maxVal,
        p10: p10,
        p25: p25,
        p50: p50,
        p75: p75,
        p90: p90,
        p95: p95,
        p99: p99,
        histogram: histogram,
        plannedSuccessRate: plannedSuccessRate,
        costs: {
          'mean': (mean * pricePerPull).round(),
          'p50': p50 * pricePerPull,
          'p90': p90 * pricePerPull,
          'p99': p99 * pricePerPull,
        },
        targetCopies: targetCopies,
      );
    } catch (e) {
      return null;
    }
  }
}
