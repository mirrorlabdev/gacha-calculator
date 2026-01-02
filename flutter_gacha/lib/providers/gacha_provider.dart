import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calculation_result.dart';
import '../utils/calculator.dart';
import '../utils/probability_data.dart';

class GachaProvider extends ChangeNotifier {
  // ========== Storage Keys ==========
  static const String _keyCommon = 'gachaCalc_common';
  static const String _keyBasic = 'gachaCalc_basic';
  static const String _keyPro = 'gachaCalc_pro';

  // ========== 기본 모드 State ==========
  double _rate = 1;
  int _pity = 100;
  int _pricePerPull = 2000;
  int _currentPulls = 0;
  String _pityType = 'grade';
  int _charactersInGrade = 22;
  int _plannedPulls = 100;
  bool _noPity = false;
  bool _gradeResetOnHit = true;  // 등급 당첨 시 천장 리셋

  // ========== 프로모드 State ==========
  bool _proMode = false;
  int _softPityStart = 0;
  double _softPityIncrease = 6;
  double _pickupRate = 100;
  bool _guaranteeOnFail = true;
  int _targetCopies = 1;
  bool _currentGuarantee = false;

  // ========== UI State ==========
  bool _darkMode = false;
  bool _isLoaded = false;
  bool _isCalculating = false;
  bool _hasCalculated = false;

  // ========== 계산 진행률 State ==========
  double _calcProgress = 0.0;  // 0.0 ~ 1.0
  String? _calcStage;  // 현재 계산 단계 설명
  Isolate? _calcIsolate;
  ReceivePort? _calcReceivePort;

  // ========== 폰트 설정 ==========
  String _proModeFont = 'D2Coding';  // D2Coding, NotoSansMonoKR
  String _basicModeFont = 'Pretendard';  // IBMPlexSansKR, Pretendard, NotoSansKR

  // ========== Cached Results ==========
  BasicResult? _basicResultCache;
  ProResult? _proResultCache;

  // ========== Getters ==========
  double get rate => _rate;
  int get pity => _pity;
  int get pricePerPull => _pricePerPull;
  int get currentPulls => _currentPulls;
  String get pityType => _pityType;
  int get charactersInGrade => _charactersInGrade;
  int get plannedPulls => _plannedPulls;
  bool get noPity => _noPity;
  bool get gradeResetOnHit => _gradeResetOnHit;
  bool get proMode => _proMode;
  int get softPityStart => _softPityStart;
  double get softPityIncrease => _softPityIncrease;
  double get pickupRate => _pickupRate;
  bool get guaranteeOnFail => _guaranteeOnFail;
  int get targetCopies => _targetCopies;
  bool get currentGuarantee => _currentGuarantee;
  bool get darkMode => _darkMode;
  bool get isLoaded => _isLoaded;
  bool get isCalculating => _isCalculating;
  bool get hasCalculated => _hasCalculated;
  double get calcProgress => _calcProgress;
  String? get calcStage => _calcStage;
  String get proModeFont => _proModeFont;
  String get basicModeFont => _basicModeFont;

  // ========== 범위 검증 헬퍼 ==========
  // message는 청크 배열 (한글 줄바꿈 최적화용)

  /// 확률 검증 (0.001 ~ 100)
  ({bool adjusted, List<String>? message, double value}) validateRate(String input) {
    final parsed = double.tryParse(input) ?? 0;
    if (parsed < 0.001) {
      return (adjusted: true, message: ['확률이', '0.001%로', '조정됐어요', '(최소 0.001%)'], value: 0.001);
    }
    if (parsed > 100) {
      return (adjusted: true, message: ['확률이', '100%로', '조정됐어요', '(최대 100%)'], value: 100.0);
    }
    return (adjusted: false, message: null, value: parsed);
  }

  /// 천장 검증 (1 ~ 2500)
  ({bool adjusted, List<String>? message, int value}) validatePity(String input) {
    final parsed = int.tryParse(input) ?? 1;
    if (parsed < 1) {
      return (adjusted: true, message: ['천장이', '1회로', '조정됐어요', '(최소 1회)'], value: 1);
    }
    if (parsed > 2500) {
      return (adjusted: true, message: ['천장이', '2500회로', '조정됐어요', '(최대 2500회)'], value: 2500);
    }
    return (adjusted: false, message: null, value: parsed);
  }

