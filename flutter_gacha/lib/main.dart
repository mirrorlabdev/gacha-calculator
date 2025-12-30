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

class GachaCalculatorApp extends StatelessWidget {
  const GachaCalculatorApp({super.key});

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
              fontFamily: provider.proMode ? 'JetBrainsMono' : null,
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
