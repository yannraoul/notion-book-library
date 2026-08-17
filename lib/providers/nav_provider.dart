import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Drives `RootShell`'s `IndexedStack` — 0 = Home, 1 = Settings. Same
/// pattern as the sister Habits app's own tab-index provider.
final selectedTabProvider = StateProvider<int>((ref) => 0);
