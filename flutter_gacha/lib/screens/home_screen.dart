import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gacha_provider.dart';
import '../utils/themes.dart';
import '../widgets/update_popup.dart';
import 'basic_mode_screen.dart';
import 'pro_mode_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasCheckedUpdate = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<GachaProvider>(
      builder: (context, provider, _) {
        if (!provider.isLoaded) {
          final theme = GachaTheme.getTheme(
            proMode: false,
            darkMode: provider.darkMode,
          );
          return Scaffold(
            backgroundColor: theme.bg,
            body: Center(
              child: CircularProgressIndicator(
                color: theme.accent,
              ),
            ),
          );
        }

        // 로드 완료 후 업데이트 체크 (한 번만)
        if (!_hasCheckedUpdate) {
          _hasCheckedUpdate = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final theme = GachaTheme.getTheme(
              proMode: provider.proMode,
              darkMode: provider.darkMode,
            );
            checkAndShowUpdatePopup(context, theme);
          });
        }

        // 각 모드별 폰트를 화면 레벨에서 적용 (MaterialApp 리빌드 방지)
        final fontFamily = provider.proMode ? 'D2Coding' : 'Pretendard';
        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.apply(fontFamily: fontFamily),
          ),
          child: provider.proMode
              ? const ProModeScreen()
              : const BasicModeScreen(),
        );
      },
    );
  }
}
