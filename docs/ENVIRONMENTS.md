# Oysyn Mobile environments

The Flutter application receives its environment and API address at build time.
The default remains Production so existing release commands keep their current
behavior.

## VS Code

Open **Run and Debug** and select one of the committed launch profiles:

- `OySyn Stage` for development and closed testing.
- `OySyn Production` only for a production verification or release build.

Use `OySyn Stage` for day-to-day development.

## Stage

```bash
flutter run \
  --dart-define=APP_ENV=stage \
  --dart-define=API_BASE_URL=https://api-mobile-stage.oysyn.asia/api/v1
```

## Production

```bash
flutter run \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api-mobile.oysyn.asia/api/v1
```

`API_BASE_URL` is public configuration, not a secret. Service tokens, database
credentials, and Core API credentials must never be included in a Flutter build.

Android product flavors and iOS schemes will wrap these values after the Stage
backend domain and the iOS Production bundle identifier are confirmed.
