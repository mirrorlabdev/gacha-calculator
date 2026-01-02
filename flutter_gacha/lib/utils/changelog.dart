// Changelog 데이터 모델 및 데이터

class ChangelogEntry {
  final String version;
  final String date;
  final List<String> changes;

  const ChangelogEntry({
    required this.version,
    required this.date,
    required this.changes,
  });
}

// 최신순 정렬
const List<ChangelogEntry> changelog = [
  ChangelogEntry(
    version: "0.7.4",
    date: "2025-01-02",
    changes: [
      "앱 아이콘 추가",
      "이미지 공유 기능 (기본모드 + 프로모드)",
      "공유 텍스트 개선 (변수 설정 포함)",
      "업데이트 공지 기능 추가",
      "계산 진행률 표시 + 취소 기능",
      "접근성 개선 (대비, 터치 영역, 시스템 폰트 크기)",
      "보장 타입 전환 시 결과 초기화",
      "알림 메시지 숫자 끊김 현상 수정",
    ],
  ),
  ChangelogEntry(
    version: "0.7.3",
    date: "2025-01-01",
    changes: [
      "React에서 Flutter로 전환",
      "기본모드 / 프로모드 구현",
      "확률 계산 엔진 구현",
      "다크모드 지원",
    ],
  ),
];

// 현재 앱 버전 (pubspec.yaml과 동기화 필요)
const String currentAppVersion = "0.7.4";
