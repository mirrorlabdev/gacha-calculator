import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/gacha_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 상태바 스타일 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  runApp(const GachaCalculatorApp());
}

class GachaCalculatorApp extends StatefulWidget {
  const GachaCalculatorApp({super.key});

  @override
  State<GachaCalculatorApp> createState() => _GachaCalculatorAppState();
}

class _GachaCalculatorAppState extends State<GachaCalculatorApp> {
  bool _fontsLoaded = false;

  @override
  void initState() {
    super.initState();
    // 첫 프레임 이후 폰트 로딩 완료로 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 다음 프레임까지 대기 (폰트 렌더링 완료 보장)
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) setState(() => _fontsLoaded = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GachaProvider()..loadSettings(),
      child: Consumer<GachaProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            title: '가챠 계산기',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: provider.darkMode ? Brightness.dark : Brightness.light,
            ),
            home: Stack(
              children: [
                const HomeScreen(),
                // 폰트 프리로딩: 투명하게 두 폰트 모두 렌더링하여 캐싱
                if (!_fontsLoaded)
                  const Positioned(
                    left: -1000,
                    child: Column(
                      children: [
                        Text('가챠 계산기 PRO 0123456789', style: TextStyle(fontFamily: 'D2Coding')),
                        Text('가챠 계산기 PRO 0123456789', style: TextStyle(fontFamily: 'Pretendard')),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
