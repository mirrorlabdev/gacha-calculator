import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gacha_provider.dart';
import '../utils/themes.dart';
import 'basic_mode_screen.dart';
import 'pro_mode_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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

        return provider.proMode
            ? const ProModeScreen()
            : const BasicModeScreen();
      },
    );
  }
}
