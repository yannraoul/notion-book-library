# NBLB-5 — bottom nav bar didn't extend to the bottom of the screen like the Habits app

Compared `lib/screens/root_shell.dart` (Shelf) against the sister Habits
app's equivalent (`notion-habit-tracker/lib/widgets/app_bottom_nav.dart`)
directly, since Yann described the visual mismatch by reference to that
app. Habits wraps `SafeArea(top: false, ...)` **inside** a colored
`DecoratedBox` — the surface-colored background sizes to the `SafeArea`'s
full reported height (which includes the bottom safe-area inset as
internal padding), so the color extends behind the home indicator all the
way to the physical bottom edge; only the actual nav-item content is
padded up above it.

Shelf had the nesting inverted: `SafeArea(top: false, child: Container(
decoration: ..., ...))`. Here the colored `Container` is the SafeArea's
*child*, so the inset strip below it is never painted by the container's
decoration at all — it just showed the plain `Scaffold` background through
that strip instead of the nav bar's surface color, reading as the bar
stopping short of the bottom edge.

Fix: restructure to match Habits' pattern —
`DecoratedBox(decoration: ..., child: SafeArea(top: false, child: Padding(...)))`
— decoration on the outside, safe-area inset applied only to the inner
content padding.

Not meaningfully verifiable on `flutter run -d windows`: desktop reports a
zero bottom safe-area inset, so the two nesting orders render identically
there regardless of which is correct — this only shows a visible
difference on a real device with a home indicator or gesture-nav inset.
`flutter analyze` is clean; visual confirmation needs the next
Codemagic/Sideloadly iPhone run.
