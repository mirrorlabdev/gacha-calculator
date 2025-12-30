import React, { useState, useMemo, useEffect, useRef } from 'react';

// ========== 확률 체감 데이터 ==========
const PROBABILITY_DATA_URL = null;
const PROBABILITY_VERSION_URL = null;

const fallbackProbabilityData = [
  { rate: 0.00012, event: "벼락 맞음", feeling: "83만 명 중 1명" },
  { rate: 0.0025, event: "오버부킹 탑승거절", feeling: "4만 명 중 1명" },
  { rate: 0.02, event: "네잎클로버 발견", feeling: "5000개 중 하나" },
  { rate: 0.06, event: "타이어 펑크", feeling: "운전자의 악몽" },
  { rate: 0.34, event: "일란성 쌍둥이", feeling: "주변에 있어? 그 확률" },
  { rate: 0.4, event: "쌍알 (노른자 2개)", feeling: "운수대통" },
  { rate: 0.5, event: "입구 앞 주차 명당", feeling: "오늘 운 좋은데?" },
  { rate: 1.2, event: "버스 도착하자마자 탑승", feeling: "1%의 행운" },
  { rate: 3.5, event: "택배 파손", feeling: "25번 중 1번" },
  { rate: 4.8, event: "신호등 5개 연속 통과", feeling: "무정차로 뚫었어?" },
  { rate: 5.6, event: "연간 접촉사고", feeling: "17.9년에 한 번" },
  { rate: 7, event: "핸드폰 두고 나감", feeling: "'아 씨 핸드폰!'" },
  { rate: 9.5, event: "왼손잡이", feeling: "10명 중 1명" },
  { rate: 12, event: "문자 잘못 보냄", feeling: "등골 오싹" },
  { rate: 15, event: "양말 한 짝 실종", feeling: "빨래 미스터리" },
  { rate: 16.7, event: "연간 식중독", feeling: "6명 중 1명" },
  { rate: 17, event: "올 그린 신호", feeling: "한 번도 안 멈춤" },
  { rate: 18, event: "장바구니 결제 완료", feeling: "5명 중 1명만 삼" },
  { rate: 20.5, event: "아는 사람 우연히 마주침", feeling: "대충 나왔는데!" },
  { rate: 29, event: "연간 폰 문제", feeling: "4명 중 1명" },
  { rate: 30, event: "알람 듣고 바로 일어남", feeling: "10명 중 3명" },
  { rate: 35, event: "새해 목표 유지", feeling: "3명 중 1명" },
  { rate: 50, event: "이어폰 꼬임", feeling: "반반이야 ㅋㅋ" },
  { rate: 62, event: "토스트 버터면 착지", feeling: "머피의 법칙" },
  { rate: 65, event: "새해 목표 포기", feeling: "3명 중 2명" },
  { rate: 70, event: "알람 끄고 다시 잠", feeling: "10명 중 7명" },
  { rate: 71, event: "연간 폰 멀쩡", feeling: "4명 중 3명" },
  { rate: 82, event: "장바구니 포기", feeling: "5명 중 4명" },
  { rate: 83.3, event: "연간 식중독 안 걸림", feeling: "6명 중 5명" },
  { rate: 99.9, event: "벼락 안 맞음", feeling: "거의 확실" },
].sort((a, b) => a.rate - b.rate);

const findClosestProbability = (targetRate, data) => {
  try {
    if (!targetRate || targetRate <= 0 || !data || !Array.isArray(data) || data.length === 0) {
      return null;
    }
    if (targetRate >= 100) return { rate: 100, event: "확실함", feeling: "무조건 됨" };
    
    let closest = data[0];
    let minDiff = Infinity;
    
    for (const item of data) {
      if (!item || !item.rate || item.rate <= 0) continue;
      const diff = Math.abs(Math.log(item.rate) - Math.log(targetRate));
      if (diff < minDiff) {
        minDiff = diff;
        closest = item;
      }
    }
    return closest;
  } catch (error) {
    console.warn('findClosestProbability error:', error);
    return null;
  }
};

const formatPercent = (value) => {
  if (value >= 10) return value.toFixed(1);
  if (value >= 1) return value.toFixed(2);
  if (value >= 0.1) return value.toFixed(3);
  if (value >= 0.01) return value.toFixed(4);
  return value.toFixed(5);
};

// ========== 프로모드 색상 테마 ==========
const proThemeDark = {
  bg: '#0a0a0a',
  bgCard: '#111111',
  bgInput: '#1a1a1a',
  border: '#2a2a2a',
  text: '#e0e0e0',
  textDim: '#666666',
  neonGreen: '#00ff88',
  neonCyan: '#00f0ff',
  neonPurple: '#bf5fff',
  neonPink: '#ff0080',
  // 글로우 강화 (프로토타입 스타일)
  glow: '0 0 15px #00ff8866, 0 0 30px #00ff8833, 0 0 45px #00ff8811',
  glowCyan: '0 0 15px #00f0ff66, 0 0 30px #00f0ff33',
  glowPink: '0 0 15px #ff008066, 0 0 30px #ff008033',
  // 헤더 그라데이션 (프로토타입 스타일)
  headerGradient: 'linear-gradient(135deg, #ff006e, #8338ec)',
};

// 프로모드 라이트 = 흰색 게이밍 웨어 (흰 배경 + LED 백라이트)
const proThemeLight = {
  bg: '#f5f5f7',
  bgCard: '#ffffff',
  bgInput: '#f0f0f2',
  border: '#e0e0e5',
  text: '#1a1a1a',
  textDim: '#666666',
  neonGreen: '#00cc6a',
  neonCyan: '#00b8d4',
  neonPurple: '#9c4dff',
  neonPink: '#e6006a',
  // 글로우 강화 (라이트 버전)
  glow: '0 0 12px #00cc6a55, 0 0 25px #00cc6a33, 0 2px 8px rgba(0,0,0,0.1)',
  glowCyan: '0 0 12px #00b8d455, 0 0 25px #00b8d433',
  glowPink: '0 0 12px #e6006a55, 0 0 25px #e6006a33',
  // 헤더 그라데이션 (라이트 버전)
  headerGradient: 'linear-gradient(135deg, #667eea, #764ba2)',
};

// 기본모드 다크 테마 - 진회색 사무용 키보드 (모노톤 베이스 + 밝은 LED)
const basicThemeDark = {
  bg: '#1a1a1a',           // 검정 키보드 베이스 (이전 유지)
  bgCard: '#2d2d2d',       // 키캡 (이전 유지)
  bgInput: '#252525',      // 입력창 (이전 유지)
  border: '#404040',       // 키캡 테두리 (이전 유지)
  text: '#e0e0e0',         // 흰 각인 (이전 유지)
  textDim: '#888888',      // 흐린 각인 (이전 유지)
  accent: '#60a5fa',       // 파란 LED (밝게)
  accentLight: '#1e3a5f',  // 블루 배경
  success: '#4ade80',      // 초록 LED (밝게)
  warning: '#fbbf24',      // 노랑 LED (밝게)
  danger: '#f87171',       // 빨강 LED (밝게)
  // 헤더 그라데이션 (차분한 블루)
  headerGradient: 'linear-gradient(135deg, #374151, #1f2937)',
};

// 기본모드 라이트 테마 - 웜그레이 + 미니멀 (은근한 90년대)
const basicThemeLight = {
  bg: '#f5f5f4',           // 스톤 화이트 (무인양품)
  bgCard: '#fafaf9',       // 거의 흰색 (깨끗)
  bgInput: '#ffffff',      // 순백 입력창
  border: '#d6d3d1',       // 웜그레이 테두리
  text: '#292524',         // 스톤 블랙
  textDim: '#78716c',      // 웜그레이 보조
  accent: '#6366f1',       // 인디고 (세련된 포인트)
  accentLight: '#e0e7ff',  // 연한 인디고 배경
  success: '#22c55e',      // 초록
  warning: '#eab308',      // 노랑
  danger: '#ef4444',       // 빨강
  // 헤더 그라데이션 (차분한 인디고)
  headerGradient: 'linear-gradient(135deg, #6366f1, #8b5cf6)',
};

