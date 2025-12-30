import 'dart:convert';
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

  // ========== Getters ==========
  double get rate => _rate;
  int get pity => _pity;
  int get pricePerPull => _pricePerPull;
  int get currentPulls => _currentPulls;
  String get pityType => _pityType;
  int get charactersInGrade => _charactersInGrade;
  int get plannedPulls => _plannedPulls;
  bool get noPity => _noPity;
  bool get proMode => _proMode;
  int get softPityStart => _softPityStart;
  double get softPityIncrease => _softPityIncrease;
  double get pickupRate => _pickupRate;
  bool get guaranteeOnFail => _guaranteeOnFail;
  int get targetCopies => _targetCopies;
  bool get currentGuarantee => _currentGuarantee;
  bool get darkMode => _darkMode;
  bool get isLoaded => _isLoaded;

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
    _pityType = value;
    _saveCurrentMode();
    notifyListeners();
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

  // ========== 모드 전환 ==========
  Future<void> toggleMode(bool targetProMode) async {
    if (!_isLoaded) return;

    // 현재 모드 저장
    await _saveCurrentMode();

    // 모드 전환
    _proMode = targetProMode;

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

    _saveCurrentMode();
    notifyListeners();
  }

  // ========== 계산 결과 ==========
  BasicResult get basicResult => BasicCalculator.calculate(
    rate: _rate,
    pity: _pity,
    pricePerPull: _pricePerPull,
    currentPulls: _currentPulls,
    pityType: _pityType,
    charactersInGrade: _charactersInGrade,
    plannedPulls: _plannedPulls,
    noPity: _noPity,
  );

  ProResult? get proResult => ProCalculator.calculate(
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

  ProbabilityFeeling? get feelingData {
    final successRate = _proMode && proResult != null
        ? proResult!.plannedSuccessRate
        : basicResult.plannedSuccessRate;
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
    final successRate = _proMode && proResult != null
        ? proResult!.plannedSuccessRate
        : basicResult.plannedSuccessRate;

    if (_proMode && proResult != null) {
      final r = proResult!;
      return '''🎰 가챠 계산기 PRO

📊 ${_targetCopies}장 목표
확률: $_rate% | 천장: ${_noPity ? '없음' : '$_pity뽑'}
${_softPityStart > 0 ? '소프트 천장: $_softPityStart뽑부터 +$_softPityIncrease%\n' : ''}${_pickupRate < 100 ? '픽업확률: $_pickupRate% (${_guaranteeOnFail ? '실패시확정' : '매번독립'})\n' : ''}
📈 결과
기대값: ${r.mean.toStringAsFixed(1)}뽑 (±${r.stdDev.toStringAsFixed(1)})
중앙값: ${r.p50}뽑 | 상위10%: ${r.p90}뽑
$_plannedPulls뽑 성공률: ${formatPercent(successRate)}%''';
    } else {
      final r = basicResult;
      return '''🎰 가챠 계산기

$_plannedPulls뽑 했을 때 성공확률: ${formatPercent(successRate)}%
예상 비용: ${(_plannedPulls * _pricePerPull).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원

50% 확률: ${r.median}뽑
90% 확률: ${r.p90}뽑
99% 확률: ${r.p99}뽑''';
    }
  }
}
