import 'dart:math';

// ========== 확률 체감 데이터 ==========
class ProbabilityFeeling {
  final double rate;
  final String event;
  final String feeling;

  const ProbabilityFeeling({
    required this.rate,
    required this.event,
    required this.feeling,
  });
}

const List<ProbabilityFeeling> fallbackProbabilityData = [
  ProbabilityFeeling(rate: 0.00012, event: "벼락 맞음", feeling: "83만 명 중 1명"),
  ProbabilityFeeling(rate: 0.0025, event: "오버부킹 탑승거절", feeling: "4만 명 중 1명"),
  ProbabilityFeeling(rate: 0.02, event: "네잎클로버 발견", feeling: "5000개 중 하나"),
  ProbabilityFeeling(rate: 0.06, event: "타이어 펑크", feeling: "운전자의 악몽"),
  ProbabilityFeeling(rate: 0.34, event: "일란성 쌍둥이", feeling: "주변에 있어? 그 확률"),
  ProbabilityFeeling(rate: 0.4, event: "쌍알 (노른자 2개)", feeling: "운수대통"),
  ProbabilityFeeling(rate: 0.5, event: "입구 앞 주차 명당", feeling: "오늘 운 좋은데?"),
  ProbabilityFeeling(rate: 1.2, event: "버스 도착하자마자 탑승", feeling: "1%의 행운"),
  ProbabilityFeeling(rate: 3.5, event: "택배 파손", feeling: "25번 중 1번"),
  ProbabilityFeeling(rate: 4.8, event: "신호등 5개 연속 통과", feeling: "무정차로 뚫었어?"),
  ProbabilityFeeling(rate: 5.6, event: "연간 접촉사고", feeling: "17.9년에 한 번"),
  ProbabilityFeeling(rate: 7, event: "핸드폰 두고 나감", feeling: "'아 씨 핸드폰!'"),
  ProbabilityFeeling(rate: 9.5, event: "왼손잡이", feeling: "10명 중 1명"),
  ProbabilityFeeling(rate: 12, event: "문자 잘못 보냄", feeling: "등골 오싹"),
  ProbabilityFeeling(rate: 15, event: "양말 한 짝 실종", feeling: "빨래 미스터리"),
  ProbabilityFeeling(rate: 16.7, event: "연간 식중독", feeling: "6명 중 1명"),
  ProbabilityFeeling(rate: 17, event: "올 그린 신호", feeling: "한 번도 안 멈춤"),
  ProbabilityFeeling(rate: 18, event: "장바구니 결제 완료", feeling: "5명 중 1명만 삼"),
  ProbabilityFeeling(rate: 20.5, event: "아는 사람 우연히 마주침", feeling: "대충 나왔는데!"),
  ProbabilityFeeling(rate: 29, event: "연간 폰 문제", feeling: "4명 중 1명"),
  ProbabilityFeeling(rate: 30, event: "알람 듣고 바로 일어남", feeling: "10명 중 3명"),
  ProbabilityFeeling(rate: 35, event: "새해 목표 유지", feeling: "3명 중 1명"),
  ProbabilityFeeling(rate: 50, event: "이어폰 꼬임", feeling: "반반이야 ㅋㅋ"),
  ProbabilityFeeling(rate: 62, event: "토스트 버터면 착지", feeling: "머피의 법칙"),
  ProbabilityFeeling(rate: 65, event: "새해 목표 포기", feeling: "3명 중 2명"),
  ProbabilityFeeling(rate: 70, event: "알람 끄고 다시 잠", feeling: "10명 중 7명"),
  ProbabilityFeeling(rate: 71, event: "연간 폰 멀쩡", feeling: "4명 중 3명"),
  ProbabilityFeeling(rate: 82, event: "장바구니 포기", feeling: "5명 중 4명"),
  ProbabilityFeeling(rate: 83.3, event: "연간 식중독 안 걸림", feeling: "6명 중 5명"),
  ProbabilityFeeling(rate: 99.9, event: "벼락 안 맞음", feeling: "거의 확실"),
];

ProbabilityFeeling? findClosestProbability(double targetRate, List<ProbabilityFeeling> data) {
  if (targetRate <= 0 || data.isEmpty) return null;
  if (targetRate >= 100) {
    return const ProbabilityFeeling(rate: 100, event: "확실함", feeling: "무조건 됨");
  }

  ProbabilityFeeling? closest;
  double minDiff = double.infinity;

  for (final item in data) {
    if (item.rate <= 0) continue;
    final diff = (log(item.rate) - log(targetRate)).abs();
    if (diff < minDiff) {
      minDiff = diff;
      closest = item;
    }
  }

  return closest;
}

String formatPercent(double value) {
  if (value >= 10) return value.toStringAsFixed(1);
  if (value >= 1) return value.toStringAsFixed(2);
  if (value >= 0.1) return value.toStringAsFixed(3);
  if (value >= 0.01) return value.toStringAsFixed(4);
  return value.toStringAsFixed(5);
}