export default function GachaCalculator() {
  // ========== 기본 모드 State ==========
  const [rate, setRate] = useState(1);
  const [pity, setPity] = useState(100);
  const [pricePerPull, setPricePerPull] = useState(2000);
  const [currentPulls, setCurrentPulls] = useState(0);
  const [pityType, setPityType] = useState('grade');
  const [charactersInGrade, setCharactersInGrade] = useState(22);
  const [plannedPulls, setPlannedPulls] = useState(100);
  const [noPity, setNoPity] = useState(false);
  const [shareStatus, setShareStatus] = useState('');
  
  // ========== 프로모드 State ==========
  const [proMode, setProMode] = useState(false);
  const [softPityStart, setSoftPityStart] = useState(0); // 0 = 소프트피티 없음
  const [softPityIncrease, setSoftPityIncrease] = useState(6); // 뽑당 증가 %
  const [pickupRate, setPickupRate] = useState(100); // 당첨 시 픽업 확률 (100% = 확정, 50% = 50/50)
  const [guaranteeOnFail, setGuaranteeOnFail] = useState(true); // true = 실패시 확정 (50/50식), false = 매번 독립 (등급보장식)
  const [targetCopies, setTargetCopies] = useState(1);
  const [currentGuarantee, setCurrentGuarantee] = useState(false); // true = 다음 당첨 시 픽업 확정
  
  // ========== UI State ==========
  const [showSettings, setShowSettings] = useState(false);
  const [showHelp, setShowHelp] = useState(null); // 'softPity' | 'pickup' | 'guarantee' 등
  const [darkMode, setDarkMode] = useState(false); // 다크모드 토글 (dark_mode)
  const [showResetConfirm, setShowResetConfirm] = useState(false); // 초기화 확인 모달 (reset_confirm)
  
  // 확률 데이터
  const [probabilityData, setProbabilityData] = useState(fallbackProbabilityData);
  const [dataSource, setDataSource] = useState('local');
  
  // ========== localStorage 분리 저장 시스템 ==========
  const STORAGE_KEY_OLD = 'gachaCalc_settings'; // 구버전 키 (마이그레이션용)
  const STORAGE_KEY_COMMON = 'gachaCalc_common'; // 공통 (proMode, darkMode)
  const STORAGE_KEY_BASIC = 'gachaCalc_basic'; // 기본모드 데이터
  const STORAGE_KEY_PRO = 'gachaCalc_pro'; // 프로모드 데이터
  
  const isLoaded = useRef(false); // 초기 로딩 완료 플래그 (로딩 중 저장 방지)
  
  // 현재 모드 데이터를 객체로 반환
  const getCurrentModeData = () => ({
    rate, pity, noPity, pricePerPull, plannedPulls, currentPulls,
    // Basic 전용
    pityType, charactersInGrade,
    // Pro 전용
    softPityStart, softPityIncrease, pickupRate, guaranteeOnFail, targetCopies, currentGuarantee
  });
  
  // 데이터를 State에 적용
  const applyModeData = (data) => {
    if (!data) return;
    if (data.rate !== undefined) setRate(data.rate);
    if (data.pity !== undefined) setPity(data.pity);
    if (data.noPity !== undefined) setNoPity(data.noPity);
    if (data.pricePerPull !== undefined) setPricePerPull(data.pricePerPull);
    if (data.plannedPulls !== undefined) setPlannedPulls(data.plannedPulls);
    if (data.currentPulls !== undefined) setCurrentPulls(data.currentPulls);
    // Basic
    if (data.pityType !== undefined) setPityType(data.pityType);
    if (data.charactersInGrade !== undefined) setCharactersInGrade(data.charactersInGrade);
    // Pro
    if (data.softPityStart !== undefined) setSoftPityStart(data.softPityStart);
    if (data.softPityIncrease !== undefined) setSoftPityIncrease(data.softPityIncrease);
    if (data.pickupRate !== undefined) setPickupRate(data.pickupRate);
    if (data.guaranteeOnFail !== undefined) setGuaranteeOnFail(data.guaranteeOnFail);
    if (data.targetCopies !== undefined) setTargetCopies(data.targetCopies);
    if (data.currentGuarantee !== undefined) setCurrentGuarantee(data.currentGuarantee);
  };
  
  // 모드 전환 핸들러 (현재 저장 → 모드 전환 → 새 모드 로드)
  const toggleMode = (targetProMode) => {
    if (!isLoaded.current) return;
    
    // 1. 현재 모드 데이터 저장
    try {
      const currentKey = proMode ? STORAGE_KEY_PRO : STORAGE_KEY_BASIC;
      localStorage.setItem(currentKey, JSON.stringify(getCurrentModeData()));
    } catch (e) {
      console.warn('Failed to save current mode data:', e);
    }
    
    // 2. 모드 전환
    setProMode(targetProMode);
    
    // 3. 새 모드 데이터 로드
    const targetKey = targetProMode ? STORAGE_KEY_PRO : STORAGE_KEY_BASIC;
    try {
      const savedData = localStorage.getItem(targetKey);
      if (savedData) {
        applyModeData(JSON.parse(savedData));
      }
    } catch (e) {
      console.warn('Failed to load mode data:', e);
    }
  };
  
  // 앱 시작시: 마이그레이션 + 설정 로드
  useEffect(() => {
    try {
      // 1. 마이그레이션: 구버전 데이터가 있으면 Basic/Pro 양쪽에 복사 후 삭제
      const oldDataStr = localStorage.getItem(STORAGE_KEY_OLD);
      if (oldDataStr) {
        const oldData = JSON.parse(oldDataStr);
        localStorage.setItem(STORAGE_KEY_BASIC, JSON.stringify(oldData));
        localStorage.setItem(STORAGE_KEY_PRO, JSON.stringify(oldData));
        // 공통 설정 분리 저장
        localStorage.setItem(STORAGE_KEY_COMMON, JSON.stringify({
          proMode: oldData.proMode || false,
          darkMode: oldData.darkMode || false
        }));
        localStorage.removeItem(STORAGE_KEY_OLD);
        console.log('Migration completed: Separated Basic/Pro storage.');
      }
      
      // 2. 공통 설정 로드 (proMode, darkMode)
      let initialProMode = false;
      const commonStr = localStorage.getItem(STORAGE_KEY_COMMON);
      if (commonStr) {
        const commonData = JSON.parse(commonStr);
        if (commonData.darkMode !== undefined) setDarkMode(commonData.darkMode);
        if (commonData.proMode !== undefined) {
          setProMode(commonData.proMode);
          initialProMode = commonData.proMode;
        }
      } else {
        // 첫 구동: 시스템 다크모드 따라가기
        const systemDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
        setDarkMode(systemDark);
      }
      
      // 3. 현재 모드 데이터 로드
      const targetKey = initialProMode ? STORAGE_KEY_PRO : STORAGE_KEY_BASIC;
      const modeStr = localStorage.getItem(targetKey);
      if (modeStr) {
        applyModeData(JSON.parse(modeStr));
      }
      
      isLoaded.current = true; // 로드 완료
    } catch (e) {
      console.warn('Failed to load settings:', e);
      isLoaded.current = true;
    }
  }, []);
  
  // 공통 설정 자동 저장 (proMode, darkMode)
  useEffect(() => {
    if (!isLoaded.current) return;
    try {
      localStorage.setItem(STORAGE_KEY_COMMON, JSON.stringify({ proMode, darkMode }));
    } catch (e) {
      console.warn('Failed to save common settings:', e);
    }
  }, [proMode, darkMode]);
  
  // 현재 모드 데이터 자동 저장
  useEffect(() => {
    if (!isLoaded.current) return;
    try {
      const currentKey = proMode ? STORAGE_KEY_PRO : STORAGE_KEY_BASIC;
      localStorage.setItem(currentKey, JSON.stringify(getCurrentModeData()));
    } catch (e) {
      console.warn('Failed to save mode settings:', e);
    }
  }, [rate, pity, noPity, pricePerPull, plannedPulls, currentPulls, pityType, charactersInGrade, softPityStart, softPityIncrease, pickupRate, guaranteeOnFail, targetCopies, currentGuarantee, proMode]);
  
  // 초기화 함수 (현재 모드만 초기화)
  const confirmReset = () => {
    setShowResetConfirm(true);
  };
  
  const executeReset = () => {
    // 공통 초기화
    setRate(1);
    setPity(100);
    setPricePerPull(2000);
    setCurrentPulls(0);
    setPlannedPulls(100);
    setNoPity(false);
    
    if (proMode) {
      // Pro 전용 초기화
      setSoftPityStart(0);
      setSoftPityIncrease(6);
      setPickupRate(100);
      setGuaranteeOnFail(true);
      setTargetCopies(1);
      setCurrentGuarantee(false);
    } else {
      // Basic 전용 초기화
      setPityType('grade');
      setCharactersInGrade(22);
    }
    
    setShowResetConfirm(false);
  };
  
  // 버그 제보용 로그 생성 및 복사
  const copyDebugLog = async () => {
    const debugData = {
      version: APP_VERSION,
      timestamp: new Date().toISOString(),
      
      // 기기 정보
      device: {
        userAgent: navigator.userAgent,
        platform: navigator.platform,
        language: navigator.language,
        screenSize: `${window.screen.width}x${window.screen.height}`,
        windowSize: `${window.innerWidth}x${window.innerHeight}`,
        pixelRatio: window.devicePixelRatio,
        darkMode: darkMode,
      },
      
      // 현재 모드
      mode: proMode ? 'PRO' : 'BASIC',
      
      // 사용자 설정값 (전체)
      settings: {
        // 공통
        rate,
        pity,
        noPity,
        pricePerPull,
        plannedPulls,
        currentPulls,
        
        // 기본모드 전용
        pityType,
        charactersInGrade,
        
        // 프로모드 전용
        softPityStart,
        softPityIncrease,
        pickupRate,
        guaranteeOnFail,
        targetCopies,
        currentGuarantee,
      },
      
      // 계산 결과
      result: proMode && proResult ? {
        mean: proResult.mean,
        stdDev: proResult.stdDev,
        p50: proResult.p50,
        p90: proResult.p90,
        p99: proResult.p99,
        plannedSuccessRate: proResult.plannedSuccessRate
      } : {
        median: result.median,
        p90: result.p90,
        p99: result.p99,
        expected: result.expected,
        plannedSuccessRate: result.plannedSuccessRate
      },
    };
    
    const logText = `[가챠계산기 버그리포트]\n${JSON.stringify(debugData, null, 2)}`;
    
    try {
      await navigator.clipboard.writeText(logText);
      alert('디버그 정보가 복사되었습니다.\n\n버그 제보 시 이 정보를 함께 붙여넣기 해주세요.');
    } catch (e) {
      // 클립보드 실패 시 텍스트 선택 가능하게
      prompt('아래 정보를 복사해서 버그 제보에 포함해주세요:', logText);
    }
  };
  
  // 앱 정보 (app_info)
  const APP_VERSION = 'v1.1.0';
  const CONTACT_EMAIL = 'mirrorlab.dev@gmail.com';
  const CONTACT_FORM_URL = 'https://forms.gle/qrRDSS5pUyp42jE97';
  const PRIVACY_POLICY_URL = 'https://gist.github.com/mirrorlabdev/f84328d6cf7a3ec0e70f4c43b050c744';
  
  // 현재 테마 선택
  const proTheme = darkMode ? proThemeDark : proThemeLight;
  const basicTheme = darkMode ? basicThemeDark : basicThemeLight;
  
  // 서버 데이터 로드 (probability_data_loader)
  useEffect(() => {
    const CACHE_KEY = 'gachaCalc_probabilityData';
    const CACHE_VERSION_KEY = 'gachaCalc_dataVersion';
    
    let loadedFromCache = false;
    
    try {
      const cached = localStorage.getItem(CACHE_KEY);
      if (cached) {
        const parsed = JSON.parse(cached);
        if (Array.isArray(parsed) && parsed.length > 0) {
          setProbabilityData(parsed.sort((a, b) => a.rate - b.rate));
          loadedFromCache = true;
        }
      }
    } catch (e) {
      console.warn('Failed to load cached probability data:', e);
    }
    
    // 클로저 버그 방지: 플래그로 상태 결정
    setDataSource(loadedFromCache ? 'cached' : 'local');
    
    if (!PROBABILITY_DATA_URL) return;
    
    // TODO: 서버 fetch 로직 (현재 미사용)
  }, []);

  // ========== 프로모드 계산 (정확 DP, accurate_dp_calculation) ==========
  const proResult = useMemo(() => {
    try {
      if (!proMode) return null;
      
      const baseRate = rate / 100;
      if (baseRate <= 0 || baseRate > 1) return null;
      
      const hasPity = !noPity && pity > 0;
      const hasSoftPity = softPityStart > 0 && (!hasPity || softPityStart < pity);
      const softPityRate = softPityIncrease / 100;
      const winRate = pickupRate / 100;
      
      // 스택 기반 확률 함수 (get_rate_at_stack)
      const getRateAtStack = (stackCount) => {
        if (!hasSoftPity || stackCount < softPityStart) return baseRate;
      const softPulls = stackCount - softPityStart + 1;
      return Math.min(1, baseRate + softPityRate * softPulls);
    };
    
    // ========== 헬퍼: 1카피 픽업 분포 계산 (calculate_single_pickup_dist) ==========
    // startPity: 시작 천장 스택 (0 ~ pity-1)
    // startGuarantee: 시작 시 확정권 보유 여부
    const calculateSinglePickupDist = (startPity, startGuarantee) => {
      const remainingToPity = hasPity ? pity - startPity : Infinity;
      const EPS = 1e-12;
      const HARD_CAP = 50000; // 안전 상한
      const maxPulls = hasPity ? remainingToPity : HARD_CAP;
      
      // 최고등급 당첨 분포 (hit_distribution)
      const hitDist = new Array(Math.min(maxPulls + 1, HARD_CAP + 1)).fill(0);
      let survival = 1;
      let actualMax = maxPulls;
      
      for (let k = 1; k <= maxPulls && k < hitDist.length; k++) {
        const stack = startPity + k;
        const pullRate = getRateAtStack(stack);
        
        if (hasPity && k === remainingToPity) {
          hitDist[k] = survival;
          survival = 0;
          actualMax = k;
          break;
        } else {
          hitDist[k] = survival * pullRate;
          survival *= (1 - pullRate);
          
          // 천장 없을 때: survival이 충분히 작으면 조기 종료
          if (!hasPity && survival < EPS) {
            actualMax = k;
            break;
          }
        }
      }
      
      // winRate = 1이면 당첨 = 픽업
      if (winRate >= 1) return hitDist;
      
      // ========== 독립 모드 (independent_mode) ==========
      // 등급보장 스타일: 최고등급 당첨 시 천장 리셋, 픽업은 별도 확률
      if (!guaranteeOnFail) {
        const effectiveRate = baseRate * winRate;
        const SAFE_MAX = 20000;
        const maxIndie = Math.min(SAFE_MAX, hasPity ? Math.ceil(pity / winRate) * 3 : Math.ceil(20 / effectiveRate));
        
        const result = new Array(maxIndie + 1).fill(0);
        
        // State-based DP: survival[pityCount] = 해당 천장에서 아직 픽업 못 얻은 확률
        const effectivePity = hasPity ? pity : Math.ceil(15 / baseRate); // 천장 없으면 99.97% 커버
        let survival = new Array(effectivePity + 1).fill(0);
        survival[startPity] = 1; // 시작 천장에서 시작
        
        for (let k = 1; k <= maxIndie; k++) {
          const newSurvival = new Array(effectivePity + 1).fill(0);
          
          for (let i = 0; i < effectivePity; i++) {
            if (survival[i] < 1e-12) continue;
            
            const pullRate = getRateAtStack(i + 1);
            const actualPullRate = (hasPity && i + 1 >= pity) ? 1 : pullRate;
            
            // 당첨 + 픽업 성공 → 완료!
            result[k] += survival[i] * actualPullRate * winRate;
            
            // 당첨 + 픽업 실패 → 천장 0으로 리셋 (reset_on_miss_pickup)
            newSurvival[0] += survival[i] * actualPullRate * (1 - winRate);
            
            // 미당첨 → 천장 +1
            if (actualPullRate < 1 && i + 1 < effectivePity) {
              newSurvival[i + 1] += survival[i] * (1 - actualPullRate);
            }
          }
          
          survival = newSurvival;
          const totalSurv = survival.reduce((a, b) => a + b, 0);
          if (totalSurv < 1e-12) break;
        }
        
        return result;
      }
      
      // ========== 50/50 모드 (fifty_fifty_mode) ==========
      const freshMaxPulls = hasPity ? pity : Math.min(2000, Math.ceil(10 / baseRate));
      const safeSize = hasPity ? pity * 3 : 5000;
      const result = new Array(safeSize + 1).fill(0);
      
      if (startGuarantee) {
        // 확정권 보유 -> 첫 당첨이 픽업 (guaranteed_first_hit)
        for (let k = 1; k < hitDist.length; k++) {
          if (k < result.length) result[k] = hitDist[k];
        }
      } else {
        // 확정권 없음 -> 50/50 (no_guarantee_fifty_fifty)
        
        // 1. 바로 성공 (direct_success)
        for (let k = 1; k < hitDist.length; k++) {
          if (k < result.length) result[k] += hitDist[k] * winRate;
        }
        
        // 2. 실패 후 확정 (fail_then_guarantee)
        // 실패하면 천장 0, 확정권 true로 리셋
        const freshDist = new Array(freshMaxPulls + 1).fill(0);
        let freshSurv = 1;
        for (let k = 1; k <= freshMaxPulls; k++) {
          const pullRate = getRateAtStack(k); // 0부터 시작
          if (hasPity && k === pity) {
            freshDist[k] = freshSurv;
            freshSurv = 0;
          } else {
            freshDist[k] = freshSurv * pullRate;
            freshSurv *= (1 - pullRate);
          }
        }
        
        // Convolution: 첫 실패 * 두번째 확정
        for (let first = 1; first < hitDist.length; first++) {
          const failProb = hitDist[first] * (1 - winRate);
          if (failProb < 1e-12) continue;
          for (let second = 1; second < freshDist.length; second++) {
            if (first + second < result.length) {
              result[first + second] += failProb * freshDist[second];
            }
          }
        }
      }
      
      return result;
    };
    
    // ========== 현재 상태 (current_state) ==========
    const currentPity = hasPity ? (currentPulls % pity) : currentPulls;
    const completedCycles = hasPity ? Math.floor(currentPulls / pity) : 0;
    
    // ========== 첫 카피 분포 (first_copy_dist) ==========
    const firstCopyDist = calculateSinglePickupDist(currentPity, currentGuarantee);
    
    // ========== N카피 분포 (multi_copy_dist) ==========
    let multiCopyDist;
    const SAFE_MAX_TOTAL = 50000;
    
    if (targetCopies === 1) {
      multiCopyDist = firstCopyDist;
    } else {
      // [핵심 수정] 2카피부터는 0, false로 시작하는 분포 사용!
      // 픽업 획득 후에는 항상 천장=0, 확정권=false이기 때문
      const freshCopyDist = calculateSinglePickupDist(0, false);
      
      // 첫 카피 분포로 시작
      multiCopyDist = firstCopyDist.slice();
      
      // 나머지 (targetCopies - 1) 카피 convolution
      for (let copy = 1; copy < targetCopies; copy++) {
        const newDist = new Array(Math.min(SAFE_MAX_TOTAL, multiCopyDist.length + freshCopyDist.length)).fill(0);
        for (let i = 0; i < multiCopyDist.length; i++) {
          if (multiCopyDist[i] < 1e-12) continue;
          for (let j = 1; j < freshCopyDist.length; j++) {
            if (freshCopyDist[j] < 1e-12) continue;
            if (i + j < newDist.length) {
              newDist[i + j] += multiCopyDist[i] * freshCopyDist[j];
            }
          }
        }
        multiCopyDist = newDist;
      }
    }

    // ========== 분포 정규화 (normalization) ==========
    // 천장 있을 때만 정규화 (천장 없으면 꼬리 확률 보존)
    const sumProb = multiCopyDist.reduce((a, b) => a + b, 0);
    if (hasPity && sumProb > 0 && Math.abs(sumProb - 1) > 1e-8) {
      multiCopyDist = multiCopyDist.map(p => p / sumProb);
    }

    // ========== 통계 계산 (statistics_calculation) ==========
    const cdf = new Array(multiCopyDist.length).fill(0);
    cdf[0] = multiCopyDist[0];
    for (let i = 1; i < multiCopyDist.length; i++) {
      cdf[i] = cdf[i - 1] + multiCopyDist[i];
    }

    const findPercentile = (p) => {
      for (let i = 0; i < cdf.length; i++) {
        if (cdf[i] >= p) return i;
      }
      return cdf.length - 1;
    };

    let mean = 0;
    for (let i = 1; i < multiCopyDist.length; i++) {
      mean += i * multiCopyDist[i];
    }

    let variance = 0;
    for (let i = 1; i < multiCopyDist.length; i++) {
      variance += multiCopyDist[i] * Math.pow(i - mean, 2);
    }
    const stdDev = Math.sqrt(variance);

    const p10 = findPercentile(0.1);
    const p25 = findPercentile(0.25);
    const p50 = findPercentile(0.5);
    const p75 = findPercentile(0.75);
    const p90 = findPercentile(0.9);
    const p95 = findPercentile(0.95);
    const p99 = findPercentile(0.99);

    let min = 1, max = multiCopyDist.length - 1;
    for (let i = 1; i < multiCopyDist.length; i++) {
      if (multiCopyDist[i] > 0.0001) { min = i; break; }
    }
    for (let i = multiCopyDist.length - 1; i >= 1; i--) {
      if (multiCopyDist[i] > 0.0001) { max = i; break; }
    }

    // ========== 히스토그램 데이터 (histogram_data) ==========
    const binCount = 30;
    const range = max - min + 1;
    const binSize = Math.max(1, Math.ceil(range / binCount));
    const histogram = [];

    for (let i = 0; i < binCount; i++) {
      const binStart = min + i * binSize;
      const binEnd = Math.min(binStart + binSize, max + 1);
      let binProb = 0;
      for (let k = binStart; k < binEnd && k < multiCopyDist.length; k++) {
        binProb += multiCopyDist[k];
      }
      histogram.push({
        start: binStart,
        end: binEnd,
        percent: binProb * 100
      });
    }

    // N뽑 성공확률 (planned_success_rate)
    const safeIndex = Math.floor(plannedPulls);
    const plannedSuccessRate = (safeIndex < cdf.length ? cdf[safeIndex] : 1) * 100;

    return {
      mean: mean.toFixed(1),
      stdDev: stdDev.toFixed(1),
      min, max,
      p10, p25, p50, p75, p90, p95, p99,
      histogram,
      plannedSuccessRate,
      costs: {
        mean: Math.round(mean * pricePerPull),
        p50: p50 * pricePerPull,
        p90: p90 * pricePerPull,
        p99: p99 * pricePerPull,
      },
      targetCopies,
    };
    } catch (error) {
      console.error('proResult 계산 오류:', error);
      return null;
    }
  }, [proMode, rate, pity, noPity, softPityStart, softPityIncrease, pickupRate, guaranteeOnFail, targetCopies, plannedPulls, pricePerPull, currentPulls, currentGuarantee]);

  // ========== 기본 모드 계산 ==========
  const defaultResult = {
    median: 0, p90: 0, p99: 0, expected: 0,
    costs: { median: 0, p90: 0, p99: 0 },
    chickens: { median: 0, p90: 0, p99: 0 },
    effectiveRatePercent: 0,
    plannedSuccessRate: 0,
    cycleSuccessRate: 0,
    remainingPity: null,
    completedCycles: 0,
    hasPity: false
  };

  const result = useMemo(() => {
    const gradeRate = rate / 100;
    if (gradeRate <= 0 || gradeRate > 1) return defaultResult;
    if (plannedPulls < 1) return defaultResult;
    if (pricePerPull < 0) return defaultResult;
    
    const hasPity = !noPity && pity > 0;
    const validCurrentPulls = hasPity ? (currentPulls % pity) : 0;
    const remainingPity = hasPity ? (pity - validCurrentPulls) : Infinity;
    const completedCycles = hasPity ? Math.floor(currentPulls / pity) : 0;

    if (pityType === 'pickup') {
      const effectiveRate = gradeRate;
      
      const getSuccessRate = (n) => {
        if (hasPity && n >= remainingPity) return 1;
        return 1 - Math.pow(1 - effectiveRate, n);
      };

      const findPullsForProb = (targetProb) => {
        if (effectiveRate >= 1) return 1;
        const pullsNeeded = Math.ceil(Math.log(1 - targetProb) / Math.log(1 - effectiveRate));
        if (hasPity && pullsNeeded > remainingPity) return remainingPity;
        return pullsNeeded;
      };

      const expected = hasPity ? Math.min(1 / effectiveRate, remainingPity) : 1 / effectiveRate;
      const median = findPullsForProb(0.5);
      const p90 = findPullsForProb(0.9);
      const p99 = findPullsForProb(0.99);
      const plannedSuccessRate = getSuccessRate(plannedPulls) * 100;

      const costs = {
        median: median * pricePerPull,
        p90: p90 * pricePerPull,
        p99: p99 * pricePerPull
      };

      const chickens = {
        median: (costs.median / 20000).toFixed(1),
        p90: (costs.p90 / 20000).toFixed(1),
        p99: (costs.p99 / 20000).toFixed(1)
      };

      return { 
        median, p90, p99, 
        expected: expected.toFixed(1), 
        costs, chickens, 
        effectiveRatePercent: (effectiveRate * 100).toFixed(4),
        plannedSuccessRate,
        remainingPity: hasPity ? remainingPity : null,
        completedCycles,
        hasPity
      };
    } else {
      if (charactersInGrade < 1) return defaultResult;

      const charRate = 1 / charactersInGrade;
      const specificCharRate = gradeRate * charRate;
      
      if (!hasPity) {
        const getSuccessRate = (n) => 1 - Math.pow(1 - specificCharRate, n);
        
        const findPullsForProb = (targetProb) => {
          if (specificCharRate >= 1) return 1;
          return Math.ceil(Math.log(1 - targetProb) / Math.log(1 - specificCharRate));
        };
        
        const median = findPullsForProb(0.5);
        const p90 = findPullsForProb(0.9);
        const p99 = findPullsForProb(0.99);
        const expected = 1 / specificCharRate;
        const plannedSuccessRate = getSuccessRate(plannedPulls) * 100;
        
        const costs = {
          median: median * pricePerPull,
          p90: p90 * pricePerPull,
          p99: p99 * pricePerPull
        };
        
        const chickens = {
          median: (costs.median / 20000).toFixed(1),
          p90: (costs.p90 / 20000).toFixed(1),
          p99: (costs.p99 / 20000).toFixed(1)
        };
        
        return {
          median, p90, p99,
          expected: expected.toFixed(1),
          costs, chickens,
          effectiveRatePercent: (specificCharRate * 100).toFixed(4),
          plannedSuccessRate,
          remainingPity: null,
          completedCycles: 0,
          hasPity: false
        };
      }
      
      const failFirstCycle = Math.pow(1 - specificCharRate, remainingPity - 1) * (1 - charRate);
      const successFirstCycle = 1 - failFirstCycle;
      const failNormalCycle = Math.pow(1 - specificCharRate, pity - 1) * (1 - charRate);
      const successNormalCycle = 1 - failNormalCycle;

      const getSuccessRateByPulls = (n) => {
        if (n <= 0) return 0;
        
        if (n <= remainingPity) {
          if (n < remainingPity) {
            return 1 - Math.pow(1 - specificCharRate, n);
          } else {
            return successFirstCycle;
          }
        }
        
        const pullsAfterFirst = n - remainingPity;
        const fullCyclesAfterFirst = Math.floor(pullsAfterFirst / pity);
        const remainingInCycle = pullsAfterFirst % pity;
        
        let failProb = failFirstCycle;
        failProb *= Math.pow(failNormalCycle, fullCyclesAfterFirst);
        
        if (remainingInCycle > 0) {
          failProb *= Math.pow(1 - specificCharRate, remainingInCycle);
        }
        
        return 1 - failProb;
      };

      const findPullsForProb = (targetProb) => {
        const maxPulls = pity * 100;
        for (let n = 1; n <= maxPulls; n++) {
          if (getSuccessRateByPulls(n) >= targetProb) return n;
        }
        return maxPulls;
      };

      const median = findPullsForProb(0.5);
      const p90 = findPullsForProb(0.9);
      const p99 = findPullsForProb(0.99);

      const expectedCycles = 1 / successNormalCycle;
      const expectedPulls = remainingPity + (expectedCycles - 1) * pity;
      const plannedSuccessRate = getSuccessRateByPulls(plannedPulls) * 100;

      const costs = {
        median: median * pricePerPull,
        p90: p90 * pricePerPull,
        p99: p99 * pricePerPull
      };

      const chickens = {
        median: (costs.median / 20000).toFixed(1),
        p90: (costs.p90 / 20000).toFixed(1),
        p99: (costs.p99 / 20000).toFixed(1)
      };

      return { 
        median, p90, p99, 
        expected: expectedPulls.toFixed(1), 
        costs, chickens, 
        effectiveRatePercent: (specificCharRate * 100).toFixed(4),
        cycleSuccessRate: (successNormalCycle * 100).toFixed(2),
        firstCycleSuccessRate: (successFirstCycle * 100).toFixed(2),
        plannedSuccessRate,
        remainingPity,
        completedCycles,
        hasPity: true
      };
    }
  }, [rate, pity, pricePerPull, currentPulls, pityType, charactersInGrade, plannedPulls, noPity]);

  const feelingData = useMemo(() => {
    try {
      const successRate = proMode && proResult && typeof proResult.plannedSuccessRate === 'number'
        ? proResult.plannedSuccessRate 
        : result.plannedSuccessRate;
      if (!successRate || successRate <= 0) return null;
      return findClosestProbability(successRate, probabilityData);
    } catch (error) {
      console.warn('feelingData 계산 오류:', error);
      return null;
    }
  }, [proMode, proResult, result.plannedSuccessRate, probabilityData]);

  // 공유 기능 (share_handler)
  const handleShare = async () => {
    try {
      const successRate = proMode && proResult && typeof proResult.plannedSuccessRate === 'number'
        ? proResult.plannedSuccessRate 
        : (result.plannedSuccessRate || 0);
      
      const shareText = proMode && proResult
        ? `🎰 가챠 계산기 PRO\n\n` +
          `📊 ${targetCopies}장 목표\n` +
          `확률: ${rate}% | 천장: ${noPity ? '없음' : pity + '뽑'}\n` +
          `${softPityStart > 0 ? `소프트 천장: ${softPityStart}뽑부터 +${softPityIncrease}%\n` : ''}` +
          `${pickupRate < 100 ? `픽업확률: ${pickupRate}% (${guaranteeOnFail ? '실패시확정' : '매번독립'})\n` : ''}` +
          `\n📈 결과\n` +
          `기대값: ${proResult.mean || 0}뽑 (±${proResult.stdDev || 0})\n` +
          `중앙값: ${proResult.p50 || 0}뽑 | 상위10%: ${proResult.p90 || 0}뽑\n` +
          `${plannedPulls}뽑 성공률: ${formatPercent(successRate)}%`
        : `🎰 가챠 계산기\n\n` +
          `${plannedPulls}뽑 했을 때 성공확률: ${formatPercent(successRate)}%\n` +
          `예상 비용: ${(plannedPulls * pricePerPull).toLocaleString()}원\n\n` +
          `50% 확률: ${result.median || 0}뽑\n` +
          `90% 확률: ${result.p90 || 0}뽑\n` +
          `99% 확률: ${result.p99 || 0}뽑`;

      if (navigator.share) {
        try {
          await navigator.share({ title: '가챠 계산기', text: shareText });
          setShareStatus('공유 완료!');
        } catch (e) {
          if (e.name !== 'AbortError') {
            await navigator.clipboard.writeText(shareText);
            setShareStatus('클립보드에 복사됨!');
          }
        }
      } else {
        await navigator.clipboard.writeText(shareText);
        setShareStatus('클립보드에 복사됨!');
      }
    } catch (error) {
      console.error('공유 오류:', error);
      setShareStatus('공유 중 오류 발생');
    }
    setTimeout(() => setShareStatus(''), 2000);
  };

  // ========== 설정 모달 컴포넌트 ==========
  const SettingsModal = () => {
    if (!showSettings) return null;
    
    const theme = darkMode ? {
      bg: 'rgba(0,0,0,0.9)',
      card: '#1e1e1e',
      text: '#e0e0e0',
      textDim: '#999',
      border: '#333',
      accent: '#8b5cf6'
    } : {
      bg: 'rgba(0,0,0,0.5)',
      card: 'white',
      text: '#333',
      textDim: '#666',
      border: '#e2e8f0',
      accent: '#8b5cf6'
    };
    
    return (
      <div style={{
        position: 'fixed',
        top: 0, left: 0, right: 0, bottom: 0,
        backgroundColor: theme.bg,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 1000,
        padding: '20px'
      }} onClick={() => setShowSettings(false)}>
        <div style={{
          backgroundColor: theme.card,
          borderRadius: '12px',
          padding: '24px',
          maxWidth: '360px',
          width: '100%',
          maxHeight: '80vh',
          overflowY: 'auto',
          border: `1px solid ${theme.border}`
        }} onClick={e => e.stopPropagation()}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
            <h3 style={{ margin: 0, color: theme.text }}>⚙️ 설정</h3>
            <span style={{ color: theme.textDim, fontSize: '12px' }}>{APP_VERSION}</span>
          </div>
          
          {/* 메뉴 항목들 */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            {/* 문의하기 - 구글 폼 */}
            <a
              href={CONTACT_FORM_URL}
              target="_blank"
              rel="noopener noreferrer"
              style={{
                padding: '12px 16px',
                backgroundColor: 'transparent',
                border: `1px solid ${theme.border}`,
                borderRadius: '8px',
                color: theme.text,
                fontSize: '14px',
                textDecoration: 'none',
                display: 'flex',
                alignItems: 'center',
                gap: '10px'
              }}
            >
              ✉️ 문의하기
            </a>
            
            {/* 버그 제보 - 로그 복사 */}
            <button
              onClick={() => {
                copyDebugLog();
              }}
              style={{
                padding: '12px 16px',
                backgroundColor: 'transparent',
                border: `1px solid ${theme.border}`,
                borderRadius: '8px',
                color: theme.text,
                fontSize: '14px',
                cursor: 'pointer',
                textAlign: 'left',
                display: 'flex',
                alignItems: 'center',
                gap: '10px'
              }}
            >
              🐛 버그 제보용 로그 복사
            </button>
            
            {/* 구분선 */}
            <div style={{ borderTop: `1px solid ${theme.border}`, margin: '4px 0' }} />
            
            {/* 개인정보처리방침 */}
            <a
              href={PRIVACY_POLICY_URL}
              target="_blank"
              rel="noopener noreferrer"
              style={{
                padding: '12px 16px',
                backgroundColor: 'transparent',
                border: `1px solid ${theme.border}`,
                borderRadius: '8px',
                color: theme.textDim,
                fontSize: '14px',
                textDecoration: 'none',
                display: 'flex',
                alignItems: 'center',
                gap: '10px'
              }}
            >
              📋 개인정보처리방침
            </a>
            
            {/* 오픈소스 라이선스 */}
            <button
              onClick={() => alert('이 앱은 다음 오픈소스 라이브러리를 사용합니다:\n\n• React (MIT License)\n• 기타 의존성은 MIT 또는 Apache 2.0 라이선스를 따릅니다.')}
              style={{
                padding: '12px 16px',
                backgroundColor: 'transparent',
                border: `1px solid ${theme.border}`,
                borderRadius: '8px',
                color: theme.textDim,
                fontSize: '14px',
                cursor: 'pointer',
                textAlign: 'left',
                display: 'flex',
                alignItems: 'center',
                gap: '10px'
              }}
            >
              📄 오픈소스 라이선스
            </button>
          </div>
          
          {/* 닫기 버튼 */}
          <button
            onClick={() => setShowSettings(false)}
            style={{
              width: '100%',
              marginTop: '20px',
              padding: '12px',
              backgroundColor: theme.accent,
              border: 'none',
              borderRadius: '8px',
              color: 'white',
              fontSize: '14px',
              fontWeight: '600',
              cursor: 'pointer'
            }}
          >
            닫기
          </button>
        </div>
      </div>
    );
  };

  // ========== 초기화 확인 모달 (reset_confirm_modal) ==========
  const ResetConfirmModal = () => {
    if (!showResetConfirm) return null;
    
    const theme = darkMode ? {
      bg: 'rgba(0,0,0,0.9)',
      card: '#1e1e1e',
      text: '#e0e0e0',
      textDim: '#999',
      border: '#333',
      danger: '#ef4444',
      cancel: '#666'
    } : {
      bg: 'rgba(0,0,0,0.5)',
      card: 'white',
      text: '#333',
      textDim: '#666',
      border: '#e2e8f0',
      danger: '#ef4444',
      cancel: '#999'
    };
    
    return (
      <div style={{
        position: 'fixed',
        top: 0, left: 0, right: 0, bottom: 0,
        backgroundColor: theme.bg,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 1001,
        padding: '20px'
      }} onClick={() => setShowResetConfirm(false)}>
        <div style={{
          backgroundColor: theme.card,
          borderRadius: '12px',
          padding: '24px',
          maxWidth: '300px',
          width: '100%',
          textAlign: 'center',
          border: `1px solid ${theme.border}`
        }} onClick={e => e.stopPropagation()}>
          <div style={{ fontSize: '32px', marginBottom: '16px' }}>⚠️</div>
          <h3 style={{ margin: '0 0 8px 0', color: theme.text }}>초기화</h3>
          <p style={{ margin: '0 0 24px 0', color: theme.textDim, fontSize: '14px', lineHeight: '1.5' }}>
            모든 계산 설정값이 초기화됩니다.<br/>
            (모드/테마는 유지)
          </p>
          <div style={{ display: 'flex', gap: '12px' }}>
            <button
              onClick={() => setShowResetConfirm(false)}
              style={{
                flex: 1,
                padding: '12px',
                backgroundColor: 'transparent',
                border: `1px solid ${theme.border}`,
                borderRadius: '8px',
                color: theme.textDim,
                fontSize: '14px',
                cursor: 'pointer'
              }}
            >
              취소
            </button>
            <button
              onClick={executeReset}
              style={{
                flex: 1,
                padding: '12px',
                backgroundColor: theme.danger,
                border: 'none',
                borderRadius: '8px',
                color: 'white',
                fontSize: '14px',
                fontWeight: '600',
                cursor: 'pointer'
              }}
            >
              초기화
            </button>
          </div>
        </div>
      </div>
    );
  };
  
  // ========== 도움말 툴팁 컴포넌트 (help_tooltip) ==========
  const HelpTooltip = ({ id, children }) => (
    <span
      onClick={() => setShowHelp(showHelp === id ? null : id)}
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        width: '16px',
        height: '16px',
        borderRadius: '50%',
        backgroundColor: proMode ? proTheme.border : '#e2e8f0',
        color: proMode ? proTheme.textDim : '#666',
        fontSize: '10px',
        cursor: 'pointer',
        marginLeft: '4px'
      }}
    >
      ?
    </span>
  );
  
  const helpTexts = {
    softPity: '소프트 천장: 일정 뽑기 수 이후부터 매 뽑기마다 확률이 증가하는 시스템입니다. 예: 원신은 74뽑부터 매 뽑기당 +6%씩 증가합니다.',
    pickup: '픽업확률: 최고 등급 당첨 시 원하는 캐릭터가 나올 확률입니다. 50/50은 절반, 등급보장(22명 중 1명)은 약 4.55%입니다.',
    guarantee: '확정권: [실패시 확정]은 픽업 실패 시 다음 당첨은 100% 픽업 (원신 방식), [매번 독립]은 매번 같은 확률로 독립 시행 (등급보장 방식)입니다.',
    pity: '천장: 이 횟수만큼 뽑으면 무조건 최고등급이 나오는 시스템입니다. 0 또는 체크 해제 시 천장 없이 순수 확률로만 계산합니다.',
    copies: '목표장수: 캐릭터 돌파/완돌에 필요한 장수입니다. 게임마다 다릅니다. (예: 원신 완돌=7장, 운빨돌격대=10장)'
  };

  // ========== 프로모드 UI ==========
  if (proMode) {
    return (
      <div style={{ 
        maxWidth: '500px', 
        margin: '0 auto', 
        padding: '16px',
        backgroundColor: proTheme.bg,
        minHeight: '100vh',
        color: proTheme.text,
        fontFamily: "'JetBrains Mono', 'Fira Code', monospace"
      }}>
        {/* 설정 모달 */}
        <SettingsModal />
        
        {/* 초기화 확인 모달 */}
        <ResetConfirmModal />
        
        {/* 도움말 모달 */}
        {showHelp && (
          <div style={{
            position: 'fixed',
            top: 0, left: 0, right: 0, bottom: 0,
            backgroundColor: darkMode ? 'rgba(0,0,0,0.8)' : 'rgba(0,0,0,0.5)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 1001,
            padding: '20px'
          }} onClick={() => setShowHelp(null)}>
            <div style={{
              backgroundColor: proTheme.bgCard,
              borderRadius: '12px',
              padding: '20px',
              maxWidth: '320px',
              border: `1px solid ${proTheme.neonCyan}`
            }} onClick={e => e.stopPropagation()}>
              <p style={{ margin: 0, fontSize: '14px', lineHeight: '1.6', color: proTheme.text }}>
                {helpTexts[showHelp]}
              </p>
              <button
                onClick={() => setShowHelp(null)}
                style={{
                  width: '100%',
                  marginTop: '16px',
                  padding: '10px',
                  backgroundColor: proTheme.neonCyan,
                  border: 'none',
                  borderRadius: '6px',
                  color: darkMode ? 'black' : 'white',
                  fontSize: '13px',
                  fontWeight: '600',
                  cursor: 'pointer'
                }}
              >
                확인
              </button>
            </div>
          </div>
        )}
        {/* 헤더 */}
        <div style={{ 
          display: 'flex', 
          justifyContent: 'space-between', 
          alignItems: 'center',
          marginBottom: '20px',
          padding: '16px 20px',
          background: proTheme.headerGradient,
          borderRadius: '12px',
          border: `2px solid ${proTheme.neonGreen}`,
          boxShadow: proTheme.glow
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <span style={{ 
              color: proTheme.neonGreen, 
              fontSize: '20px',
              textShadow: `0 0 10px ${proTheme.neonGreen}`
            }}>▶</span>
            <span style={{ 
              fontWeight: 'bold', 
              letterSpacing: '2px',
              color: 'white',
              textShadow: '0 2px 4px rgba(0,0,0,0.3)'
            }}>가챠 분석기 PRO</span>
          </div>
          <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
            {/* 다크모드 토글 */}
            <button
              onClick={() => setDarkMode(!darkMode)}
              style={{
                padding: '6px 10px',
                backgroundColor: 'rgba(0,0,0,0.3)',
                border: `1px solid rgba(255,255,255,0.3)`,
                borderRadius: '4px',
                color: 'white',
                fontSize: '14px',
                cursor: 'pointer',
                fontFamily: 'inherit'
              }}
              title={darkMode ? '라이트 모드로 전환' : '다크 모드로 전환'}
            >
              {darkMode ? '☀️' : '🌙'}
            </button>
            <button
              onClick={() => setShowSettings(true)}
              style={{
                padding: '6px 10px',
                backgroundColor: 'rgba(0,0,0,0.3)',
                border: `1px solid rgba(255,255,255,0.3)`,
                borderRadius: '4px',
                color: 'white',
                fontSize: '12px',
                cursor: 'pointer',
                fontFamily: 'inherit'
              }}
            >
              ⚙️
            </button>
            <button
              onClick={() => toggleMode(false)}
              style={{
                padding: '6px 12px',
                backgroundColor: 'rgba(0,255,136,0.2)',
                border: `2px solid ${proTheme.neonGreen}`,
                borderRadius: '4px',
                color: proTheme.neonGreen,
                fontSize: '12px',
                cursor: 'pointer',
                fontFamily: 'inherit',
                fontWeight: '600',
                textShadow: `0 0 8px ${proTheme.neonGreen}`
              }}
            >
              기본모드
            </button>
          </div>
        </div>

        {/* 변수 패널 (Variables Panel) */}
        <div style={{
          backgroundColor: proTheme.bgCard,
          borderRadius: '8px',
          border: `1px solid ${proTheme.border}`,
          padding: '16px',
          marginBottom: '16px'
        }}>
          <div style={{ 
            color: proTheme.neonCyan, 
            fontSize: '12px', 
            marginBottom: '12px',
            letterSpacing: '1px'
          }}>
            ─── 변수 설정 ───
          </div>
          
          {/* 기본확률 (base_rate) */}
          <div style={{ display: 'flex', alignItems: 'center', marginBottom: '10px', gap: '8px' }}>
            <span style={{ width: '100px', color: proTheme.textDim, fontSize: '13px' }}>기본확률</span>
            <input
              type="number"
              value={rate}
              onChange={(e) => setRate(Math.max(0.001, parseFloat(e.target.value) || 0.001))}
              step="0.1"
              style={{
                width: '80px',
                padding: '6px 8px',
                backgroundColor: proTheme.bgInput,
                border: `1px solid ${proTheme.border}`,
                borderRadius: '4px',
                color: proTheme.neonGreen,
                fontSize: '14px',
                fontFamily: 'inherit'
              }}
            />
            <span style={{ color: proTheme.neonGreen, fontSize: '13px' }}>%</span>
          </div>

          {/* 천장 (pity_cap / hard_pity) */}
          <div style={{ display: 'flex', alignItems: 'center', marginBottom: '10px', gap: '8px' }}>
            <span style={{ width: '100px', color: proTheme.textDim, fontSize: '13px', display: 'flex', alignItems: 'center' }}>
              천장
              <HelpTooltip id="pity" />
            </span>
            <input
              type="number"
              min="0"
              max="500"
              value={noPity ? 0 : pity}
              onChange={(e) => {
                const val = Math.min(2500, parseInt(e.target.value) || 0);
                if (val === 0) {
                  setNoPity(true);
                } else {
                  setNoPity(false);
                  setPity(val);
                }
              }}
              style={{
                width: '80px',
                padding: '6px 8px',
                backgroundColor: proTheme.bgInput,
                border: `1px solid ${proTheme.border}`,
                borderRadius: '4px',
                color: noPity ? proTheme.textDim : proTheme.neonGreen,
                fontSize: '14px',
                fontFamily: 'inherit'
              }}
            />
            <span style={{ color: noPity ? proTheme.neonPink : proTheme.textDim, fontSize: '12px' }}>
              {noPity ? '천장 없음' : '뽑'}
            </span>
          </div>

          {/* 소프트 천장 (soft_pity) - 천장 근처에서 확률 증가 */}
          <div style={{ display: 'flex', alignItems: 'center', marginBottom: '10px', gap: '8px' }}>
            <span style={{ width: '100px', color: proTheme.textDim, fontSize: '13px', display: 'flex', alignItems: 'center' }}>
              소프트 천장
              <HelpTooltip id="softPity" />
            </span>
            <input
              type="number"
              value={softPityStart}
              onChange={(e) => setSoftPityStart(Math.max(0, parseInt(e.target.value) || 0))}
              placeholder="0"
              style={{
                width: '55px',
                padding: '6px 8px',
                backgroundColor: proTheme.bgInput,
                border: `1px solid ${proTheme.border}`,
                borderRadius: '4px',
                color: softPityStart > 0 ? proTheme.neonCyan : proTheme.textDim,
                fontSize: '14px',
                fontFamily: 'inherit'
              }}
            />
            <span style={{ color: proTheme.textDim, fontSize: '12px' }}>뽑부터</span>
            <span style={{ color: proTheme.neonCyan }}>+</span>
            <input
              type="number"
              value={softPityIncrease}
              onChange={(e) => setSoftPityIncrease(Math.max(0, parseFloat(e.target.value) || 0))}
              step="0.5"
              style={{
                width: '45px',
                padding: '6px 8px',
                backgroundColor: proTheme.bgInput,
                border: `1px solid ${proTheme.border}`,
                borderRadius: '4px',
                color: softPityStart > 0 ? proTheme.neonCyan : proTheme.textDim,
                fontSize: '14px',
                fontFamily: 'inherit'
              }}
            />
            <span style={{ color: proTheme.textDim, fontSize: '12px' }}>%씩</span>
          </div>

          {/* 픽업확률 (pickup_rate) - 당첨 시 원하는 캐릭터 획득 확률 */}
          <div style={{ marginBottom: '10px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '6px' }}>
              <span style={{ width: '100px', color: proTheme.textDim, fontSize: '13px', display: 'flex', alignItems: 'center' }}>
                픽업확률
                <HelpTooltip id="pickup" />
              </span>
              <input
                type="number"
                value={pickupRate}
                onChange={(e) => setPickupRate(Math.max(0.1, Math.min(100, parseFloat(e.target.value) || 100)))}
                step="0.1"
                min="0.1"
                max="100"
                style={{
                  width: '70px',
                  padding: '6px 8px',
                  backgroundColor: proTheme.bgInput,
                  border: `1px solid ${proTheme.border}`,
                  borderRadius: '4px',
                  color: proTheme.neonPurple,
                  fontSize: '14px',
                  fontFamily: 'inherit'
                }}
              />
              <span style={{ color: proTheme.textDim, fontSize: '12px' }}>%</span>
            </div>
            <div style={{ display: 'flex', gap: '6px', marginLeft: '100px' }}>
              {[
                { value: 100, label: '확정' },
                { value: 50, label: '50/50' },
                { value: 75, label: '75/25' }
              ].map(({ value, label }) => (
                <button
                  key={value}
                  onClick={() => setPickupRate(value)}
                  style={{
                    padding: '3px 8px',
                    backgroundColor: pickupRate === value ? proTheme.neonPurple + '33' : 'transparent',
                    border: `1px solid ${pickupRate === value ? proTheme.neonPurple : proTheme.border}`,
                    borderRadius: '4px',
                    color: pickupRate === value ? proTheme.neonPurple : proTheme.textDim,
                    fontSize: '11px',
                    cursor: 'pointer',
                    fontFamily: 'inherit'
                  }}
                >
                  {label}
                </button>
              ))}
            </div>
            <div style={{ fontSize: '11px', color: proTheme.textDim, marginTop: '4px', marginLeft: '100px' }}>
              당첨 시 원하는 캐릭 확률 (등급 내 n명 → {(100/pickupRate).toFixed(1)}명 중 1명)
            </div>
          </div>

          {/* 확정권 모드 (guarantee_on_fail) - 픽업확률 < 100%일 때만 표시 */}
          {pickupRate < 100 && (
            <div style={{ display: 'flex', alignItems: 'center', marginBottom: '10px', gap: '8px' }}>
              <span style={{ width: '100px', color: proTheme.textDim, fontSize: '13px', display: 'flex', alignItems: 'center' }}>
                확정권
                <HelpTooltip id="guarantee" />
              </span>
              <div style={{ display: 'flex', gap: '6px' }}>
                <button
                  onClick={() => setGuaranteeOnFail(true)}
                  style={{
                    padding: '4px 10px',
                    backgroundColor: guaranteeOnFail ? proTheme.neonCyan + '33' : 'transparent',
                    border: `1px solid ${guaranteeOnFail ? proTheme.neonCyan : proTheme.border}`,
                    borderRadius: '4px',
                    color: guaranteeOnFail ? proTheme.neonCyan : proTheme.textDim,
                    fontSize: '11px',
                    cursor: 'pointer',
                    fontFamily: 'inherit'
                  }}
                >
                  실패시 확정
                </button>
                <button
                  onClick={() => setGuaranteeOnFail(false)}
                  style={{
                    padding: '4px 10px',
                    backgroundColor: !guaranteeOnFail ? proTheme.neonCyan + '33' : 'transparent',
                    border: `1px solid ${!guaranteeOnFail ? proTheme.neonCyan : proTheme.border}`,
                    borderRadius: '4px',
                    color: !guaranteeOnFail ? proTheme.neonCyan : proTheme.textDim,
                    fontSize: '11px',
                    cursor: 'pointer',
                    fontFamily: 'inherit'
                  }}
                >
                  매번 독립
                </button>
              </div>
              <span style={{ fontSize: '10px', color: proTheme.textDim }}>
                {guaranteeOnFail ? '(원신식)' : '(등급보장식)'}
              </span>
            </div>
          )}

          {/* 목표장수 (target_copies) */}
          <div style={{ display: 'flex', alignItems: 'center', marginBottom: '10px', gap: '8px' }}>
            <span style={{ width: '100px', color: proTheme.textDim, fontSize: '13px', display: 'flex', alignItems: 'center' }}>
              목표장수
              <HelpTooltip id="copies" />
            </span>
            <input
              type="number"
              value={targetCopies}
              onChange={(e) => setTargetCopies(Math.min(20, Math.max(1, parseInt(e.target.value) || 1)))}
              min="1"
              max="20"
              style={{
                width: '60px',
                padding: '6px 8px',
                backgroundColor: proTheme.bgInput,
                border: `1px solid ${proTheme.border}`,
                borderRadius: '4px',
                color: proTheme.neonGreen,
                fontSize: '14px',
                fontFamily: 'inherit'
              }}
            />
            <span style={{ color: proTheme.textDim, fontSize: '12px' }}>장</span>
          </div>

          {/* 구분선 - 현재 상태 */}
          <div style={{ borderTop: `1px solid ${proTheme.border}`, margin: '12px 0', paddingTop: '12px' }}>
            <span style={{ color: proTheme.neonCyan, fontSize: '11px', letterSpacing: '1px' }}>── 현재 상태 ──</span>
          </div>

          {/* 현재 뽑기 수 (current_pulls) */}
          <div style={{ marginBottom: '10px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span style={{ width: '100px', color: proTheme.textDim, fontSize: '13px' }}>현재 뽑기 수</span>
              <input
                type="number"
                value={currentPulls}
                onChange={(e) => setCurrentPulls(Math.min(2500, Math.max(0, parseInt(e.target.value) || 0)))}
                min="0"
                disabled={noPity && softPityStart === 0}
                style={{
                  width: '80px',
                  padding: '6px 8px',
                  backgroundColor: proTheme.bgInput,
                  border: `1px solid ${proTheme.border}`,
                  borderRadius: '4px',
                  color: noPity ? proTheme.textDim : proTheme.neonGreen,
                  fontSize: '14px',
                  fontFamily: 'inherit'
                }}
              />
              <span style={{ color: proTheme.textDim, fontSize: '12px' }}>뽑</span>
            </div>
            {!noPity && pity > 0 && currentPulls > 0 && (
              <div style={{ marginLeft: '100px', marginTop: '4px', fontSize: '11px', color: proTheme.neonCyan }}>
                {Math.floor(currentPulls / pity) > 0 
                  ? `→ 천장 ${Math.floor(currentPulls / pity)}바퀴 완료, 다음 천장까지 ${pity - (currentPulls % pity)}뽑 남음`
                  : `→ 첫 천장까지 ${pity - currentPulls}뽑 남음`
                }
              </div>
            )}
          </div>

          {/* 확정권 상태 (current_guarantee) - 50/50 시스템일 때만 표시 */}
          {pickupRate < 100 && guaranteeOnFail && (
            <div style={{ display: 'flex', alignItems: 'center', marginBottom: '10px', gap: '8px' }}>
              <span style={{ width: '100px', color: proTheme.textDim, fontSize: '13px' }}>확정권 보유</span>
              <button
                onClick={() => setCurrentGuarantee(!currentGuarantee)}
                style={{
                  padding: '4px 12px',
                  backgroundColor: currentGuarantee ? proTheme.neonCyan + '33' : 'transparent',
                  border: `1px solid ${currentGuarantee ? proTheme.neonCyan : proTheme.border}`,
                  borderRadius: '4px',
                  color: currentGuarantee ? proTheme.neonCyan : proTheme.textDim,
                  fontSize: '12px',
                  cursor: 'pointer',
                  fontFamily: 'inherit'
                }}
              >
                {currentGuarantee ? '예 (다음 확정)' : '아니오'}
              </button>
            </div>
          )}

          {/* 구분선 - 비용 */}
          <div style={{ borderTop: `1px solid ${proTheme.border}`, margin: '12px 0', paddingTop: '12px' }}>
            <span style={{ color: proTheme.neonCyan, fontSize: '11px', letterSpacing: '1px' }}>── 비용 ──</span>
          </div>

          {/* 뽑당비용 (cost_per_pull) */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{ width: '100px', color: proTheme.textDim, fontSize: '13px' }}>뽑당비용</span>
            <input
              type="number"
              value={pricePerPull}
              onChange={(e) => setPricePerPull(Math.max(0, parseInt(e.target.value) || 0))}
              style={{
                width: '80px',
                padding: '6px 8px',
                backgroundColor: proTheme.bgInput,
                border: `1px solid ${proTheme.border}`,
                borderRadius: '4px',
                color: proTheme.neonGreen,
                fontSize: '14px',
                fontFamily: 'inherit'
              }}
            />
            <span style={{ color: proTheme.textDim, fontSize: '12px' }}>원</span>
          </div>
          
          {/* 초기화 버튼 */}
          <div style={{ marginTop: '12px', paddingTop: '12px', borderTop: `1px solid ${proTheme.border}` }}>
            <button
              onClick={confirmReset}
              style={{
                padding: '6px 12px',
                backgroundColor: 'transparent',
                border: `1px solid ${proTheme.border}`,
                borderRadius: '4px',
                color: proTheme.textDim,
                fontSize: '11px',
                cursor: 'pointer',
                fontFamily: 'inherit'
              }}
            >
              초기화
            </button>
          </div>
        </div>

        {/* 확률분포 히스토그램 (Distribution Histogram) */}
        {proResult && (
          <div style={{
            backgroundColor: proTheme.bgCard,
            borderRadius: '8px',
            border: `1px solid ${proTheme.border}`,
            padding: '16px',
            marginBottom: '16px'
          }}>
            <div style={{ 
              color: proTheme.neonCyan, 
              fontSize: '12px', 
              marginBottom: '12px',
              letterSpacing: '1px'
            }}>
              ─── 확률분포 ───
            </div>
            
            <div style={{ height: '120px', display: 'flex', alignItems: 'flex-end', gap: '2px' }}>
              {(() => {
                const maxPercent = Math.max(...proResult.histogram.map(b => b.percent), 0.001); // division by zero 방지
                return proResult.histogram.map((bin, i) => {
                  const height = maxPercent > 0 ? (bin.percent / maxPercent) * 100 : 0;
                  const isP50 = bin.start <= proResult.p50 && proResult.p50 < bin.end;
                  const isP90 = bin.start <= proResult.p90 && proResult.p90 < bin.end;
                  
                  return (
                    <div
                      key={i}
                      style={{
                        flex: 1,
                        height: `${height}%`,
                        backgroundColor: isP90 ? proTheme.neonPink : isP50 ? proTheme.neonCyan : proTheme.neonGreen,
                        opacity: isP50 || isP90 ? 1 : 0.6,
                        borderRadius: '2px 2px 0 0',
                        minHeight: '2px'
                      }}
                      title={`${bin.start}-${bin.end}뽑: ${bin.percent.toFixed(1)}%`}
                    />
                  );
                });
              })()}
            </div>
            
            <div style={{ 
              display: 'flex', 
              justifyContent: 'space-between', 
              marginTop: '8px',
              fontSize: '11px',
              color: proTheme.textDim 
            }}>
              <span>최소 {proResult.min}</span>
              <span style={{ color: proTheme.neonCyan }}>중앙값 {proResult.p50}</span>
              <span style={{ color: proTheme.neonPink }}>상위10% {proResult.p90}</span>
              <span>최대 {proResult.max}</span>
            </div>
          </div>
        )}

        {/* 통계 패널 (Statistics Panel) */}
        {proResult && (
          <div style={{
            backgroundColor: proTheme.bgCard,
            borderRadius: '8px',
            border: `1px solid ${proTheme.border}`,
            padding: '16px',
            marginBottom: '16px'
          }}>
            <div style={{ 
              color: proTheme.neonCyan, 
              fontSize: '12px', 
              marginBottom: '12px',
              letterSpacing: '1px'
            }}>
              ─── 통계 ({targetCopies}장 목표) ───
            </div>
            
            <div style={{ fontFamily: 'inherit', fontSize: '13px', lineHeight: '1.8' }}>
              {/* 기대값 E[X] = Expected Value */}
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: proTheme.textDim }}>기대값</span>
                <span style={{ color: proTheme.neonGreen }}>{proResult.mean}뽑</span>
              </div>
              {/* 표준편차 σ = Standard Deviation */}
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: proTheme.textDim }}>표준편차</span>
                <span style={{ color: proTheme.text }}>±{proResult.stdDev}</span>
              </div>
              <div style={{ borderTop: `1px solid ${proTheme.border}`, margin: '8px 0' }} />
              {/* 백분위수 Percentiles */}
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: proTheme.textDim }}>운 좋으면 (상위10%)</span>
                <span style={{ color: '#4ade80' }}>{proResult.p10}뽑</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: proTheme.textDim }}>중앙값 (절반)</span>
                <span style={{ color: proTheme.neonCyan }}>{proResult.p50}뽑</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: proTheme.textDim }}>운 나쁘면 (하위10%)</span>
                <span style={{ color: '#fbbf24' }}>{proResult.p90}뽑</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: proTheme.textDim }}>극악 (하위1%)</span>
                <span style={{ color: proTheme.neonPink }}>{proResult.p99}뽑</span>
              </div>
              <div style={{ borderTop: `1px solid ${proTheme.border}`, margin: '8px 0' }} />
              {/* 비용 환산 */}
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: proTheme.textDim }}>중앙값 비용</span>
                <span style={{ color: proTheme.text }}>{proResult.costs.p50.toLocaleString()}원</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: proTheme.textDim }}>운나쁨 비용</span>
                <span style={{ color: proTheme.text }}>{proResult.costs.p90.toLocaleString()}원</span>
              </div>
            </div>
          </div>
        )}

        {/* 계획 뽑기 계산 (Planned Pulls Query) */}
        <div style={{
          backgroundColor: proTheme.bgCard,
          borderRadius: '8px',
          border: `1px solid ${proTheme.neonGreen}`,
          padding: '16px',
          marginBottom: '16px',
          boxShadow: proTheme.glow
        }}>
          <div style={{ 
            color: proTheme.neonGreen, 
            fontSize: '12px', 
            marginBottom: '12px',
            letterSpacing: '1px'
          }}>
            ─── 성공확률 계산 ───
          </div>
          
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '12px' }}>
            <span style={{ color: proTheme.textDim, fontSize: '13px' }}>계획 뽑기수</span>
            <input
              type="number"
              value={plannedPulls}
              onChange={(e) => setPlannedPulls(Math.max(1, parseInt(e.target.value) || 1))}
              style={{
                width: '80px',
                padding: '6px 8px',
                backgroundColor: proTheme.bgInput,
                border: `1px solid ${proTheme.neonGreen}`,
                borderRadius: '4px',
                color: proTheme.neonGreen,
                fontSize: '14px',
                fontFamily: 'inherit'
              }}
            />
            <span style={{ color: proTheme.textDim, fontSize: '13px' }}>뽑</span>
          </div>
          
          {proResult && (
            <div style={{ 
              padding: '12px',
              backgroundColor: proTheme.neonGreen + '11',
              borderRadius: '4px',
              border: `1px solid ${proTheme.neonGreen}44`
            }}>
              <div style={{ fontSize: '12px', color: proTheme.textDim, marginBottom: '4px' }}>
                {plannedPulls}뽑으로 {targetCopies}장 얻을 확률
              </div>
              <div style={{ fontSize: '24px', fontWeight: 'bold', color: proTheme.neonGreen }}>
                {formatPercent(proResult.plannedSuccessRate)}%
              </div>
              <div style={{ fontSize: '12px', color: proTheme.textDim, marginTop: '4px' }}>
                예상비용: {(plannedPulls * pricePerPull).toLocaleString()}원
              </div>
            </div>
          )}
        </div>

        {/* 체감 문구 (Probability Feeling) */}
        {feelingData && proResult && (
          <div style={{
            backgroundColor: proTheme.bgCard,
            borderRadius: '8px',
            border: `1px solid ${proTheme.border}`,
            padding: '12px 16px',
            marginBottom: '16px'
          }}>
            <div style={{ fontSize: '12px', color: proTheme.neonCyan }}>
              💡 "{feelingData.event}" ({feelingData.rate}%) 정도의 확률
            </div>
            <div style={{ fontSize: '11px', color: proTheme.textDim, marginTop: '4px' }}>
              {feelingData.feeling}
            </div>
          </div>
        )}

        {/* 공유 버튼 */}
        <button
          onClick={handleShare}
          style={{
            width: '100%',
            padding: '12px',
            backgroundColor: 'transparent',
            border: `1px solid ${proTheme.neonGreen}`,
            borderRadius: '4px',
            color: proTheme.neonGreen,
            fontSize: '13px',
            fontWeight: '600',
            cursor: 'pointer',
            fontFamily: 'inherit',
            letterSpacing: '1px'
          }}
        >
          결과 공유하기
        </button>
        {shareStatus && (
          <div style={{ textAlign: 'center', marginTop: '8px', color: proTheme.neonGreen, fontSize: '12px' }}>
            {shareStatus}
          </div>
        )}

        {/* 광고 영역 (테스트 기간 비활성화) */}
        <div style={{ 
          display: 'none',
          marginTop: '16px', 
          padding: '30px', 
          backgroundColor: proTheme.bgCard, 
          borderRadius: '8px', 
          textAlign: 'center', 
          color: proTheme.textDim,
          border: `1px solid ${proTheme.border}`
        }}>
          광고 영역
        </div>

        {/* 면책조항 */}
        <p style={{ marginTop: '24px', fontSize: '10px', color: proTheme.textDim, textAlign: 'center', lineHeight: '1.5' }}>
          본 앱은 참고용 확률 계산 도구이며, 계산 결과의 정확성을 보장하지 않습니다.<br/>
          과금 결정에 대한 책임은 사용자 본인에게 있습니다.
        </p>
      </div>
    );
  }

  // ========== 기본 모드 UI ==========
  return (
    <div style={{ 
      maxWidth: '500px', 
      margin: '0 auto', 
      padding: '16px', 
      fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif',
      backgroundColor: basicTheme.bg,
      minHeight: '100vh',
      color: basicTheme.text
    }}>
      {/* 설정 모달 */}
      <SettingsModal />
      
      {/* 초기화 확인 모달 */}
      <ResetConfirmModal />
      
      {/* 도움말 모달 */}
      {showHelp && (
        <div style={{
          position: 'fixed',
          top: 0, left: 0, right: 0, bottom: 0,
          backgroundColor: 'rgba(0,0,0,0.5)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 1001,
          padding: '20px'
        }} onClick={() => setShowHelp(null)}>
          <div style={{
            backgroundColor: basicTheme.bgCard,
            borderRadius: '12px',
            padding: '20px',
            maxWidth: '320px',
            border: `1px solid ${basicTheme.border}`
          }} onClick={e => e.stopPropagation()}>
            <p style={{ margin: 0, fontSize: '14px', lineHeight: '1.6', color: basicTheme.text }}>
              {helpTexts[showHelp]}
            </p>
            <button
              onClick={() => setShowHelp(null)}
              style={{
                width: '100%',
                marginTop: '16px',
                padding: '10px',
                backgroundColor: basicTheme.accent,
                border: 'none',
                borderRadius: '6px',
                color: 'white',
                fontSize: '13px',
                fontWeight: '600',
                cursor: 'pointer'
              }}
            >
              확인
            </button>
          </div>
        </div>
      )}
      
      {/* 헤더 */}
      <div style={{ 
        display: 'flex', 
        justifyContent: 'space-between', 
        alignItems: 'center', 
        marginBottom: '16px', 
        padding: '14px 18px', 
        background: basicTheme.headerGradient,
        borderRadius: '12px', 
        boxShadow: '0 4px 12px rgba(0,0,0,0.15)'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <span style={{ fontSize: '20px' }}>🎰</span>
          <span style={{ 
            fontWeight: 'bold', 
            color: 'white',
            textShadow: '0 1px 3px rgba(0,0,0,0.3)'
          }}>가챠 계산기</span>
        </div>
        <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
          {/* 다크모드 토글 */}
          <button
            onClick={() => setDarkMode(!darkMode)}
            style={{
              padding: '6px 10px',
              backgroundColor: 'rgba(255,255,255,0.2)',
              border: '1px solid rgba(255,255,255,0.3)',
              borderRadius: '6px',
              color: 'white',
              fontSize: '14px',
              cursor: 'pointer'
            }}
            title={darkMode ? '라이트 모드로 전환' : '다크 모드로 전환'}
          >
            {darkMode ? '☀️' : '🌙'}
          </button>
          <button
            onClick={() => setShowSettings(true)}
            style={{
              padding: '6px 10px',
              backgroundColor: 'rgba(255,255,255,0.2)',
              border: '1px solid rgba(255,255,255,0.3)',
              borderRadius: '6px',
              color: 'white',
              fontSize: '14px',
              cursor: 'pointer'
            }}
          >
            ⚙️
          </button>
          <button
            onClick={() => toggleMode(true)}
            style={{
              padding: '6px 12px',
              backgroundColor: 'rgba(255,255,255,0.25)',
              border: '1px solid rgba(255,255,255,0.5)',
              borderRadius: '6px',
              color: 'white',
              fontSize: '12px',
              fontWeight: '600',
              cursor: 'pointer'
            }}
          >
            프로모드
          </button>
        </div>
      </div>

      {/* 픽업/등급보장 선택 */}
      <div style={{ marginBottom: '16px' }}>
        <div style={{ display: 'flex', borderRadius: '8px', overflow: 'hidden', border: `1px solid ${basicTheme.border}` }}>
          <button
            onClick={() => setPityType('pickup')}
            style={{
              flex: 1, padding: '12px', border: 'none', cursor: 'pointer',
              backgroundColor: pityType === 'pickup' ? basicTheme.accent : basicTheme.bgCard,
              color: pityType === 'pickup' ? 'white' : basicTheme.text,
              fontWeight: pityType === 'pickup' ? '600' : '400'
            }}
          >
            픽업 보장
          </button>
          <button
            onClick={() => setPityType('grade')}
            style={{
              flex: 1, padding: '12px', border: 'none', cursor: 'pointer',
              backgroundColor: pityType === 'grade' ? basicTheme.accent : basicTheme.bgCard,
              color: pityType === 'grade' ? 'white' : basicTheme.text,
              fontWeight: pityType === 'grade' ? '600' : '400'
            }}
          >
            등급 보장
          </button>
        </div>
        <div style={{ fontSize: '12px', color: basicTheme.textDim, marginTop: '6px' }}>
          {pityType === 'pickup' 
            ? '픽업: 천장 도달 시 해당 캐릭터 확정' 
            : '등급: 천장 도달 시 해당 등급 중 랜덤'}
        </div>
      </div>

      {/* 확률 입력 */}
      <div style={{ marginBottom: '16px' }}>
        <label style={{ display: 'block', marginBottom: '6px', fontWeight: '600', color: basicTheme.text }}>
          {pityType === 'pickup' ? '픽업 확률 (%)' : '등급 확률 (%)'}
        </label>
        <input
          type="number" value={rate}
          onChange={(e) => setRate(Math.max(0.001, parseFloat(e.target.value) || 0.001))}
          step="0.1" min="0.001" max="100"
          style={{ width: '100%', padding: '10px', fontSize: '16px', boxSizing: 'border-box', borderRadius: '8px', border: `1px solid ${basicTheme.border}`, backgroundColor: basicTheme.bgInput, color: basicTheme.text }}
        />
      </div>

      {/* 등급 내 캐릭터 수 (등급보장만) */}
      {pityType === 'grade' && (
        <div style={{ marginBottom: '16px' }}>
          <label style={{ display: 'block', marginBottom: '6px', fontWeight: '600', color: basicTheme.text }}>등급 내 캐릭터 수</label>
          <input
            type="number" value={charactersInGrade}
            onChange={(e) => setCharactersInGrade(Math.max(1, parseInt(e.target.value) || 1))}
            min="1"
            style={{ width: '100%', padding: '10px', fontSize: '16px', boxSizing: 'border-box', borderRadius: '8px', border: `1px solid ${basicTheme.border}`, backgroundColor: basicTheme.bgInput, color: basicTheme.text }}
          />
          <div style={{ marginTop: '6px' }}>
            <small style={{ color: basicTheme.textDim }}>
              일반 뽑기 특정캐릭 확률: {result.effectiveRatePercent}%
            </small>
            {result.cycleSuccessRate && (
              <small style={{ display: 'block', color: basicTheme.success }}>
                천장 1사이클({pity}뽑)당 성공률: {result.cycleSuccessRate}%
              </small>
            )}
            <small style={{ display: 'block', color: basicTheme.warning, marginTop: '4px' }}>
              ⚠️ 다른 캐릭 당첨 시 천장 리셋은 미반영 (근사치)
            </small>
          </div>
        </div>
      )}

      {/* 천장 */}
      <div style={{ marginBottom: '16px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
          <label style={{ fontWeight: '600', color: basicTheme.text }}>천장 (회)</label>
          <label style={{ display: 'flex', alignItems: 'center', gap: '6px', cursor: 'pointer', fontSize: '14px' }}>
            <input
              type="checkbox"
              checked={noPity}
              onChange={(e) => setNoPity(e.target.checked)}
              style={{ width: '16px', height: '16px', cursor: 'pointer' }}
            />
            <span style={{ color: noPity ? basicTheme.danger : basicTheme.textDim }}>천장 없음</span>
          </label>
        </div>
        <input
          type="number" 
          value={pity}
          onChange={(e) => setPity(Math.min(2500, Math.max(1, parseInt(e.target.value) || 1)))}
          min="1"
          max="500"
          disabled={noPity}
          style={{ 
            width: '100%', padding: '10px', fontSize: '16px', boxSizing: 'border-box', borderRadius: '8px', border: `1px solid ${basicTheme.border}`,
            backgroundColor: noPity ? basicTheme.bgCard : basicTheme.bgInput,
            color: noPity ? basicTheme.textDim : basicTheme.text
          }}
        />
        {noPity && (
          <small style={{ color: basicTheme.danger, display: 'block', marginTop: '4px' }}>
            ⚠️ 천장 없음 - 순수 확률로만 계산
          </small>
        )}
      </div>

      {/* 현재 뽑기 수 */}
      <div style={{ marginBottom: '16px' }}>
        <label style={{ display: 'block', marginBottom: '6px', fontWeight: '600', color: basicTheme.text }}>현재 뽑기 수</label>
        <input
          type="number" value={currentPulls}
          onChange={(e) => setCurrentPulls(Math.min(2500, Math.max(0, parseInt(e.target.value) || 0)))}
          min="0"
          disabled={noPity}
          style={{ 
            width: '100%', padding: '10px', fontSize: '16px', boxSizing: 'border-box', borderRadius: '8px', border: `1px solid ${basicTheme.border}`,
            backgroundColor: noPity ? basicTheme.bgCard : basicTheme.bgInput,
            color: noPity ? basicTheme.textDim : basicTheme.text
          }}
        />
        {!noPity && result.hasPity && currentPulls > 0 && (
          <small style={{ color: basicTheme.success, display: 'block', marginTop: '4px' }}>
            {result.completedCycles > 0 
              ? `→ 천장 ${result.completedCycles}바퀴 완료, 다음 천장까지 ${result.remainingPity}뽑 남음`
              : `→ 첫 천장까지 ${result.remainingPity}뽑 남음`
            }
          </small>
        )}
        {noPity && (
          <small style={{ color: basicTheme.textDim, display: 'block', marginTop: '4px' }}>
            (천장 없음 - 현재 뽑기 수 무관)
          </small>
        )}
      </div>

      {/* 1뽑 가격 */}
      <div style={{ marginBottom: '16px' }}>
        <label style={{ display: 'block', marginBottom: '6px', fontWeight: '600', color: basicTheme.text }}>1뽑 가격 (원)</label>
        <input
          type="number" value={pricePerPull}
          onChange={(e) => setPricePerPull(Math.max(0, parseInt(e.target.value) || 0))}
          min="0"
          style={{ width: '100%', padding: '10px', fontSize: '16px', boxSizing: 'border-box', borderRadius: '8px', border: `1px solid ${basicTheme.border}`, backgroundColor: basicTheme.bgInput, color: basicTheme.text }}
        />
      </div>
      
      {/* 초기화 버튼 */}
      <div style={{ marginBottom: '16px', textAlign: 'right' }}>
        <button
          onClick={confirmReset}
          style={{
            padding: '6px 12px',
            backgroundColor: 'transparent',
            border: `1px solid ${basicTheme.border}`,
            borderRadius: '6px',
            color: basicTheme.textDim,
            fontSize: '12px',
            cursor: 'pointer'
          }}
        >
          🔄 초기화
        </button>
      </div>

      {/* 계획 뽑기 수 */}
      <div style={{ marginBottom: '16px' }}>
        <label style={{ display: 'block', marginBottom: '6px', fontWeight: '600', color: basicTheme.text }}>🎯 내가 뽑을 횟수</label>
        <input
          type="number" value={plannedPulls}
          onChange={(e) => setPlannedPulls(Math.max(1, parseInt(e.target.value) || 1))}
          min="1"
          style={{ width: '100%', padding: '10px', fontSize: '16px', boxSizing: 'border-box', borderRadius: '8px', border: `2px solid ${basicTheme.accent}`, backgroundColor: basicTheme.bgInput, color: basicTheme.text }}
        />
      </div>

      {/* 결과 */}
      <div style={{ backgroundColor: basicTheme.bgCard, padding: '16px', borderRadius: '12px', border: `1px solid ${basicTheme.border}` }}>
        <h3 style={{ margin: '0 0 12px 0', color: basicTheme.text }}>결과 (특정 캐릭 1장)</h3>
        
        <div style={{ padding: '14px', backgroundColor: basicTheme.accent, borderRadius: '8px', marginBottom: '12px', color: 'white' }}>
          <div style={{ fontSize: '14px', opacity: 0.9 }}>🎯 {plannedPulls}뽑 했을 때 성공확률</div>
          <div style={{ fontSize: '28px', fontWeight: 'bold', marginTop: '4px' }}>{formatPercent(result.plannedSuccessRate)}%</div>
          <div style={{ fontSize: '13px', opacity: 0.8, marginTop: '4px' }}>
            비용: {(plannedPulls * pricePerPull).toLocaleString()}원 / 🍗 {((plannedPulls * pricePerPull) / 20000).toFixed(1)}마리
          </div>
        </div>
        
        <div style={{ padding: '12px', backgroundColor: darkMode ? '#064e3b' : '#d1fae5', borderRadius: '8px', marginBottom: '8px' }}>
          <div style={{ color: darkMode ? '#6ee7b7' : '#065f46' }}>😊 운 좋으면 (50%): <strong>{result.median}뽑</strong></div>
          <div style={{ color: darkMode ? '#a7f3d0' : '#047857' }}>{result.costs.median.toLocaleString()}원 / 🍗 {result.chickens.median}마리</div>
        </div>

        <div style={{ padding: '12px', backgroundColor: darkMode ? '#78350f' : '#fef3c7', borderRadius: '8px', marginBottom: '8px' }}>
          <div style={{ color: darkMode ? '#fcd34d' : '#92400e' }}>😐 거의 확실 (90%): <strong>{result.p90}뽑</strong></div>
          <div style={{ color: darkMode ? '#fde68a' : '#b45309' }}>{result.costs.p90.toLocaleString()}원 / 🍗 {result.chickens.p90}마리</div>
        </div>

        <div style={{ padding: '12px', backgroundColor: darkMode ? '#7f1d1d' : '#fee2e2', borderRadius: '8px', marginBottom: '8px' }}>
          <div style={{ color: darkMode ? '#fca5a5' : '#991b1b' }}>😭 최악 (99%): <strong>{result.p99}뽑</strong></div>
          <div style={{ color: darkMode ? '#fecaca' : '#b91c1c' }}>{result.costs.p99.toLocaleString()}원 / 🍗 {result.chickens.p99}마리</div>
        </div>

        <div style={{ fontSize: '14px', color: basicTheme.textDim, marginTop: '8px' }}>
          평균: {result.expected}뽑
        </div>

        {feelingData && (
          <div style={{ marginTop: '16px', padding: '12px', backgroundColor: darkMode ? '#312e81' : '#e0e7ff', borderRadius: '8px' }}>
            <div style={{ fontSize: '13px', color: darkMode ? '#a5b4fc' : '#4338ca', marginBottom: '4px' }}>💡 {formatPercent(result.plannedSuccessRate)}% 확률이란?</div>
            <div style={{ fontSize: '15px', fontWeight: '600', color: darkMode ? '#c7d2fe' : '#312e81' }}>
              "{feelingData.event}" ({feelingData.rate}%)
            </div>
            <div style={{ fontSize: '13px', color: darkMode ? '#a5b4fc' : '#4338ca', marginTop: '4px' }}>
              {feelingData.feeling}
            </div>
          </div>
        )}

        <button
          onClick={handleShare}
          style={{
            width: '100%', marginTop: '16px', padding: '12px',
            backgroundColor: basicTheme.success, color: 'white', border: 'none', borderRadius: '8px',
            fontSize: '15px', fontWeight: '600', cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px'
          }}
        >
          📤 결과 공유하기
        </button>
        {shareStatus && (
          <div style={{ textAlign: 'center', marginTop: '8px', color: basicTheme.success, fontSize: '13px' }}>
            {shareStatus}
          </div>
        )}
      </div>

      {/* 광고 영역 (테스트 기간 비활성화) */}
      <div style={{ display: 'none', marginTop: '16px', padding: '30px', backgroundColor: basicTheme.bgCard, borderRadius: '8px', textAlign: 'center', color: basicTheme.textDim, border: `1px solid ${basicTheme.border}` }}>
        광고 영역
      </div>

      <p style={{ marginTop: '24px', fontSize: '11px', color: basicTheme.textDim, textAlign: 'center', lineHeight: '1.5' }}>
        본 앱은 참고용 확률 계산 도구이며, 계산 결과의 정확성을 보장하지 않습니다.<br/>
        과금 결정에 대한 책임은 사용자 본인에게 있습니다.
      </p>
    </div>
  );
}