  /// 현재 뽑기 수 검증 (0 ~ 2500)
  ({bool adjusted, List<String>? message, int value}) validateCurrentPulls(String input) {
    final parsed = int.tryParse(input) ?? 0;
    if (parsed < 0) {
      return (adjusted: true, message: ['현재 뽑기가', '0회로', '조정됐어요', '(최소 0회)'], value: 0);
    }
    if (parsed > 2500) {
      return (adjusted: true, message: ['현재 뽑기가', '2500회로', '조정됐어요', '(최대 2500회)'], value: 2500);
    }
    return (adjusted: false, message: null, value: parsed);
  }

  /// 가격 검증 (0 ~ 999999999)
  ({bool adjusted, List<String>? message, int value}) validatePrice(String input) {
    final parsed = int.tryParse(input) ?? 0;
    if (parsed < 0) {
      return (adjusted: true, message: ['가격이', '0원으로', '조정됐어요', '(최소 0원)'], value: 0);
    }
    if (parsed > 999999999) {
      return (adjusted: true, message: ['가격이', '9억원으로', '조정됐어요', '(최대)'], value: 999999999);
    }
    return (adjusted: false, message: null, value: parsed);
  }

  /// 계획 뽑기 수 검증 (1 ~ 99999)
  ({bool adjusted, List<String>? message, int value}) validatePlannedPulls(String input) {
    final parsed = int.tryParse(input) ?? 1;
    if (parsed < 1) {
      return (adjusted: true, message: ['계획 뽑기가', '1회로', '조정됐어요', '(최소 1회)'], value: 1);
    }
    if (parsed > 99999) {
      return (adjusted: true, message: ['계획 뽑기가', '99999회로', '조정됐어요', '(최대)'], value: 99999);
    }
    return (adjusted: false, message: null, value: parsed);
  }

  /// 등급 내 캐릭터 수 검증 (1 ~ 1000)
  ({bool adjusted, List<String>? message, int value}) validateCharactersInGrade(String input) {
    final parsed = int.tryParse(input) ?? 1;
    if (parsed < 1) {
      return (adjusted: true, message: ['캐릭터 수가', '1명으로', '조정됐어요', '(최소 1명)'], value: 1);
    }
    if (parsed > 1000) {
      return (adjusted: true, message: ['캐릭터 수가', '1000명으로', '조정됐어요', '(최대)'], value: 1000);
    }
    return (adjusted: false, message: null, value: parsed);
  }

  /// 소프트 천장 검증 (0 ~ 2500)
  ({bool adjusted, List<String>? message, int value}) validateSoftPityStart(String input) {
    final parsed = int.tryParse(input) ?? 0;
    if (parsed < 0) {
      return (adjusted: true, message: ['소프트 천장이', '0으로', '조정됐어요', '(최소 0)'], value: 0);
    }
    if (parsed > 2500) {
      return (adjusted: true, message: ['소프트 천장이', '2500으로', '조정됐어요', '(최대)'], value: 2500);
    }
    return (adjusted: false, message: null, value: parsed);
  }

  /// 소프트 천장 증가율 검증 (0 ~ 100)
  ({bool adjusted, List<String>? message, double value}) validateSoftPityIncrease(String input) {
    final parsed = double.tryParse(input) ?? 0;
    if (parsed < 0) {
      return (adjusted: true, message: ['증가율이', '0%로', '조정됐어요', '(최소 0%)'], value: 0.0);
    }
    if (parsed > 100) {
      return (adjusted: true, message: ['증가율이', '100%로', '조정됐어요', '(최대 100%)'], value: 100.0);
    }
    return (adjusted: false, message: null, value: parsed);
  }

  /// 픽업 확률 검증 (0.1 ~ 100)
  ({bool adjusted, List<String>? message, double value}) validatePickupRate(String input) {
    final parsed = double.tryParse(input) ?? 50;
    if (parsed < 0.1) {
      return (adjusted: true, message: ['픽업 확률이', '0.1%로', '조정됐어요', '(최소 0.1%)'], value: 0.1);
    }
    if (parsed > 100) {
      return (adjusted: true, message: ['픽업 확률이', '100%로', '조정됐어요', '(최대 100%)'], value: 100.0);
    }
    return (adjusted: false, message: null, value: parsed);
  }

  /// 목표 장수 검증 (1 ~ 20)
  ({bool adjusted, List<String>? message, int value}) validateTargetCopies(String input) {
    final parsed = int.tryParse(input) ?? 1;
    if (parsed < 1) {
      return (adjusted: true, message: ['목표 장수가', '1장으로', '조정됐어요', '(최소 1장)'], value: 1);
    }
    if (parsed > 20) {
      return (adjusted: true, message: ['목표 장수가', '20장으로', '조정됐어요', '(최대 20장)'], value: 20);
    }
    return (adjusted: false, message: null, value: parsed);
  }

