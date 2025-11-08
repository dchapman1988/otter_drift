# Otter Drift

Otter Drift is a Flutter + Flame arcade game where you guide an otter down river rapids while collecting items and dodging hazards. This repository contains the Flutter client and requires a Rails API backend for player authentication and leaderboard data.

## Prerequisites

- Flutter 3.22+ (check with `flutter --version`)
- Dart SDK (bundled with Flutter)
- Ruby on Rails backend running on <http://localhost:3000> *(or update the base URL via `--dart-define` flags – see below)*

## Setup

```bash
git clone <repository-url>
cd otter_drift
flutter pub get
```

Provide the API credentials at runtime. At minimum an `API_KEY` must be supplied (`CLIENT_ID` is optional and defaults to `game_client_1`):

```bash
flutter run \
  --dart-define=API_KEY=your_64_char_hex_key \
  --dart-define=CLIENT_ID=game_client_1 \
  --dart-define=API_BASE=http://localhost:3000
```

Building for release uses the same flags:

```bash
flutter build apk --dart-define=API_KEY=prod_key_here
```

## Project Structure

- `lib/game/` – Flame components, HUD, and game loop
- `lib/screens/` – Flutter screens (auth, menu, profile, leaderboard)
- `lib/services/` – API, authentication, security, and logging helpers
- `assets/` – Sprites, audio, and UI art

## Gameplay

- **Objective** – Stay alive as long as possible while racking up score.
- **Controls** – Tap anywhere to move the otter horizontally toward the tap position.
- **Hearts** – You begin with 3. Colliding with a log costs one heart; grabbing a floating heart restores one (max 3).
- **Lilies** – Each lily collected adds 10 points.
- **Logs** – Avoid them; repeated collisions end the run.
- **Difficulty** – Base river speed is 120 px/s and increases by ~10% every 20 seconds, capping at 240 px/s. Spawn mix is roughly 60% logs, 25% lilies, 15% hearts.
- **Game Over** – Shows run stats and lets you submit the score to the backend (if signed in) or replay.

Guest play is supported; signing in enables profile sync, achievements, and placement on the global leaderboard managed by the Rails API.

## Backend Notes

- Default API base URL is `http://localhost:3000` (Android emulators automatically use `http://10.0.2.2:3000`).
- Ensure the Rails server exposes the expected routes (auth, profile, leaderboard, game sessions) and shares the same API key.
- Certificate pinning placeholders live in `lib/services/security_config.dart` if you plan to deploy to production.

## Troubleshooting

- **Missing API key** – Flutter builds fail with a descriptive error; re-run with `--dart-define=API_KEY=...`.
- **401 / auth issues** – Confirm the backend is running, keys match, and device/emulator can reach the host URL.
- **Sprite/audio not loading** – Check asset paths in `pubspec.yaml` and confirm they are bundled.

Happy drifting! 🦦