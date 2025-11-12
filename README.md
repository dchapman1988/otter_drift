# Otter Drift

Otter Drift is a Flutter + Flame arcade game where you guide an otter down river rapids while collecting items and dodging hazards. This repository contains the Flutter client and requires a Rails API backend for player authentication and leaderboard data.

Frontend repo: this project  
Backend repo: [otter_drift_api](https://github.com/dchapman1988/otter_drift_api/)

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

## Important Details

- Authentication uses JWT tokens stored via `flutter_secure_storage`; all API calls run through `ApiService` which injects auth headers and enforces certificate pinning rules.
- All secret configuration (API keys, base URLs) must be provided via `--dart-define` flags at build/run time to avoid leaking credentials.
- The project ships with a structured logging utility (`SecureLogger`) that automatically masks sensitive fields before writing to console.
- Asset pipeline lives under `assets/`; be sure to run `flutter pub get` after modifying `pubspec.yaml` to include new sprites or audio.

## Backend Notes

- Default API base URL is `http://localhost:3000` (Android emulators automatically use `http://10.0.2.2:3000`).
- Ensure the Rails server exposes the expected routes (auth, profile, leaderboard, game sessions) and shares the same API key.
- Certificate pinning placeholders live in `lib/services/security_config.dart` if you plan to deploy to production.

## Troubleshooting

- **Missing API key** – Flutter builds fail with a descriptive error; re-run with `--dart-define=API_KEY=...`.
- **401 / auth issues** – Confirm the backend is running, keys match, and device/emulator can reach the host URL.
- **Sprite/audio not loading** – Check asset paths in `pubspec.yaml` and confirm they are bundled.

Happy drifting! 🦦

## Media
<img width="517" height="1029" alt="Screenshot 2025-11-08 at 3 17 59 PM" src="https://github.com/user-attachments/assets/5adb68fd-1fa7-4ccd-a5d2-52f14cbfc9cb" />
<img width="517" height="1029" alt="Screenshot 2025-11-12 at 2 27 56 PM" src="https://github.com/user-attachments/assets/97459875-1033-43a5-ba9f-2a39a4bbdb34" />
<img width="517" height="1029" alt="Screenshot 2025-11-08 at 3 17 45 PM" src="https://github.com/user-attachments/assets/921dab53-74fd-4bd4-9287-9b1296aef85f" />
<img width="517" height="1029" alt="Screenshot 2025-11-08 at 3 18 16 PM" src="https://github.com/user-attachments/assets/c4e7c0d9-37d7-4e63-9063-a4fb821c0aef" />
<img width="517" height="1029" alt="Screenshot 2025-11-08 at 3 18 21 PM" src="https://github.com/user-attachments/assets/6100a19c-c2b1-4e5a-9260-4f40f8f55e3a" />
<img width="517" height="1029" alt="Screenshot 2025-11-08 at 3 18 39 PM" src="https://github.com/user-attachments/assets/20fe3029-e2b2-4e29-93a1-6977cf152271" />
<img width="517" height="1029" alt="Screenshot 2025-11-08 at 3 18 48 PM" src="https://github.com/user-attachments/assets/56b1de6b-eeb0-49aa-a5ce-81e0cecbe7b6" />