  // ========== Setters ==========
  void setRate(double value) {
    _rate = value.clamp(0.001, 100);
    _saveCurrentMode();
    notifyListeners();
  }

  void setPity(int value) {
    _pity = value.clamp(1, 2500);
    _saveCurrentMode();
    notifyListeners();
  }

  void setPricePerPull(int value) {
    _pricePerPull = value.clamp(0, 999999999);
    _saveCurrentMode();
    notifyListeners();
  }

  void setCurrentPulls(int value) {
    _currentPulls = value.clamp(0, 2500);
    _saveCurrentMode();
    notifyListeners();
  }

  void setPityType(String value) {
    if (_pityType != value) {
      _pityType = value;
      // 보장 타입 변경 시 결과 초기화
      _hasCalculated = false;
      _basicResultCache = null;
      _saveCurrentMode();
      notifyListeners();
    }
  }

  void setCharactersInGrade(int value) {
    _charactersInGrade = value.clamp(1, 1000);
    _saveCurrentMode();
    notifyListeners();
  }

  void setPlannedPulls(int value) {
    _plannedPulls = value.clamp(1, 99999);
    _saveCurrentMode();
    notifyListeners();
  }

  void setNoPity(bool value) {
    _noPity = value;
    _saveCurrentMode();
    notifyListeners();
  }

  void setGradeResetOnHit(bool value) {
    _gradeResetOnHit = value;
    _saveCurrentMode();
    notifyListeners();
  }

  void setSoftPityStart(int value) {
    _softPityStart = value.clamp(0, 2500);
    _saveCurrentMode();
    notifyListeners();
  }

  void setSoftPityIncrease(double value) {
    _softPityIncrease = value.clamp(0, 100);
    _saveCurrentMode();
    notifyListeners();
  }

  void setPickupRate(double value) {
    _pickupRate = value.clamp(0.1, 100);
    _saveCurrentMode();
    notifyListeners();
  }

  void setGuaranteeOnFail(bool value) {
    _guaranteeOnFail = value;
    _saveCurrentMode();
    notifyListeners();
  }

  void setTargetCopies(int value) {
    _targetCopies = value.clamp(1, 20);
    _saveCurrentMode();
    notifyListeners();
  }

  void setCurrentGuarantee(bool value) {
    _currentGuarantee = value;
    _saveCurrentMode();
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _darkMode = value;
    _saveCommon();
    notifyListeners();
  }

  void setProModeFont(String value) {
    _proModeFont = value;
    _saveCommon();
    notifyListeners();
  }

  void setBasicModeFont(String value) {
    _basicModeFont = value;
    _saveCommon();
    notifyListeners();
  }

  // ========== 모드 전환 ==========
  Future<void> toggleMode(bool targetProMode) async {
    if (!_isLoaded) return;

    // 현재 모드 저장
    await _saveCurrentMode();

    // 모드 전환
    _proMode = targetProMode;

    // 캐시 초기화
    _hasCalculated = false;
    _basicResultCache = null;
    _proResultCache = null;

    // 새 모드 로드
    await _loadModeData(targetProMode);

    await _saveCommon();
    notifyListeners();
  }

  // ========== 초기화 ==========
  void reset() {
    _rate = 1;
    _pity = 100;
    _pricePerPull = 2000;
    _currentPulls = 0;
    _plannedPulls = 100;
    _noPity = false;

    if (_proMode) {
      _softPityStart = 0;
      _softPityIncrease = 6;
      _pickupRate = 100;
      _guaranteeOnFail = true;
      _targetCopies = 1;
      _currentGuarantee = false;
    } else {
      _pityType = 'grade';
      _charactersInGrade = 22;
    }

    // 캐시 초기화
    _hasCalculated = false;
    _basicResultCache = null;
    _proResultCache = null;

    _saveCurrentMode();
    notifyListeners();
  }

  // ========== 계산 결과 ==========
  BasicResult? get basicResult => _basicResultCache;
  ProResult? get proResult => _proResultCache;

  // ========== 계산 취소 ==========
  void cancelCalculation() {
    if (_calcIsolate != null) {
      _calcIsolate!.kill(priority: Isolate.immediate);
      _calcIsolate = null;
    }
    _calcReceivePort?.close();
    _calcReceivePort = null;
    _isCalculating = false;
    _calcProgress = 0.0;
    _calcStage = null;
    notifyListeners();
  }

