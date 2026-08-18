import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../services/settings_storage.dart';
import '../theme/color_tokens.dart';
import '../theme/spacing.dart';
import 'root_shell.dart';
import 'scan_screen.dart';

const hasSeenOnboardingKey = 'hasSeenOnboarding';

/// Design screens 01-03 — the 3-page onboarding carousel (button-driven,
/// no swipe — matches `Shelf.dc.html`'s `goOnboarding2`/`goOnboarding3`).
/// [standalone] is true when this is `MyApp.home` on first launch (exiting
/// replaces the whole app root with [RootShell]); false when pushed from
/// Settings' "View onboarding again" (exiting just pops back).
class OnboardingScreen extends ConsumerStatefulWidget {
  final bool standalone;
  const OnboardingScreen({super.key, this.standalone = true});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _page = 0;

  Future<void> _exit(BuildContext context, {bool startScan = false}) async {
    final navigator = Navigator.of(context);
    await SettingsStorage().write(hasSeenOnboardingKey, 'true');
    if (widget.standalone) {
      navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const RootShell()), (route) => false);
    } else {
      navigator.pop();
    }
    if (startScan) {
      navigator.push(MaterialPageRoute(builder: (_) => const ScanScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = ref.watch(colorTokensProvider(MediaQuery.platformBrightnessOf(context)));

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
          child: switch (_page) {
            0 => _OnboardingPage1(tokens: tokens, l10n: l10n, onSkip: () => _exit(context), onNext: () => setState(() => _page = 1)),
            1 => _OnboardingPage2(tokens: tokens, l10n: l10n, onSkip: () => _exit(context), onNext: () => setState(() => _page = 2)),
            _ => _OnboardingPage3(
                tokens: tokens,
                l10n: l10n,
                onScan: () => _exit(context, startScan: true),
                onSkip: () => _exit(context),
              ),
          },
        ),
      ),
    );
  }
}

class _SkipLink extends StatelessWidget {
  final AppColorTokens tokens;
  final String label;
  final VoidCallback onTap;
  const _SkipLink({required this.tokens, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(onTap: onTap, child: Text(label, style: TextStyle(fontSize: 14, color: tokens.muted))),
      ],
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final AppColorTokens tokens;
  final int index;
  const _DotIndicator({required this.tokens, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final active = i == index;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: active ? tokens.accent : tokens.border,
            ),
          );
        }),
      ),
    );
  }
}

Widget _primaryButton(AppColorTokens tokens, String label, VoidCallback onTap) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: tokens.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    ),
  );
}

class _OnboardingPage1 extends StatelessWidget {
  final AppColorTokens tokens;
  final AppLocalizations l10n;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  const _OnboardingPage1({required this.tokens, required this.l10n, required this.onSkip, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SkipLink(tokens: tokens, label: l10n.onboardingSkip, onTap: onSkip),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: tokens.accentSoft, borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.menu_book_outlined, color: tokens.accent, size: 34),
              ),
              const SizedBox(height: 18),
              Text(l10n.ob1Title, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: tokens.text)),
              const SizedBox(height: 12),
              Text(
                l10n.ob1Body,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.5, color: tokens.muted, height: 1.6),
              ),
            ],
          ),
        ),
        _DotIndicator(tokens: tokens, index: 0),
        _primaryButton(tokens, l10n.onboardingNext, onNext),
      ],
    );
  }
}

class _OnboardingPage2 extends StatelessWidget {
  final AppColorTokens tokens;
  final AppLocalizations l10n;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  const _OnboardingPage2({required this.tokens, required this.l10n, required this.onSkip, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SkipLink(tokens: tokens, label: l10n.onboardingSkip, onTap: onSkip),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.ob2Title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: tokens.text),
              ),
              const SizedBox(height: 22),
              _OnboardingRow(tokens: tokens, icon: Icons.qr_code_scanner, label: l10n.ob2BodyScan),
              const SizedBox(height: 22),
              _OnboardingRow(tokens: tokens, icon: Icons.photo_camera_outlined, label: l10n.ob2BodyPhoto),
              const SizedBox(height: 22),
              _OnboardingRow(tokens: tokens, icon: Icons.edit_outlined, label: l10n.ob2BodyManual),
            ],
          ),
        ),
        _DotIndicator(tokens: tokens, index: 1),
        _primaryButton(tokens, l10n.onboardingNext, onNext),
      ],
    );
  }
}

class _OnboardingRow extends StatelessWidget {
  final AppColorTokens tokens;
  final IconData icon;
  final String label;
  const _OnboardingRow({required this.tokens, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: tokens.accentSoft, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: tokens.accent, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: tokens.text))),
      ],
    );
  }
}

class _OnboardingPage3 extends StatelessWidget {
  final AppColorTokens tokens;
  final AppLocalizations l10n;
  final VoidCallback onScan;
  final VoidCallback onSkip;
  const _OnboardingPage3({required this.tokens, required this.l10n, required this.onScan, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 14),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: tokens.secondarySoft, shape: BoxShape.circle),
                child: Icon(Icons.check_circle, color: tokens.secondary, size: 36),
              ),
              const SizedBox(height: 18),
              Text(l10n.ob3Title, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: tokens.text)),
              const SizedBox(height: 12),
              Text(
                l10n.ob3Body,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.5, color: tokens.muted, height: 1.6),
              ),
            ],
          ),
        ),
        _DotIndicator(tokens: tokens, index: 2),
        _primaryButton(tokens, l10n.obScanCta, onScan),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onSkip,
            style: OutlinedButton.styleFrom(
              foregroundColor: tokens.text,
              side: BorderSide(color: tokens.border, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 12.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius)),
            ),
            child: Text(l10n.obSkipToShelf, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
