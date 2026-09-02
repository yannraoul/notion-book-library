# iOS sideloading & 7-day auto-refresh (SideStore)

Shelf's iOS build is signed with a **free Apple ID**, so its certificate
expires after **7 days**. There is no Mac locally; `codemagic.yaml`
produces an *unsigned* IPA (`Shelf.ipa`) that gets re-signed on install.

This doc covers keeping the app alive without rebuilding on Codemagic
every week, using **SideStore**: after a one-time install it re-signs the
app **on-device** over Wi-Fi before the cert expires. The PC is only
needed for the initial install (and after a major iOS update).

The same setup covers the sister Habits app — same machine, same Apple ID.
Free accounts allow **3 sideloaded apps at once**; SideStore itself counts
as one, leaving room for both apps.

## Why SideStore and not AltStore

- **AltStore PAL** (the EU marketplace version) installs *notarized* apps
  from sources only — it **cannot sideload your own `.ipa`**. Useless for
  Shelf. If it's currently installed, delete it.
- **AltStore Classic** *can* sideload your own IPA, but it needs AltServer
  running on the PC whenever you sign in or refresh, and it derives Apple
  auth data ("anisette") from **iCloud for Windows** — a fragile
  dependency that commonly fails with
  `Failed to login — the data couldn't be read because it isn't in the
  correct format`.
- **SideStore** is an AltStore Classic fork that fixes both: anisette
  comes from its own hosted server (configurable), and refresh runs
  on-device, so the PC doesn't need to stay on.

---

## One-time setup — PC (Windows, 64-bit, Win 8+)

1. Install **iTunes** — the standalone installer from apple.com is
   recommended over the Microsoft Store version (or the Apple Devices
   app as an alternative). This provides the USB device drivers.
2. Download **iloader** from the SideStore GitHub releases
   (<https://github.com/SideStore/SideStore/releases> — take the `.msi`)
   and run the installer.

## One-time setup — install SideStore on the iPhone

The iPhone needs iOS 15+ **with a passcode set**.

3. Plug the iPhone in via USB, unlock, tap **Trust This Computer**.
4. Launch **iloader** → sign in with your Apple ID and its **normal
   account password** (not an app-specific password). With 2FA on, it
   prompts separately for the 6-digit code.
5. Pick your device from the list → **Install SideStore (Stable)**.
6. On the iPhone, trust the app:
   - Settings → General → **VPN & Device Management** → under *Developer
     App* tap your Apple ID name → **Trust**.
   - iOS 16+: also Settings → Privacy & Security → **Developer Mode** → on
     (device restarts).
   - iOS 18+: choose **Allow & Restart** and confirm with your passcode.
7. Install **LocalDevVPN** from the App Store, open it, tap **Connect**.
   Leave it connected — it's a loopback VPN (no traffic leaves the device)
   that lets SideStore re-sign apps locally.

## First launch

8. Open **SideStore** → sign in with the **same Apple ID** used in
   iloader.
9. Go to **My Apps** → tap the **"7 DAYS"** counter to force a refresh and
   finish setup → accept any certificate prompt (**Refresh Now** / **Yes**).

## Install Shelf

10. Get `Shelf.ipa` from the Codemagic `ios-unsigned` workflow artifact.
    SideStore re-signs it on install, so the unsigned IPA is fine.
11. Transfer the IPA to the phone (AirDrop / Files / iCloud Drive), then
    SideStore → **My Apps → "+"** → select the `.ipa`. It re-signs with
    the 7-day cert and installs.

Repeat step 11 with the Habits IPA.

---

## Ongoing — the automatic part

- With **LocalDevVPN connected** and the phone on Wi-Fi, SideStore
  re-signs Shelf in the background before the 7 days elapse. The PC is not
  involved.
- iOS does not *guarantee* background execution. Backstop habit: **open
  SideStore every few days** (on Wi-Fi) and tap refresh on the My Apps
  tab — a few seconds.
- If the app *does* expire (LocalDevVPN was off, or no Wi-Fi for >7 days)
  it simply won't launch until the next refresh. The local `sqflite`
  cache is untouched — no data loss, and Notion is the source of truth
  anyway.
- **Refresh needs Wi-Fi** — cellular won't trigger it.
- After a **major iOS update** the device pairing can break; re-run
  iloader (or re-import the pairing file per the SideStore pairing-file
  guide).

## When shipping a code change

Unchanged from the normal flow:

1. Push → Codemagic `ios-unsigned` → download the new `Shelf.ipa`.
2. SideStore → **My Apps → "+"** → select the new IPA. Installs over the
   top, keeps app data. The refresh cycle continues from there.

---

## Troubleshooting

**Login fails / "isn't in the correct format", or setup hangs**
- This is the **anisette server** — and note that login working in
  iloader on the PC does *not* mean the phone will work: iloader uses a
  local source, the phone app calls a remote server, and SideStore's
  default (`ani.sidestore.io`) is often overloaded and returns an error
  page instead of JSON → "isn't in the correct format".
- SideStore → Settings → **Anisette Server** → refresh the server list and
  pick a *different* one. Alternatives: `https://sidestore.io/anisette/`,
  `https://anisette.sideloadly.io/`, or retry the default a few times.
- Then clear the app cache / reset `adi.pb` if shown, and sign in again.
- Phone **date & time on automatic**; **iCloud Private Relay off**.
- Use your **normal Apple ID password**, never an app-specific one; enter
  the 2FA code when prompted.
- Once the first login succeeds the anisette data is cached and later
  refreshes are far more robust.

**VPN / "AFC connection failed" / can't reach device**
- Use **LocalDevVPN**, not WireGuard or StosVPN.
- Turn off DNS blockers, content blockers, and **iCloud Private Relay**.
- Confirm LocalDevVPN shows *Connected*; restart SideStore; recreate the
  pairing file if it persists.

**"Could not determine this device's UDID" (error 1006) / can't refresh**
- Stale/missing pairing file (happens after iOS updates or device resets
  — Apple limitation). Re-pair on **both** sides — re-placing from iloader
  alone does not overwrite SideStore's cached pairing:
  1. SideStore → Settings → **Reset Pairing File** (+ reset `adi.pb` /
     clear cache if shown).
  2. iloader (phone plugged in via USB, unlocked): **Delete Stored
     Pairing** → select device → **Trust** on the phone → **Manage
     Pairing File** → **Place** → wait for success.
  3. Phone: Wi-Fi **ON** *and* LocalDevVPN **Connected** — 1006/1414 need
     both.
  4. Force-quit SideStore, reopen, retry.
- Still failing: SideStore → Settings → VPN/advanced device address should
  be **`10.7.0.1`**; confirm you're on the current stable channel (re-run
  iloader → Install SideStore); restart phone + PC and repeat.

**"Maximum number of apps" reached**
- Free accounts allow 3 sideloaded apps (SideStore + Shelf + Habits =
  exactly 3). Remove anything else sideloaded.

---

## Alternatives (not used here)

- **AltStore Classic** — works for custom IPAs but needs AltServer running
  on the PC and iCloud for Windows for anisette; brittle login. If going
  this route, use the legacy **iCloud 12.x** standalone installer from
  Apple, not the Store app or 14.x/15.x.
- **AltStore PAL** — EU marketplace, notarized apps only, cannot sideload
  your own IPA.
- **Apple Developer Program ($99/yr)** — 1-year signing certs. Configure
  signing in Codemagic, `flutter build ipa`, install once, ignore for
  ~12 months. Eliminates the refresh problem entirely.