  // ========== 계산 실행 (별도 isolate에서 실행, 진행률 지원) ==========
  Future<void> calculate() async {
    // 이전 계산 정리
    cancelCalculation();

    _isCalculating = true;
    _calcProgress = 0.0;
    _calcStage = '시작 중...';
    notifyListeners();

    try {
      _calcReceivePort = ReceivePort();

      if (_proMode) {
        final params = ProCalcParams(
          rate: _rate,
          pity: _pity,
          noPity: _noPity,
          softPityStart: _softPityStart,
          softPityIncrease: _softPityIncrease,
          pickupRate: _pickupRate,
          guaranteeOnFail: _guaranteeOnFail,
          targetCopies: _targetCopies,
          plannedPulls: _plannedPulls,
          pricePerPull: _pricePerPull,
          currentPulls: _currentPulls,
          currentGuarantee: _currentGuarantee,
        );

        final message = IsolateCalcMessage(
          sendPort: _calcReceivePort!.sendPort,
          params: params,
          isProMode: true,
        );

        _calcIsolate = await Isolate.spawn(calculatorIsolateEntry, message);

        await for (final msg in _calcReceivePort!) {
          if (msg is ProgressMessage) {
            _calcProgress = msg.progress;
            _calcStage = msg.stage;
            notifyListeners();
          } else if (msg is ResultMessage<ProResult?>) {
            _proResultCache = msg.result;
            if (msg.error != null) {
              debugPrint('Calculation error: ${msg.error}');
            }
            break;
          }
        }
      } else {
        final params = BasicCalcParams(
          rate: _rate,
          pity: _pity,
          pricePerPull: _pricePerPull,
          currentPulls: _currentPulls,
          pityType: _pityType,
          charactersInGrade: _charactersInGrade,
          plannedPulls: _plannedPulls,
          noPity: _noPity,
          gradeResetOnHit: _gradeResetOnHit,
        );

        final message = IsolateCalcMessage(
          sendPort: _calcReceivePort!.sendPort,
          params: params,
          isProMode: false,
        );

        _calcIsolate = await Isolate.spawn(calculatorIsolateEntry, message);

        await for (final msg in _calcReceivePort!) {
          if (msg is ProgressMessage) {
            _calcProgress = msg.progress;
            _calcStage = msg.stage;
            notifyListeners();
          } else if (msg is ResultMessage<BasicResult>) {
            _basicResultCache = msg.result;
            if (msg.error != null) {
              debugPrint('Calculation error: ${msg.error}');
            }
            break;
          }
        }
      }
      _hasCalculated = true;
    } catch (e) {
      debugPrint('Calculation error: $e');
    }

    _calcReceivePort?.close();
    _calcReceivePort = null;
    _calcIsolate = null;
    _isCalculating = false;
    _calcProgress = 1.0;
    notifyListeners();
  }

  ProbabilityFeeling? get feelingData {
    if (!_hasCalculated) return null;
    final successRate = _proMode && proResult != null
        ? proResult!.plannedSuccessRate
        : basicResult?.plannedSuccessRate ?? 0;
    if (successRate <= 0) return null;
    return findClosestProbability(successRate, fallbackProbabilityData);
  }

  // ========== Storage ==========
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 공통 설정 로드
      final commonStr = prefs.getString(_keyCommon);
      if (commonStr != null) {
        final common = jsonDecode(commonStr);
        _darkMode = common['darkMode'] ?? false;
        _proMode = common['proMode'] ?? false;
        _proModeFont = common['proModeFont'] ?? 'D2Coding';
        _basicModeFont = common['basicModeFont'] ?? 'Pretendard';
      }

