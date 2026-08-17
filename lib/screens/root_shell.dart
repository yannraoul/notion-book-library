import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/nav_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/typography.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

/// Hand-rolled bottom nav + `IndexedStack`, not `BottomNavigationBar` — no
/// `AppBar` anywhere, per `instructions.md`'s layout convention. All tabs
/// stay mounted so switching back to Home doesn't lose scroll position.
class RootShell extends ConsumerWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = ref.watch(colorTokensProvider(MediaQuery.platformBrightnessOf(context)));
    final selectedTab = ref.watch(selectedTabProvider);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: selectedTab,
          children: const [HomeScreen(), SettingsScreen()],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border(top: BorderSide(color: tokens.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              children: [
                _NavItem(
                  label: l10n.navHome,
                  active: selectedTab == 0,
                  activeColor: tokens.accent,
                  mutedColor: tokens.muted,
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 0,
                ),
                _NavItem(
                  label: l10n.navSettings,
                  active: selectedTab == 1,
                  activeColor: tokens.accent,
                  mutedColor: tokens.muted,
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final Color mutedColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.mutedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.navLabel(active ? activeColor : mutedColor),
          ),
        ),
      ),
    );
  }
}