      // 현재 모드 데이터 로드
      await _loadModeData(_proMode);

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load settings: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _loadModeData(bool isProMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = isProMode ? _keyPro : _keyBasic;
      final dataStr = prefs.getString(key);

      if (dataStr != null) {
        final data = jsonDecode(dataStr);
        _rate = (data['rate'] ?? 1).toDouble();
        _pity = data['pity'] ?? 100;
        _noPity = data['noPity'] ?? false;
        _pricePerPull = data['pricePerPull'] ?? 2000;
        _plannedPulls = data['plannedPulls'] ?? 100;
        _currentPulls = data['currentPulls'] ?? 0;

        if (!isProMode) {
          _pityType = data['pityType'] ?? 'grade';
          _charactersInGrade = data['charactersInGrade'] ?? 22;
          _gradeResetOnHit = data['gradeResetOnHit'] ?? true;
        } else {
          _softPityStart = data['softPityStart'] ?? 0;
          _softPityIncrease = (data['softPityIncrease'] ?? 6).toDouble();
          _pickupRate = (data['pickupRate'] ?? 100).toDouble();
          _guaranteeOnFail = data['guaranteeOnFail'] ?? true;
          _targetCopies = data['targetCopies'] ?? 1;
          _currentGuarantee = data['currentGuarantee'] ?? false;
        }
      }
    } catch (e) {
      debugPrint('Failed to load mode data: $e');
    }
  }

  Future<void> _saveCommon() async {
    if (!_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCommon, jsonEncode({
        'proMode': _proMode,
        'darkMode': _darkMode,
        'proModeFont': _proModeFont,
        'basicModeFont': _basicModeFont,
      }));
    } catch (e) {
      debugPrint('Failed to save common: $e');
    }
  }

  Future<void> _saveCurrentMode() async {
    if (!_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _proMode ? _keyPro : _keyBasic;
      await prefs.setString(key, jsonEncode({
        'rate': _rate,
        'pity': _pity,
        'noPity': _noPity,
        'pricePerPull': _pricePerPull,
        'plannedPulls': _plannedPulls,
        'currentPulls': _currentPulls,
        'pityType': _pityType,
        'charactersInGrade': _charactersInGrade,
        'gradeResetOnHit': _gradeResetOnHit,
        'softPityStart': _softPityStart,
        'softPityIncrease': _softPityIncrease,
        'pickupRate': _pickupRate,
        'guaranteeOnFail': _guaranteeOnFail,
        'targetCopies': _targetCopies,
        'currentGuarantee': _currentGuarantee,
      }));
    } catch (e) {
      debugPrint('Failed to save mode: $e');
    }
  }

  // ========== 공유 텍스트 ==========
  String getShareText() {
    if (!_hasCalculated) return '먼저 계산하기 버튼을 눌러주세요.';

    final successRate = _proMode && proResult != null
        ? proResult!.plannedSuccessRate
        : basicResult?.plannedSuccessRate ?? 0;

    if (_proMode && proResult != null) {
      final r = proResult!;
      final formatNum = (int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

      return '''🎰 가챠 계산기 PRO

═══ 변수 설정 ═══
• 기본확률: $_rate%
• 천장: ${_noPity ? '없음' : '$_pity뽑'}${_softPityStart > 0 ? '\n• 소프트 천장: $_softPityStart뽑부터 +$_softPityIncrease%' : ''}${_pickupRate < 100 ? '\n• 픽업확률: $_pickupRate% (${_guaranteeOnFail ? '실패시확정' : '매번독립'})' : ''}
• 뽑기당 가격: ${formatNum(_pricePerPull)}원

═══ ${_targetCopies}장 목표 통계 ═══
• 기대값: ${r.mean.toStringAsFixed(1)}뽑 (±${r.stdDev.toStringAsFixed(1)})
• 운 좋으면 (상위10%): ${r.p10}뽑
• 중앙값 (절반): ${r.p50}뽑
• 운 나쁘면 (하위10%): ${r.p90}뽑
• 극악 (하위1%): ${r.p99}뽑

═══ 예상 비용 ═══
• 중앙값 비용: ${formatNum(r.costs['p50'] ?? 0)}원
• 운나쁨 비용: ${formatNum(r.costs['p90'] ?? 0)}원

═══ 성공확률 계산 ═══
• $_plannedPulls뽑 성공률: ${formatPercent(successRate)}%''';
    } else if (basicResult != null) {
      final r = basicResult!;
      final formatNum = (int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

      final pityTypeLabel = _pityType == 'pickup' ? '픽업 보장' : '등급 보장';
      final gradeInfo = _pityType == 'grade'
          ? '\n• 등급 내 캐릭터: $_charactersInGrade개\n• 등급 당첨 시 리셋: ${_gradeResetOnHit ? '예' : '아니오'}'
          : '';

      return '''🎰 가챠 계산기

═══ 변수 설정 ═══
• 보장 타입: $pityTypeLabel
• 확률: $_rate%
• 천장: ${_noPity ? '없음' : '$_pity뽑'}$gradeInfo
• 뽑기당 가격: ${formatNum(_pricePerPull)}원

═══ 결과 ═══
• 50% 확률: ${r.median}뽑 (${formatNum(r.costs['median'] ?? 0)}원)
• 90% 확률: ${r.p90}뽑 (${formatNum(r.costs['p90'] ?? 0)}원)
• 99% 확률: ${r.p99}뽑 (${formatNum(r.costs['p99'] ?? 0)}원)

═══ 성공확률 계산 ═══
• $_plannedPulls뽑 성공률: ${formatPercent(successRate)}%
• 예상 비용: ${formatNum(_plannedPulls * _pricePerPull)}원''';
    }
    return '결과가 없습니다.';
  }
}
